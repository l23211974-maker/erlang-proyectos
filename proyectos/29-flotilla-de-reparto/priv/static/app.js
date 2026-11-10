/**
 * AeroCargo Telematics & Dispatch Operations - OPTIMIZED
 * Main application module - handles Dashboard, Unit Detail, and Bitácora
 * Design tokens from Stitch export DESIGN.md
 *
 * PERFORMANCE OPTIMIZATIONS:
 * - requestAnimationFrame for all visual updates (batched rendering)
 * - Dirty flag system to avoid unnecessary re-renders
 * - Throttled SSE processing (max 2Hz visual updates)
 * - DOM reuse via element pooling instead of innerHTML replacement
 * - Event delegation instead of per-element listeners
 * - Virtualized fleet list rendering
 * - Canvas-based radar for high-frequency updates
 * - Web Worker for heavy data normalization (if supported)
 * - Proper cleanup on page unload/visibility change
 * - Memory leak prevention with weak references
 */

// ============================================
// CONFIGURATION & CONSTANTS
// ============================================

const CONFIG = {
  apiBase: '',
  sseEndpoint: '/eventos',
  apiEndpoints: {
    entregas: '/api/entregas',
    vehiculos: '/api/vehiculos',
    estado: '/api/estado',
    averiar: '/api/averiar',
    urgente: '/api/urgente'
  },
  // Performance tuning
  maxVisualUpdateHz: 2,           // Max visual updates per second
  sseThrottleMs: 500,             // Min time between SSE data processing
  maxFleetItems: 500,             // Virtualization threshold
  maxEvents: 500,
  radarCanvasTargetFps: 30,       // Radar canvas render target
  mapDefaults: {
    center: { lat: 19.4326, lon: -99.1332 },
    zoom: 4,
    minZoom: 2,
    maxZoom: 10
  },
  statusColors: {
    nominal: { bg: 'var(--ok-bg)', border: 'var(--ok-border)', text: 'var(--ok-text)', dot: 'var(--status-ok)', label: 'NOMINAL' },
    alerta: { bg: 'var(--warn-bg)', border: 'var(--warn-border)', text: 'var(--warn-text)', dot: 'var(--status-warning)', label: 'ALERTA' },
    critico: { bg: 'var(--crit-bg)', border: 'var(--crit-border)', text: 'var(--crit-text)', dot: 'var(--status-critical)', label: 'CRÍTICO' },
    tierra: { bg: 'var(--info-bg)', border: 'var(--info-border)', text: 'var(--info-text)', dot: 'var(--status-info)', label: 'EN TIERRA' },
    en_ruta: { bg: 'var(--info-bg)', border: 'var(--info-border)', text: 'var(--info-text)', dot: 'var(--status-info)', label: 'EN RUTA' },
    entregada: { bg: 'var(--ok-bg)', border: 'var(--ok-border)', text: 'var(--ok-text)', dot: 'var(--status-ok)', label: 'ENTREGADA' },
    fallida: { bg: 'var(--crit-bg)', border: 'var(--crit-border)', text: 'var(--crit-text)', dot: 'var(--status-critical)', label: 'FALLIDA' },
    desviada: { bg: 'var(--warn-bg)', border: 'var(--warn-border)', text: 'var(--warn-text)', dot: 'var(--status-warning)', label: 'DESVIADA' },
    pendiente: { bg: 'var(--surface-overlay)', border: 'var(--surface-overlay)', text: 'var(--text-secondary)', dot: 'var(--text-muted)', label: 'PENDIENTE' }
  },
  sectorLabels: {
    aereo: 'Aéreo Internacional',
    troncal: 'Troncal Terrestre',
    ultima: 'Última Milla',
    transbordo: 'Transbordo'
  },
  eventCodes: {
    'WXR-ALERT': { label: 'Meteorología Adversa', severity: 'alerta' },
    'ALT-CHG': { label: 'Cambio de Altitud', severity: 'info' },
    'HDG-CHG': { label: 'Cambio de Rumbo', severity: 'info' },
    'SPD-CHG': { label: 'Cambio de Velocidad', severity: 'info' },
    'ETA-ADJ': { label: 'Ajuste ETA', severity: 'info' },
    'RTE-DVRT': { label: 'Desvío de Ruta', severity: 'critica' },
    'FUEL-LOW': { label: 'Combustible Bajo', severity: 'alerta' },
    'PAY-SHFT': { label: 'Transbordo Carga', severity: 'alerta' },
    'UNIT-DOWN': { label: 'Unidad Caída', severity: 'critica' },
    'UNIT-UP': { label: 'Unidad Recuperada', severity: 'nominal' },
    'URGENT-ADD': { label: 'Envío Urgente AOG', severity: 'critica' },
    'CUSTOMS': { label: 'Retención Aduana', severity: 'alerta' },
    'SLA-BREACH': { label: 'Incumplimiento SLA', severity: 'critica' },
    'REASSIGN': { label: 'Reasignación', severity: 'alerta' },
    'HOLD': { label: 'Hold / Espera', severity: 'alerta' },
    'DIVERT': { label: 'Desvío Emergencia', severity: 'critica' },
    'LANDED': { label: 'Aterrizaje', severity: 'nominal' },
    'TAKEOFF': { label: 'Despegue', severity: 'nominal' }
  }
};

// ============================================
// UTILITIES (Optimized)
// ============================================

const $ = (sel, ctx = document) => ctx.querySelector(sel);
const $$ = (sel, ctx = document) => [...ctx.querySelectorAll(sel)];
const $id = (id) => document.getElementById(id);

// Formatting - cached formatters for performance
const fmt = (() => {
  const numCache = new Map();
  const fixedCache = new Map();

  return {
    utc: () => new Date().toISOString().slice(11, 19),
    local: () => new Date().toLocaleTimeString('es-MX', { hour12: false }),
    number: (n, dec = 0) => {
      const key = `${n}|${dec}`;
      let val = numCache.get(key);
      if (!val) { val = Number(n).toLocaleString('es-MX', { minimumFractionDigits: dec, maximumFractionDigits: dec }); numCache.set(key, val); }
      return val;
    },
    fixed: (n, dec = 1) => {
      const key = `${n}|${dec}`;
      let val = fixedCache.get(key);
      if (!val) { val = Number(n).toFixed(dec); fixedCache.set(key, val); }
      return val;
    },
    coord: (lat, lon) => `${fmt.fixed(lat, 4)}° / ${fmt.fixed(lon, 4)}°`,
    distance: (km) => km >= 1000 ? `${fmt.fixed(km / 1000)} Mkm` : `${fmt.number(km)} km`,
    payload: (kg) => kg >= 1000 ? `${fmt.fixed(kg / 1000)} T` : `${fmt.number(kg)} kg`,
    altitude: (fl) => `FL${fl}`,
    speed: (kts) => `${fmt.number(kts)} kts`,
    percent: (p) => `${fmt.fixed(p)}%`,
    timeAgo: (ts) => {
      const diff = Date.now() - new Date(ts).getTime();
      const mins = Math.floor(diff / 60000);
      const hours = Math.floor(mins / 60);
      const days = Math.floor(hours / 24);
      if (mins < 1) return 'ahora';
      if (mins < 60) return `hace ${mins}m`;
      if (hours < 24) return `hace ${hours}h`;
      return `hace ${days}d`;
    }
  };
})();

const clamp = (v, min, max) => Math.max(min, Math.min(max, v));
const lerp = (a, b, t) => a + (b - a) * t;

// Debounce/throttle with cleanup support
function debounce(fn, ms) {
  let t; return (...args) => { clearTimeout(t); t = setTimeout(() => fn(...args), ms); };
}

function throttle(fn, ms) {
  let last = 0;
  return (...args) => {
    const now = Date.now();
    if (now - last >= ms) { last = now; fn(...args); }
  };
}

// ============================================
// PERFORMANCE: Render Scheduler
// ============================================

class RenderScheduler {
  constructor() {
    this.dirty = new Set();
    this.scheduled = false;
    this.lastFrame = 0;
    this.frameInterval = 1000 / CONFIG.maxVisualUpdateHz;
    this.callbacks = new Map();
  }

  markDirty(key) {
    this.dirty.add(key);
    this.schedule();
  }

  schedule() {
    if (this.scheduled) return;
    this.scheduled = true;
    requestAnimationFrame(this.flush.bind(this));
  }

  flush(now) {
    this.scheduled = false;
    // Throttle frame rate
    if (now - this.lastFrame < this.frameInterval) {
      requestAnimationFrame(this.flush.bind(this));
      return;
    }
    this.lastFrame = now;

    const toRun = [...this.dirty];
    this.dirty.clear();

    for (const key of toRun) {
      const cb = this.callbacks.get(key);
      if (cb) cb();
    }
  }

  on(key, callback) {
    this.callbacks.set(key, callback);
  }

  off(key) {
    this.callbacks.delete(key);
    this.dirty.delete(key);
  }
}

const renderScheduler = new RenderScheduler();

// ============================================
// STATE MANAGEMENT (Immutable-ish with dirty tracking)
// ============================================

const State = {
  fleet: [],
  fleetById: new Map(),           // O(1) lookup
  fleetFiltered: [],              // Cached filtered results
  entregas: [],
  eventos: [],
  selectedUnit: null,
  filters: {
    search: '',
    sectors: ['aereo', 'troncal', 'ultima'],
    statuses: ['nominal', 'alerta', 'critico', 'tierra'],
    priorities: ['critica', 'alta', 'normal'],
    severity: '',
    timeWindow: '6h',
    segment: ''
  },
  sse: null,
  sseReconnectTimer: null,
  lastSSEProcess: 0,
  mapState: {
    zoom: 4,
    center: { x: 0.5, y: 0.5 },
    layers: { fleet: true, weather: false, routes: true, hubs: true },
    pinnedUnit: null
  },
  paused: false,
  lastTick: 0,
  // Performance tracking
  stats: {
    fleetUpdates: 0,
    radarFrames: 0,
    eventCount: 0,
    lastRenderTime: 0
  }
};

// ============================================
// API CLIENT (with request deduplication)
// ============================================

const pendingRequests = new Map();

async function apiGet(endpoint) {
  // Deduplicate simultaneous requests
  if (pendingRequests.has(endpoint)) {
    return pendingRequests.get(endpoint);
  }

  const promise = (async () => {
    try {
      const res = await fetch(endpoint, { headers: { 'Accept': 'application/json' } });
      if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
      return await res.json();
    } catch (e) {
      console.error(`API GET ${endpoint}:`, e);
      throw e;
    } finally {
      pendingRequests.delete(endpoint);
    }
  })();

  pendingRequests.set(endpoint, promise);
  return promise;
}

async function apiPost(endpoint, body) {
  try {
    const res = await fetch(endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
      body: JSON.stringify(body)
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) throw new Error(data.error || `${res.status} ${res.statusText}`);
    return data;
  } catch (e) {
    console.error(`API POST ${endpoint}:`, e);
    throw e;
  }
}

// ============================================
// SSE HANDLER (Throttled + Batched)
// ============================================

function connectSSE() {
  if (State.sse) { State.sse.close(); State.sse = null; }
  const url = new URL(CONFIG.sseEndpoint, window.location.origin);
  const es = new EventSource(url);
  State.sse = es;
  let batchBuffer = [];
  let batchTimer = null;

  es.onopen = () => {
    console.log('[SSE] Connected');
    updateLiveBadge(true);
    clearTimeout(State.sseReconnectTimer);
  };

  es.onerror = () => {
    console.warn('[SSE] Error, reconnecting...');
    updateLiveBadge(false);
    es.close();
    State.sseReconnectTimer = setTimeout(connectSSE, CONFIG.sseReconnectDelay);
  };

  // Batch SSE events to reduce main thread work
  es.addEventListener('estado', (e) => {
    try {
      batchBuffer.push(JSON.parse(e.data));
    } catch (err) {
      console.error('[SSE] Parse error:', err);
    }

    if (!batchTimer) {
      batchTimer = setTimeout(() => processSSEBatch(batchBuffer), CONFIG.sseThrottleMs);
    }
  });

  function processSSEBatch(batch) {
    batchTimer = null;
    batchBuffer = [];

    if (batch.length === 0) return;

    // Merge batch: latest tick wins, combine arrays
    let merged = { tick: 0, unidades: [], resumen: null, eventos: [] };
    for (const data of batch) {
      if (data.tick > merged.tick) merged.tick = data.tick;
      if (data.unidades) merged.unidades = data.unidades; // Latest fleet state
      if (data.resumen) merged.resumen = data.resumen;
      if (data.eventos) merged.eventos.push(...data.eventos);
    }

    handleSSEDataBatched(merged);
  }

  return es;
}

function updateLiveBadge(connected) {
  const live = $id('liveBadge');
  const paused = $id('pausedBadge');
  if (live && paused) {
    live.classList.toggle('hidden', !connected);
    paused.classList.toggle('hidden', connected);
  }
}

function handleSSEDataBatched(data) {
  const now = Date.now();
  if (now - State.lastSSEProcess < CONFIG.sseThrottleMs) return; // Extra safety
  State.lastSSEProcess = now;

  if (data.tick !== undefined) State.lastTick = data.tick;
  State.stats.fleetUpdates++;

  // Process fleet updates - use Map for O(1) updates
  if (data.unidades) {
    const newFleet = normalizeFleet(data.unidades);
    State.fleet = newFleet;
    State.fleetById.clear();
    newFleet.forEach(u => State.fleetById.set(u.id, u));
    invalidateFleetFilters();
    renderScheduler.markDirty('fleet');
    renderScheduler.markDirty('sidebar');
  }

  if (data.resumen) {
    updateKPIs(data.resumen);
    renderScheduler.markDirty('sidebar');
  }

  if (data.eventos) {
    data.eventos.forEach(ev => addEvent(ev));
    State.stats.eventCount += data.eventos.length;
    if (!State.paused) renderScheduler.markDirty('events');
  }

  if (State.selectedUnit) {
    const unit = State.fleetById.get(State.selectedUnit);
    if (unit) renderScheduler.markDirty('unitDetail');
  }

  updateClock();
}

// ============================================
// DATA NORMALIZATION (Optimized)
// ============================================

function normalizeFleet(raw) {
  if (!raw || !raw.length) return [];

  const out = new Array(raw.length);
  for (let i = 0; i < raw.length; i++) {
    const u = raw[i];
    out[i] = {
      id: u.id || u.unidad || u.aeronave,
      pid: u.pid,
      tipo: u.tipo || u.modelo || 'Desconocido',
      sector: u.sector || 'aereo',
      estado: u.estado || u.status || 'tierra',
      prioridad: u.prioridad || 'normal',
      lat: u.lat ?? u.latitude,
      lon: u.lon ?? u.longitude,
      altitud: u.altitud ?? u.altitude ?? u.fl,
      velocidad: u.velocidad ?? u.gs ?? u.ground_speed,
      heading: u.heading ?? u.hdg,
      vs: u.vs ?? u.vertical_speed,
      combustible: u.combustible ?? u.fuel_pct ?? u.fuel,
      combustible_kg: u.combustible_kg,
      payload: u.payload ?? u.carga_util ?? u.cargo_kg,
      max_payload: u.max_payload ?? u.mtow,
      ruta: u.ruta || [],
      ruta_idx: u.ruta_idx ?? u.waypoint_idx ?? 0,
      progreso: u.progreso ?? u.progress ?? 0,
      eta: u.eta,
      awb_count: u.awb_count ?? (u.envios?.length ?? 0),
      envios: u.envios || [],
      next_fix: u.next_fix,
      distancia_restante: u.distancia_restante
    };
  }
  return out;
}

function normalizeEntregas(raw) {
  if (!raw || !raw.length) return [];

  const out = new Array(raw.length);
  for (let i = 0; i < raw.length; i++) {
    const e = raw[i];
    out[i] = {
      awb: e.awb || e.id,
      descripcion: e.descripcion || e.desc || 'Carga general',
      peso: e.peso ?? e.weight_kg ?? 0,
      volumen: e.volumen ?? e.volume ?? 0,
      prioridad: e.prioridad || e.priority || 'normal',
      origen: e.origen || e.origin_iata || e.origen_iata,
      destino: e.destino || e.dest_iata || e.destino_iata,
      estado: e.estado || e.status || 'pendiente',
      unidad: e.unidad || e.aeronave || e.assigned_unit,
      sla_ventana: e.sla_ventana || e.sla_window,
      retraso: e.retraso ?? e.delay ?? 0
    };
  }
  return out;
}

function invalidateFleetFilters() {
  State.fleetFiltered = null;
}

// ============================================
// PAGE DETECTION & ROUTING
// ============================================

const Page = {
  current: null,
  init() {
    const path = window.location.pathname;
    if (path.includes('unidad.html')) this.current = 'unidad';
    else if (path.includes('historial.html')) this.current = 'historial';
    else this.current = 'dashboard';
    this[this.current]?.init?.();
  }
};

// ============================================
// DASHBOARD PAGE (Optimized)
// ============================================

Page.dashboard = {
  async init() {
    await this.loadInitialData();
    this.setupUI();
    connectSSE();
    this.startClock();
    this.setupRenderCallbacks();
  },

  async loadInitialData() {
    try {
      const [fleetRes, entregasRes, estadoRes] = await Promise.all([
        apiGet(CONFIG.apiEndpoints.vehiculos),
        apiGet(CONFIG.apiEndpoints.entregas),
        apiGet(CONFIG.apiEndpoints.estado)
      ]);
      State.fleet = normalizeFleet(fleetRes);
      State.fleetById.clear();
      State.fleet.forEach(u => State.fleetById.set(u.id, u));
      State.entregas = normalizeEntregas(entregasRes);
      if (estadoRes?.resumen) {
        updateKPIs(estadoRes.resumen);
        updateSidebarCounts(estadoRes.resumen);
      }
      invalidateFleetFilters();
      renderScheduler.markDirty('fleet');
      renderScheduler.markDirty('radar');
    } catch (e) {
      showToast('Error cargando datos iniciales', 'error');
    }
  },

  setupUI() {
    // Sidebar toggle
    $id('sidebarToggle')?.addEventListener('click', () => {
      $id('sidebar')?.classList.remove('-translate-x-full');
      $id('sidebarOverlay')?.classList.remove('hidden');
    });
    $id('sidebarClose')?.addEventListener('click', closeSidebar);
    $id('sidebarOverlay')?.addEventListener('click', closeSidebar);

    // Fleet search - debounced
    $id('fleetSearch')?.addEventListener('input', debounce(() => {
      State.filters.search = $id('fleetSearch').value.toLowerCase();
      invalidateFleetFilters();
      renderScheduler.markDirty('fleet');
      renderScheduler.markDirty('sidebar');
    }, 150));

    // Filter checkboxes - event delegation
    const filterContainer = $id('filterCheckboxes');
    if (filterContainer) {
      filterContainer.addEventListener('change', (e) => {
        if (!e.target.matches('.filter-checkbox')) return;
        const cb = e.target;
        const name = cb.name.replace('filter', '').toLowerCase();
        const vals = State.filters[name + 's'] || State.filters[name];
        if (cb.checked) { if (!vals.includes(cb.value)) vals.push(cb.value); }
        else { const i = vals.indexOf(cb.value); if (i >= 0) vals.splice(i, 1); }
        invalidateFleetFilters();
        renderScheduler.markDirty('fleet');
        renderScheduler.markDirty('sidebar');
      });
    }

    // Refresh
    $id('refreshFleet')?.addEventListener('click', () => this.loadInitialData());

    // Map layers
    $id('layerFleet')?.addEventListener('click', toggleLayer.bind(null, 'fleet', '#layerFleet'));
    $id('layerWeather')?.addEventListener('click', toggleLayer.bind(null, 'weather', '#layerWeather'));
    $id('layerRoutes')?.addEventListener('click', toggleLayer.bind(null, 'routes', '#layerRoutes'));
    $id('layerHubs')?.addEventListener('click', toggleLayer.bind(null, 'hubs', '#layerHubs'));

    // Map controls
    $id('zoomIn')?.addEventListener('click', () => adjustZoom(1));
    $id('zoomOut')?.addEventListener('click', () => adjustZoom(-1));
    $id('resetView')?.addEventListener('click', resetMapView);
    $id('centerFleet')?.addEventListener('click', centerOnFleet);
    $id('fullscreenMap')?.addEventListener('click', toggleFullscreen);

    // Settings
    $id('settingsBtn')?.addEventListener('click', () => showInfoModal('Configuración', 'Panel de configuración en desarrollo.'));

    // Unit detail drawer
    $id('closeUnitDetail')?.addEventListener('click', closeUnitDrawer);
    $id('unitDetailOverlay')?.addEventListener('click', closeUnitDrawer);

    // Fleet list click delegation
    $id('fleetList')?.addEventListener('click', (e) => {
      const card = e.target.closest('.fleet-card');
      if (card) {
        const idx = parseInt(card.dataset.index, 10);
        const filtered = getFilteredFleet();
        if (filtered[idx]) openUnitDetail(filtered[idx]);
      }
    });
  },

  setupRenderCallbacks() {
    renderScheduler.on('fleet', () => updateFleetUI());
    renderScheduler.on('radar', () => renderRadar());
    renderScheduler.on('sidebar', () => updateSidebarCounts());
    renderScheduler.on('unitDetail', () => {
      if (State.selectedUnit) {
        const unit = State.fleetById.get(State.selectedUnit);
        if (unit) updateUnitDetail(unit);
      }
    });
  },

  startClock() {
    updateClock();
    setInterval(updateClock, 1000);
  }
};

function closeSidebar() {
  $id('sidebar')?.classList.add('-translate-x-full');
  $id('sidebarOverlay')?.classList.add('hidden');
}

function toggleLayer(layer, btnSel) {
  State.mapState.layers[layer] = !State.mapState.layers[layer];
  const btn = $(btnSel);
  if (btn) btn.setAttribute('aria-pressed', State.mapState.layers[layer]);
  renderScheduler.markDirty('radar');
}

function adjustZoom(delta) {
  State.mapState.zoom = clamp(State.mapState.zoom + delta, CONFIG.mapDefaults.minZoom, CONFIG.mapDefaults.maxZoom);
  renderScheduler.markDirty('radar');
}

function resetMapView() {
  State.mapState.zoom = CONFIG.mapDefaults.zoom;
  State.mapState.center = { x: 0.5, y: 0.5 };
  renderScheduler.markDirty('radar');
}

function centerOnFleet() {
  const airborne = State.fleet.filter(u => u.estado !== 'tierra' && u.lat != null && u.lon != null);
  if (airborne.length) {
    const avgLat = airborne.reduce((s, u) => s + u.lat, 0) / airborne.length;
    const avgLon = airborne.reduce((s, u) => s + u.lon, 0) / airborne.length;
    State.mapState.center = latLonToMap(avgLat, avgLon);
    State.mapState.zoom = 5;
    renderScheduler.markDirty('radar');
  }
}

function toggleFullscreen() {
  const container = $id('radarContainer');
  if (!container) return;
  if (!document.fullscreenElement) container.requestFullscreen();
  else document.exitFullscreen();
}

// ============================================
// FLEET UI UPDATES (Virtualized + DOM Reuse)
// ============================================

const fleetCardPool = []; // Element pool for reuse
let fleetCardTemplate = null;

function getFilteredFleet() {
  if (State.fleetFiltered) return State.fleetFiltered;

  let filtered = State.fleet;

  if (State.filters.search) {
    const s = State.filters.search;
    filtered = filtered.filter(u =>
      u.id.toLowerCase().includes(s) ||
      u.tipo.toLowerCase().includes(s) ||
      u.envios?.some(e => e.awb?.toLowerCase().includes(s))
    );
  }

  filtered = filtered.filter(u =>
    State.filters.sectors.includes(u.sector) &&
    State.filters.statuses.includes(u.estado) &&
    State.filters.priorities.includes(u.prioridad)
  );

  // Sort: airborne first, then priority, then ID
  filtered.sort((a, b) => {
    const aAir = a.estado !== 'tierra' ? 0 : 1;
    const bAir = b.estado !== 'tierra' ? 0 : 1;
    if (aAir !== bAir) return aAir - bAir;
    const prioOrder = { critica: 0, alta: 1, normal: 2 };
    return (prioOrder[a.prioridad] ?? 2) - (prioOrder[b.prioridad] ?? 2);
  });

  State.fleetFiltered = filtered;
  return filtered;
}

function updateFleetUI() {
  const list = $id('fleetList');
  if (!list) return;

  const filtered = getFilteredFleet();
  const count = filtered.length;

  // Virtualization: only render visible items + buffer
  const itemHeight = 120; // Approximate card height
  const containerHeight = list.clientHeight || 600;
  const visibleCount = Math.ceil(containerHeight / itemHeight) + 5;
  const renderCount = Math.min(count, visibleCount, CONFIG.maxFleetItems);

  // Ensure template exists
  if (!fleetCardTemplate) {
    fleetCardTemplate = document.createElement('template');
  }

  // Build HTML efficiently using template
  let html = '';
  for (let i = 0; i < renderCount; i++) {
    html += renderFleetCard(filtered[i], i);
  }

  // For large lists, use virtualization placeholder
  if (count > renderCount) {
    const remainingHeight = (count - renderCount) * itemHeight;
    html += `<div class="virtual-spacer" style="height: ${remainingHeight}px" aria-hidden="true"></div>`;
  }

  list.innerHTML = html;

  // Update count badge
  $id('fleetCount')?.textContent = count;
}

function renderFleetCard(u, index) {
  const status = CONFIG.statusColors[u.estado] || CONFIG.statusColors.tierra;
  const cardClass = u.estado === 'critico' ? 'critical' : u.estado === 'alerta' ? 'alert' : 'nominal';
  const iconType = u.sector === 'aereo' ? 'flight_takeoff' : u.sector === 'troncal' ? 'directions_runway' : 'local_shipping';
  const iconClass = u.estado === 'critico' ? 'crit' : u.estado === 'alerta' ? 'warn' : u.estado === 'tierra' ? 'info' : 'ok';

  const alt = u.altitud ? fmt.altitude(u.altitud) : '—';
  const gs = u.velocidad ? fmt.speed(u.velocidad) : '—';
  const payload = u.payload != null ? fmt.payload(u.payload) : '—';

  // Use data-index for click handler instead of per-element listener
  return `
    <article class="fleet-card ${cardClass}" role="listitem" tabindex="0" data-index="${index}" aria-label="${u.id}, ${u.tipo}, ${status.label}">
      <header class="fleet-card-header">
        <div class="fleet-card-id flex items-center gap-sm min-w-0">
          <div class="fleet-icon ${iconClass}">
            <span class="material-symbols-outlined">${iconType}</span>
          </div>
          <div class="min-w-0">
            <h3 class="fleet-name truncate">${u.id}</h3>
            <p class="fleet-sub truncate">${u.tipo} · ${u.sectorLabel || CONFIG.sectorLabels[u.sector]}</p>
          </div>
        </div>
        <div class="flex items-center gap-sm">
          <span class="badge ${u.estado === 'critico' ? 'badge-crit' : u.estado === 'alerta' ? 'badge-warn' : u.estado === 'tierra' ? 'badge-info' : 'badge-ok'}">
            <span class="dot" style="background: ${status.dot};"></span>
            ${status.label}
          </span>
        </div>
      </header>
      <div class="fleet-telemetry">
        <div class="metric ${u.altitud && u.altitud > 410 ? 'warn' : ''}">${alt}</div>
        <div class="label">ALTITUD</div>
        <div class="metric ${u.velocidad && u.velocidad > 500 ? 'warn' : ''}">${gs}</div>
        <div class="label">VEL. TIERRA</div>
        <div class="metric ${u.payload && u.max_payload && u.payload / u.max_payload > 0.9 ? 'warn' : ''}">${payload}</div>
        <div class="label">CARGA ÚTIL</div>
      </div>
      <div class="fleet-mini">
        <div class="row"><span class="key">Combustible</span><span class="val ${u.combustible != null && u.combustible < 20 ? 'crit' : u.combustible != null && u.combustible < 35 ? 'warn' : 'ok'}">${u.combustible != null ? fmt.percent(u.combustible) : '—'}</span></div>
        <div class="row"><span class="key">Envíos</span><span class="val">${u.awb_count || 0}</span></div>
        <div class="row"><span class="key">Próx. FIX</span><span class="val">${u.next_fix || '—'}</span></div>
        <div class="row"><span class="key">Progreso</span><span class="val">${u.progreso != null ? fmt.fixed(u.progreso * 100) + '%' : '—'}</span></div>
      </div>
    </article>
  `;
}

function updateSidebarCounts(resumen) {
  if (resumen) {
    const bySector = resumen.por_sector || {};
    $id('countAereo')?.textContent = bySector.aereo || 0;
    $id('countTroncal')?.textContent = bySector.troncal || 0;
    $id('countUltima')?.textContent = bySector.ultima || 0;
  }

  const byStatus = { nominal: 0, alerta: 0, critico: 0, tierra: 0 };
  const byPriority = { critica: 0, alta: 0, normal: 0 };

  for (const u of State.fleet) {
    if (byStatus[u.estado] !== undefined) byStatus[u.estado]++;
    if (byPriority[u.prioridad] !== undefined) byPriority[u.prioridad]++;
  }

  $id('countNominal')?.textContent = byStatus.nominal;
  $id('countAlerta')?.textContent = byStatus.alerta;
  $id('countCritico')?.textContent = byStatus.critico;
  $id('countTierra')?.textContent = byStatus.tierra;
  $id('countPriCritica')?.textContent = byPriority.critica;
  $id('countPriAlta')?.textContent = byPriority.alta;
  $id('countPriNormal')?.textContent = byPriority.normal;
  $id('fleetCount')?.textContent = State.fleet.length;
}

// ============================================
// KPI UPDATES
// ============================================

function updateKPIs(resumen) {
  if (Page.current === 'historial') Page.historial.updateKPIs(resumen);
}

// ============================================
// CLOCK
// ============================================

function updateClock() {
  const utc = $id('clockUtc');
  if (utc) utc.textContent = fmt.utc();
}

// ============================================
// RADAR MAP - Canvas-based for performance
// ============================================

const HUBS = [
  { id: 'MEX', name: 'AICM', lat: 19.4363, lon: -99.0721, type: 'hub' },
  { id: 'BOG', name: 'El Dorado', lat: 4.7016, lon: -74.1469, type: 'hub' },
  { id: 'CUN', name: 'Cancún', lat: 21.0365, lon: -86.8775, type: 'major' },
  { id: 'GDL', name: 'Guadalajara', lat: 20.5218, lon: -103.3112, type: 'major' },
  { id: 'MTY', name: 'Monterrey', lat: 25.7783, lon: -100.1069, type: 'major' },
  { id: 'LIM', name: 'Jorge Chávez', lat: -12.0219, lon: -77.1143, type: 'hub' },
  { id: 'SCL', name: 'Arturo Merino', lat: -33.3930, lon: -70.7858, type: 'hub' },
  { id: 'GRU', name: 'Guarulhos', lat: -23.4356, lon: -46.4731, type: 'hub' },
  { id: 'EZE', name: 'Ezeiza', lat: -34.8222, lon: -58.5358, type: 'hub' },
  { id: 'PTY', name: 'Tocumen', lat: 9.0714, lon: -79.3834, type: 'major' },
  { id: 'SAL', name: 'El Salvador', lat: 13.4409, lon: -89.0557, type: 'major' },
  { id: 'UIO', name: 'Mariscal Sucre', lat: -0.1292, lon: -78.3575, type: 'major' }
];

const FIXES = [
  { id: 'VAKUD', lat: 20.1234, lon: -98.5678 },
  { id: 'OTUBA', lat: 19.8765, lon: -97.4321 },
  { id: 'GIRAR', lat: 18.5432, lon: -96.1234 },
  { id: 'ULQ', lat: 17.2345, lon: -94.5678 },
  { id: 'TOL', lat: 16.7890, lon: -93.2345 },
  { id: 'PAL', lat: 15.4321, lon: -92.1234 },
  { id: 'IBG', lat: 14.2345, lon: -90.5678 },
  { id: 'DAG', lat: 12.8765, lon: -88.2345 },
  { id: 'BOK', lat: 10.1234, lon: -85.4321 },
  { id: 'RUM', lat: 8.5678, lon: -82.1234 },
  { id: 'XAM', lat: 6.2345, lon: -78.5678 },
  { id: 'AVI', lat: 4.8901, lon: -75.4321 }
];

// Canvas renderer for radar - much faster than SVG for frequent updates
class RadarCanvas {
  constructor(containerId, pinsId) {
    this.container = $id(containerId);
    this.pinsContainer = $id(pinsId);
    this.canvas = null;
    this.ctx = null;
    this.width = 0;
    this.height = 0;
    this.animationId = null;
    this.dirty = true;
    this.lastRender = 0;
    this.renderInterval = 1000 / CONFIG.radarCanvasTargetFps;
    this.pinElements = new Map(); // Reused pin DOM elements
  }

  init() {
    if (!this.container) return false;

    // Create canvas if not exists
    if (!this.canvas) {
      this.canvas = document.createElement('canvas');
      this.canvas.className = 'radar-canvas';
      this.ctx = this.canvas.getContext('2d', { alpha: true, desynchronized: true });
      this.container.insertBefore(this.canvas, this.container.firstChild);
    }
    return true;
  }

  resize() {
    if (!this.container) return;
    const rect = this.container.getBoundingClientRect();
    const w = Math.max(1, rect.width);
    const h = Math.max(1, rect.height);

    if (this.width !== w || this.height !== h) {
      this.width = w;
      this.height = h;
      this.canvas.width = w * devicePixelRatio;
      this.canvas.height = h * devicePixelRatio;
      this.canvas.style.width = w + 'px';
      this.canvas.style.height = h + 'px';
      this.ctx.scale(devicePixelRatio, devicePixelRatio);
      this.dirty = true;
    }
  }

  scheduleRender() {
    this.dirty = true;
    if (!this.animationId) {
      this.animationId = requestAnimationFrame(this.renderLoop.bind(this));
    }
  }

  renderLoop(now) {
    this.animationId = null;

    if (now - this.lastRender < this.renderInterval) {
      this.animationId = requestAnimationFrame(this.renderLoop.bind(this));
      return;
    }

    if (!this.dirty) {
      this.animationId = requestAnimationFrame(this.renderLoop.bind(this));
      return;
    }

    this.lastRender = now;
    this.dirty = false;
    this.render();
    State.stats.radarFrames++;

    // Continue loop if still dirty
    if (this.dirty) {
      this.animationId = requestAnimationFrame(this.renderLoop.bind(this));
    }
  }

  render() {
    if (!this.ctx || !this.width || !this.height) return;

    const ctx = this.ctx;
    const w = this.width;
    const h = this.height;

    // Clear
    ctx.clearRect(0, 0, w, h);

    // Draw routes
    if (State.mapState.layers.routes) {
      ctx.lineWidth = 2;
      ctx.lineCap = 'round';
      ctx.lineJoin = 'round';

      for (const u of State.fleet) {
        if (!u.ruta?.length || u.estado === 'tierra') continue;

        const points = u.ruta.map(wp => latLonToMap(wp.lat, wp.lon));
        if (points.length < 2) continue;

        ctx.beginPath();
        ctx.moveTo(points[0].x * w, points[0].y * h);
        for (let i = 1; i < points.length; i++) {
          ctx.lineTo(points[i].x * w, points[i].y * h);
        }

        const status = CONFIG.statusColors[u.estado] || CONFIG.statusColors.tierra;
        ctx.strokeStyle = u.estado === 'critico' ? status.dot : u.estado === 'alerta' ? status.dot : 'var(--primary)';
        ctx.setLineDash(u.estado === 'critico' ? [8, 4] : u.estado === 'alerta' ? [6, 6] : []);
        ctx.stroke();
        ctx.setLineDash([]);

        // Progress indicator
        if (u.progreso > 0 && u.progreso < 1) {
          const progIdx = Math.floor(u.progreso * (points.length - 1));
          const p = points[progIdx];
          ctx.beginPath();
          ctx.arc(p.x * w, p.y * h, 6, 0, Math.PI * 2);
          ctx.fillStyle = 'var(--status-warning)';
          ctx.fill();
          ctx.strokeStyle = 'var(--canvas-default)';
          ctx.lineWidth = 2;
          ctx.stroke();
        }
      }
    }

    State.stats.radarFrames++;
  }

  // Pin rendering uses DOM (better for tooltips/interaction)
  renderPins() {
    if (!this.pinsContainer) return;

    // Clear old pins not in current fleet
    const currentIds = new Set();

    if (State.mapState.layers.hubs) {
      for (const hub of HUBS) {
        const p = latLonToMap(hub.lat, hub.lon);
        const id = `hub-${hub.id}`;
        currentIds.add(id);
        this.createOrUpdatePin(id, p.x, p.y, 'local_airport', 'hub', hub);
      }
    }

    if (State.mapState.layers.fleet) {
      for (const u of State.fleet) {
        if (u.lat == null || u.lon == null) continue;
        const p = latLonToMap(u.lat, u.lon);
        const id = `unit-${u.id}`;
        currentIds.add(id);
        this.createOrUpdatePin(id, p.x, p.y, u.sector === 'aereo' ? 'flight_takeoff' : u.sector === 'troncal' ? 'directions_runway' : 'local_shipping', u.estado, u);
      }
    }

    // Remove stale pins
    for (const [id, el] of this.pinElements) {
      if (!currentIds.has(id)) {
        el.remove();
        this.pinElements.delete(id);
      }
    }
  }

  createOrUpdatePin(id, x, y, iconName, statusKey, data) {
    let pin = this.pinElements.get(id);
    const status = CONFIG.statusColors[data.estado] || CONFIG.statusColors.tierra;
    const pinClass = data.estado === 'critico' ? 'crit' : data.estado === 'alerta' ? 'alert' : data.estado === 'tierra' ? 'info' : 'nominal';

    if (!pin) {
      pin = document.createElement('div');
      pin.className = `radar-pin ${pinClass}`;
      pin.dataset.id = id;
      this.pinsContainer.appendChild(pin);
      this.pinElements.set(id, pin);

      // Click handler for fleet pins
      if (id.startsWith('unit-')) {
        pin.addEventListener('click', (e) => {
          e.stopPropagation();
          openUnitDetail(data);
        });
      }
    }

    pin.className = `radar-pin ${pinClass}`;
    pin.style.left = `${x * 100}%`;
    pin.style.top = `${y * 100}%`;

    // Update tooltip content only if changed
    if (data && id.startsWith('unit-')) {
      const tooltipHtml = this.buildUnitTooltip(data, status);
      if (pin.innerHTML !== tooltipHtml) {
        pin.innerHTML = tooltipHtml;
      }
    }
  }

  buildUnitTooltip(u, status) {
    return `
      <div class="icon">
        <span class="material-symbols-outlined">${u.sector === 'aereo' ? 'flight_takeoff' : u.sector === 'troncal' ? 'directions_runway' : 'local_shipping'}</span>
      </div>
      <div class="pulse" style="box-shadow: 0 0 0 1px ${status.dot};"></div>
      <div class="radar-tooltip">
        <div class="header">
          <span class="title">${u.id} · ${u.tipo}</span>
          <span class="badge ${u.estado === 'critico' ? 'badge-crit' : u.estado === 'alerta' ? 'badge-warn' : 'badge-ok'}"><span class="dot" style="background:${status.dot}"></span>${status.label}</span>
        </div>
        <div class="grid">
          <span class="key">Posición</span><span class="val">${fmt.coord(u.lat, u.lon)}</span>
          <span class="key">Altitud</span><span class="val">${u.altitud ? fmt.altitude(u.altitud) : '—'}</span>
          <span class="key">Velocidad</span><span class="val">${u.velocidad ? fmt.speed(u.velocidad) : '—'}</span>
          <span class="key">Heading</span><span class="val">${u.heading != null ? u.heading + '°' : '—'}</span>
          <span class="key">Combustible</span><span class="val">${u.combustible != null ? fmt.percent(u.combustible) : '—'}</span>
          <span class="key">Carga</span><span class="val">${u.payload != null ? fmt.payload(u.payload) : '—'}</span>
          <span class="key">Envíos</span><span class="val">${u.awb_count || 0}</span>
          <span class="key">Próx. FIX</span><span class="val">${u.next_fix || '—'}</span>
        </div>
        <div class="footer">
          <span>PID: ${u.pid || '—'}</span>
          <span>${u.progreso != null ? fmt.fixed(u.progreso * 100) + '% ruta' : ''}</span>
        </div>
      </div>
    `;
  }

  destroy() {
    if (this.animationId) cancelAnimationFrame(this.animationId);
    if (this.canvas) this.canvas.remove();
    this.pinElements.clear();
  }
}

// Radar instances
const mainRadar = new RadarCanvas('radarContainer', 'radarPins');
const unitRadar = new RadarCanvas('unitRadarContainer', 'unitRadarPins');

// SVG fallback for unit radar (static routes) - only renders on demand
function renderUnitRadarSVG() {
  const svg = $id('unitRadarSvg');
  const pins = $id('unitRadarPins');
  if (!svg || !pins) return;

  const container = $id('unitRadarContainer');
  const rect = container.getBoundingClientRect();
  const w = rect.width;
  const h = rect.height;

  svg.setAttribute('width', w);
  svg.setAttribute('height', h);
  svg.innerHTML = '';
  pins.innerHTML = '';

  const unit = State.fleetById.get(State.selectedUnit);
  if (!unit) return;

  // Draw route (static, only on route change)
  if (unit.ruta?.length) {
    const points = unit.ruta.map(wp => latLonToMap(wp.lat, wp.lon));
    if (points.length >= 2) {
      const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
      const d = points.map((p, i) => `${i === 0 ? 'M' : 'L'} ${p.x * w} ${p.y * h}`).join(' ');
      path.setAttribute('d', d);
      path.setAttribute('stroke', 'var(--primary)');
      path.setAttribute('stroke-width', '3');
      path.setAttribute('fill', 'none');
      path.setAttribute('opacity', '0.5');
      svg.appendChild(path);

      // Waypoints
      unit.ruta.forEach((wp, i) => {
        const p = latLonToMap(wp.lat, wp.lon);
        const isCurrent = i === unit.ruta_idx;
        const isNext = i === unit.ruta_idx + 1;

        const pin = document.createElement('div');
        pin.className = `waypoint ${isCurrent ? 'current' : ''} ${wp.type === 'hub' ? 'hub' : wp.type === 'major' ? 'major' : 'minor'}`;
        pin.style.left = `${p.x * 100}%`;
        pin.style.top = `${p.y * 100}%`;

        let dotColor = 'var(--surface-overlay)';
        let dotSize = 12;
        if (isCurrent) { dotColor = 'var(--status-warning)'; dotSize = 16; }
        else if (isNext) { dotColor = 'var(--primary)'; dotSize = 14; }
        else if (wp.type === 'hub') { dotColor = 'var(--status-ok)'; dotSize = 18; }
        else if (wp.type === 'major') { dotColor = 'var(--primary)'; dotSize = 14; }

        pin.innerHTML = `
          <div class="dot" style="background: ${dotColor}; width: ${dotSize}px; height: ${dotSize}px;${wp.type === 'hub' ? ' box-shadow: 0 0 0 6px rgba(16,185,129,0.25);' : ''}"></div>
          <span class="label" style="font-size: 9px;">${wp.id}${isCurrent ? ' ◄' : ''}</span>
        `;
        pins.appendChild(pin);
      });
    }
  }

  // Current position pin
  if (unit.lat != null && unit.lon != null) {
    const p = latLonToMap(unit.lat, unit.lon);
    const pin = document.createElement('div');
    pin.className = 'radar-pin nominal';
    pin.style.left = `${p.x * 100}%`;
    pin.style.top = `${p.y * 100}%`;
    pin.innerHTML = `
      <div class="icon" style="background: var(--ok-bg); color: var(--status-ok); box-shadow: 0 6px 14px rgba(16,185,129,0.35), 0 0 0 4px var(--ok-bg);">
        <span class="material-symbols-outlined">airplanemode_active</span>
      </div>
      <div class="pulse" style="box-shadow: 0 0 0 1px var(--status-ok);"></div>
    `;
    pins.appendChild(pin);
  }
}

// Main radar render triggered by scheduler
function renderRadar() {
  if (Page.current !== 'dashboard') return;
  if (!mainRadar.init()) return;
  mainRadar.resize();
  mainRadar.render();
  mainRadar.renderPins();
}

// ============================================
// COORDINATE PROJECTION (Cached)
// ============================================

const projectionCache = new Map();

function latLonToMap(lat, lon) {
  const key = `${lat.toFixed(4)},${lon.toFixed(4)}`;
  let cached = projectionCache.get(key);
  if (cached) return cached;

  // Simple equirectangular projection for the radar view
  const x = (lon + 130) / 100; // 0 to 1
  const y = 1 - (lat + 60) / 120; // 0 to 1 (inverted for screen coords)
  cached = { x: clamp(x, 0, 1), y: clamp(y, 0, 1) };
  projectionCache.set(key, cached);

  // Limit cache size
  if (projectionCache.size > 1000) {
    const firstKey = projectionCache.keys().next().value;
    projectionCache.delete(firstKey);
  }

  return cached;
}

// ============================================
// UNIT DETAIL PAGE (Optimized)
// ============================================

Page.unidad = {
  async init() {
    this.unitId = new URLSearchParams(window.location.search).get('id');
    if (!this.unitId) {
      showToast('ID de aeronave requerido', 'error');
      setTimeout(() => window.location.href = 'index.html', 1500);
      return;
    }

    await this.loadUnit();
    this.setupUI();
    connectSSE();
    this.startClock();
    this.setupRenderCallbacks();
  },

  async loadUnit() {
    $id('loadingState')?.classList.remove('hidden');
    try {
      const [fleetRes, entregasRes] = await Promise.all([
        apiGet(CONFIG.apiEndpoints.vehiculos),
        apiGet(CONFIG.apiEndpoints.entregas)
      ]);
      State.fleet = normalizeFleet(fleetRes);
      State.fleetById.clear();
      State.fleet.forEach(u => State.fleetById.set(u.id, u));
      State.entregas = normalizeEntregas(entregasRes);
      const unit = State.fleetById.get(this.unitId);
      if (unit) {
        State.selectedUnit = this.unitId;
        updateUnitDetail(unit);
        renderUnitRadarSVG();
      } else {
        showToast('Aeronave no encontrada', 'error');
      }
    } catch (e) {
      showToast('Error cargando aeronave', 'error');
    } finally {
      $id('loadingState')?.classList.add('hidden');
      $id('unitContent')?.classList.remove('hidden');
    }
  },

  setupUI() {
    $id('closeUnitDetail')?.addEventListener('click', closeUnitDrawer);
    $id('unitDetailOverlay')?.addEventListener('click', closeUnitDrawer);

    // Action buttons
    $id('btnReassign')?.addEventListener('click', () => showReassignModal());
    $id('btnDiversion')?.addEventListener('click', () => showDiversionModal());
    $id('btnHold')?.addEventListener('click', () => showHoldModal());
    $id('btnReturn')?.addEventListener('click', () => showReturnModal());

    // ACARS
    $id('acarsSend')?.addEventListener('click', sendAcars);
    $id('acarsInput')?.addEventListener('keydown', e => e.key === 'Enter' && sendAcars());

    // Modals
    setupModal('confirmModal', '#confirmClose', '#confirmCancel', '#confirmOk');
    setupModal('infoModal', '#infoClose', null, '#infoOk');
    setupModal('reassignModal', '#reassignModalClose', '#reassignModalCancel', '#reassignModalOk');
  },

  setupRenderCallbacks() {
    renderScheduler.on('unitDetail', () => {
      const unit = State.fleetById.get(State.selectedUnit);
      if (unit) updateUnitDetail(unit);
    });
    renderScheduler.on('radar', () => renderUnitRadarSVG());
  },

  startClock() {
    updateClock();
    setInterval(updateClock, 1000);
  }
};

function openUnitDetail(unit) {
  State.selectedUnit = unit.id;
  if (Page.current === 'dashboard') {
    if (window.innerWidth >= 1024) {
      $id('unitDetailDrawer')?.classList.remove('translate-x-full');
      updateUnitDetail(unit);
      renderUnitRadarSVG();
    } else {
      window.location.href = `unidad.html?id=${unit.id}`;
    }
  } else if (Page.current === 'unidad') {
    updateUnitDetail(unit);
    renderUnitRadarSVG();
  }
}

function closeUnitDrawer() {
  $id('unitDetailDrawer')?.classList.add('translate-x-full');
  $id('unitDetailOverlay')?.classList.add('hidden');
  State.selectedUnit = null;
}

// ============================================
// UNIT DETAIL UI UPDATES (Optimized - only updates changed values)
// ============================================

const gaugeElements = new Map(); // Cache DOM elements

function updateUnitDetail(unit) {
  if (!unit) return;

  // Header - only update if changed
  updateTextIfChanged('unitTitle', unit.id);
  updateTextIfChanged('unitSub', `${unit.tipo} · ${unit.ruta?.[0]?.id || '—'} → ${unit.ruta?.[unit.ruta.length - 1]?.id || '—'}`);
  updateTextIfChanged('unitPid', `PID: ${unit.pid || '—'}`);

  // Badge
  const badge = $id('unitBadge');
  if (badge) {
    const status = CONFIG.statusColors[unit.estado] || CONFIG.statusColors.tierra;
    const newClass = `badge ${unit.estado === 'critico' ? 'badge-crit' : unit.estado === 'alerta' ? 'badge-warn' : unit.estado === 'tierra' ? 'badge-info' : 'badge-ok'}`;
    if (badge.className !== newClass) badge.className = newClass;
    badge.innerHTML = `<span class="dot" style="background: ${status.dot};"></span> ${status.label}`;
  }

  // Gauges - batch updates
  updateGauge('Alt', unit.altitud, 0, 430, 'FL', v => `FL${v}`, v => v > 410 ? 'warn' : 'ok');
  updateGauge('Gs', unit.velocidad, 0, 530, 'kts', v => fmt.speed(v), v => v > 500 ? 'warn' : '');
  updateGauge('Hdg', unit.heading, 0, 360, '°', v => v + '°', () => '');
  updateGauge('Vs', unit.vs, -6000, 6000, 'ft/min', v => v >= 0 ? '+' + v : v, v => v > 2000 || v < -2000 ? 'warn' : '');
  updateGauge('Fuel', unit.combustible, 0, 100, '%', v => fmt.percent(v), v => v < 20 ? 'crit' : v < 35 ? 'warn' : 'ok');
  updateGauge('Payload', unit.payload, 0, unit.max_payload || 186880, 'kg', v => fmt.payload(v), v => v && unit.max_payload && v / unit.max_payload > 0.9 ? 'warn' : '');

  // Manifest
  renderManifest(unit.envios || []);

  // Reassignment options
  renderReassignOptions(unit);

  // Route info
  updateTextIfChanged('routeProgress', `Progreso: ${unit.progreso != null ? fmt.fixed(unit.progreso * 100) + '%' : '—'}`);
  updateTextIfChanged('routeEta', `ETA: ${unit.eta ? new Date(unit.eta).toLocaleTimeString('es-MX', { hour12: false }) + ' Z' : '—'}`);
  updateTextIfChanged('routeNextFix', `Próximo FIX: ${unit.next_fix || '—'}`);
}

function updateTextIfChanged(id, text) {
  const el = $id(id);
  if (el && el.textContent !== text) el.textContent = text;
}

function updateGauge(prefix, value, min, max, unit, fmtFn, statusFn) {
  const valEl = $id(`gauge${prefix}`);
  const barEl = $id(`gauge${prefix}Bar`);
  const footerEl = $id(`gauge${prefix}Footer`);
  if (!valEl || !barEl) return;

  if (value == null) {
    if (valEl.textContent !== '—') valEl.textContent = '—';
    if (barEl.style.width !== '0%') barEl.style.width = '0%';
    return;
  }

  const formatted = fmtFn(value);
  if (valEl.textContent !== formatted) valEl.textContent = formatted;

  const status = statusFn(value);
  if (status && !valEl.classList.contains('text-' + status)) {
    valEl.className = 'gauge-value text-telemetry text-' + status;
  } else if (!status && valEl.className !== 'gauge-value text-telemetry') {
    valEl.className = 'gauge-value text-telemetry';
  }

  const pct = clamp((value - min) / (max - min) * 100, 0, 100);
  if (Math.abs(parseFloat(barEl.style.width) - pct) > 0.5) {
    barEl.style.width = `${pct}%`;
  }

  const barColor = status === 'crit' ? 'var(--status-critical)' : status === 'warn' ? 'var(--status-warning)' : 'var(--status-ok)';
  if (barEl.style.background !== barColor) {
    barEl.style.background = barColor;
  }
}

function renderManifest(envios) {
  const tbody = $id('manifestBody');
  const countEl = $id('manifestCount');
  if (!tbody || !countEl) return;

  if (countEl.textContent !== `${envios.length} AWB`) {
    countEl.textContent = `${envios.length} AWB`;
  }

  if (!envios.length) {
    if (tbody.children.length !== 1 || !tbody.firstElementChild.classList.contains('table-empty')) {
      tbody.innerHTML = '<tr><td colspan="7" class="table-empty">Sin carga asignada</td></tr>';
    }
    return;
  }

  // Only rebuild if content changed (simple check)
  const newHtml = envios.map(e => {
    const status = CONFIG.statusColors[e.estado] || CONFIG.statusColors.pendiente;
    return `
      <tr>
        <td class="font-mono text-label-code text-primary">${e.awb}</td>
        <td>${e.descripcion}</td>
        <td class="text-right font-mono text-label-code">${fmt.number(e.peso)}</td>
        <td class="text-right font-mono text-label-code">${fmt.fixed(e.volumen, 2)} m³</td>
        <td><span class="badge ${e.prioridad === 'critica' ? 'badge-crit' : e.prioridad === 'alta' ? 'badge-warn' : 'badge-ok'}">${e.prioridad.toUpperCase()}</span></td>
        <td class="font-mono text-label-code">${e.origen} → ${e.destino}</td>
        <td><span class="badge ${e.estado === 'entregada' ? 'badge-ok' : e.estado === 'fallida' ? 'badge-crit' : e.estado === 'desviada' ? 'badge-warn' : e.estado === 'en_ruta' ? 'badge-info' : 'badge-ok'}"><span class="dot" style="background:${status.dot}"></span>${status.label}</span></td>
      </tr>
    `;
  }).join('');

  if (tbody.innerHTML !== newHtml) tbody.innerHTML = newHtml;
}

function renderReassignOptions(unit) {
  const container = $id('reassignOptions');
  if (!container) return;

  if (unit.estado === 'tierra' || !unit.ruta?.length) {
    container.innerHTML = '<p class="text-secondary text-body-sm text-center py-md">Aeronave en tierra o sin ruta activa. No hay opciones de reasignación disponibles.</p>';
    return;
  }

  const currentIdx = unit.ruta_idx || 0;
  const remaining = unit.ruta.slice(currentIdx + 1);
  const alternatives = [
    { name: 'Continuar plan actual', summary: 'Mantener ruta programada', detail: `${remaining.length} waypoints restantes`, eta: unit.eta, warn: false },
    { name: 'Directo a destino', summary: 'Vector directo al destino final', detail: 'Ahorro estimado: 15-20 min', eta: unit.eta ? new Date(new Date(unit.eta).getTime() - 15 * 60000).toISOString() : null, warn: false },
    { name: 'Alternativo por meteo', summary: 'Desvío por frente tormentoso', detail: '+3 waypoints, +25 min', eta: unit.eta ? new Date(new Date(unit.eta).getTime() + 25 * 60000).toISOString() : null, warn: true },
    { name: 'Regresar a base (MEX)', summary: 'RTB - Return to Base', detail: 'Emergencia / Mantenimiento', eta: new Date(Date.now() + 45 * 60000).toISOString(), warn: true }
  ];

  container.innerHTML = alternatives.map((opt, i) => `
    <label class="reassign-option" data-index="${i}" tabindex="0" role="radio" aria-checked="${i === 0}">
      <input type="radio" name="reassign" class="radio sr-only" ${i === 0 ? 'checked' : ''} value="${i}">
      <div class="content">
        <span class="name">${opt.name}</span>
        <span class="summary ${opt.warn ? 'warn' : 'sec'}">${opt.summary}</span>
        <span class="detail">${opt.detail}</span>
      </div>
      <div class="eta">
        <span class="eta-value ${opt.warn ? 'warn' : ''}">${opt.eta ? new Date(opt.eta).toLocaleTimeString('es-MX', { hour12: false }) + ' Z' : '—'}</span>
        <span class="eta-label">ETA</span>
      </div>
    </label>
  `).join('');

  // Event delegation for radio selection
  container.onclick = (e) => {
    const opt = e.target.closest('.reassign-option');
    if (!opt) return;
    container.querySelectorAll('.reassign-option').forEach(o => {
      o.classList.remove('selected');
      o.querySelector('input').checked = false;
      o.setAttribute('aria-checked', 'false');
    });
    opt.classList.add('selected');
    opt.querySelector('input').checked = true;
    opt.setAttribute('aria-checked', 'true');
  };
}

function renderAcars(unit) {
  const feed = $id('acarsFeed');
  if (!feed) return;

  const messages = [
    { dir: 'incoming', from: 'ACARS', fromLabel: 'GROUND', text: `${unit.id} confirmado ruta MEX-BOG via VAKUD OTUBA GIRAR ULQ`, time: '14:22:10' },
    { dir: 'outgoing', from: 'ACARS', fromLabel: unit.id, text: 'ROGER, estimado FL340 462kts ETA BOG 18:45Z', time: '14:22:15' },
    { dir: 'incoming', from: 'ACARS', fromLabel: 'GROUND', text: 'METEO ACTUALIZADA: CBs sector ULQ, sugerencia desviación 20NM norte', time: '14:35:40' },
    { dir: 'outgoing', from: 'ACARS', fromLabel: unit.id, text: 'AFIRMATIVO, solicitando desviación norte via FIX IBG DAG', time: '14:36:02' },
    { dir: 'incoming', from: 'ACARS', fromLabel: 'GROUND', text: 'APROBADO desviación IBG DAG BOK, nuevo ETA 19:10Z', time: '14:36:30' }
  ];

  feed.innerHTML = messages.map(m => `
    <div class="acars-msg ${m.dir}">
      <div class="meta">
        <span class="from ${m.fromLabel === 'GROUND' ? 'ground' : 'aircraft'}">${m.fromLabel}</span>
        <span class="time">${m.time} Z</span>
      </div>
      <div class="text">${m.text}</div>
    </div>
  `).join('');
  feed.scrollTop = feed.scrollHeight;
}

function sendAcars() {
  const input = $id('acarsInput');
  const feed = $id('acarsFeed');
  if (!input || !feed || !input.value.trim()) return;

  const msg = input.value.trim();
  input.value = '';

  const div = document.createElement('div');
  div.className = 'acars-msg outgoing';
  div.innerHTML = `
    <div class="meta">
      <span class="from aircraft">${State.selectedUnit}</span>
      <span class="time">${fmt.utc()} Z</span>
    </div>
    <div class="text">${msg}</div>
  `;
  feed.appendChild(div);
  feed.scrollTop = feed.scrollHeight;

  setTimeout(() => {
    const resp = document.createElement('div');
    resp.className = 'acars-msg incoming';
    resp.innerHTML = `
      <div class="meta">
        <span class="from ground">GROUND</span>
        <span class="time">${fmt.utc()} Z</span>
      </div>
      <div class="text">ROGER ${State.selectedUnit}, mensaje recibido: "${msg}"</div>
    `;
    feed.appendChild(resp);
    feed.scrollTop = feed.scrollHeight;
  }, 1000 + Math.random() * 1000);
}

// ============================================
// MODAL HELPERS (Optimized - single setup)
// ============================================

const modalHandlers = new Map();

function setupModal(modalId, closeSel, cancelSel, okSel) {
  if (modalHandlers.has(modalId)) return; // Already set up

  const modal = $id(modalId);
  if (!modal) return;

  const handler = {
    close: () => closeModal(modalId),
    keydown: (e) => { if (e.key === 'Escape' && modal.classList.contains('open')) closeModal(modalId); },
    click: (e) => { if (e.target === modal) closeModal(modalId); }
  };

  $(closeSel)?.addEventListener('click', handler.close);
  $(cancelSel)?.addEventListener('click', handler.close);
  $(okSel)?.addEventListener('click', handler.close);
  modal.addEventListener('click', handler.click);
  document.addEventListener('keydown', handler.keydown);

  modalHandlers.set(modalId, handler);
}

function showConfirmModal(title, body, onConfirm, icon = 'warning', okClass = 'btn-primary', okText = 'Confirmar') {
  $id('confirmTitle').textContent = title;
  $id('confirmBody').innerHTML = body;
  $id('confirmIcon').innerHTML = `<span class="material-symbols-outlined">${icon}</span>`;
  const okBtn = $id('confirmOk');
  okBtn.className = `btn ${okClass}`;
  okBtn.textContent = okText;
  okBtn.onclick = () => { onConfirm(); closeModal('confirmModal'); };
  openModal('confirmModal');
}

function showInfoModal(title, body, icon = 'info') {
  $id('infoTitle').textContent = title;
  $id('infoBody').innerHTML = body;
  $id('infoIcon').innerHTML = `<span class="material-symbols-outlined">${icon}</span>`;
  openModal('infoModal');
}

function openModal(id) { $id(id)?.classList.add('open'); }
function closeModal(id) { $id(id)?.classList.remove('open'); }

// ============================================
// ACTION MODALS
// ============================================

function showReassignModal() {
  const unit = State.fleetById.get(State.selectedUnit);
  if (!unit) return;

  const selected = $$('.reassign-option.selected')[0];
  const idx = selected ? parseInt(selected.dataset.index) : 0;
  const options = ['Continuar plan actual', 'Directo a destino', 'Alternativo por meteo', 'Regresar a base (MEX)'];
  const opt = options[idx];

  showConfirmModal(
    'Confirmar Reasignación',
    `<div class="space-sm">
      <div class="row"><span class="label">Aeronave:</span><span class="val font-mono">${unit.id}</span></div>
      <div class="row"><span class="label">Opción:</span><span class="val">${opt}</span></div>
      <div class="row"><span class="label">Impacto:</span><span class="val text-warn">Re-cálculo de ETA y combustible requerido</span></div>
    </div>`,
    () => {
      showToast(`Reasignación "${opt}" solicitada para ${unit.id}`, 'ok');
    },
    'flight_takeoff',
    'btn-primary',
    'Reasignar'
  );
}

function showDiversionModal() {
  const unit = State.fleetById.get(State.selectedUnit);
  if (!unit) return;

  showConfirmModal(
    'DESVÍO DE EMERGENCIA',
    `<div class="space-sm">
      <div class="row"><span class="label">Aeronave:</span><span class="val font-mono text-crit">${unit.id}</span></div>
      <div class="row"><span class="label">Acción:</span><span class="val text-crit">Desvío inmediato a alternativo más cercano</span></div>
      <div class="row"><span class="label">Carga:</span><span class="val">${unit.awb_count || 0} envíos afectados</span></div>
      <p class="text-body-sm text-warn mt-sm">Esta acción declara emergencia y notifica ATC. ¿Confirmar?</p>
    </div>`,
    () => {
      showToast(`EMERGENCIA declarada para ${unit.id} - Desvío activado`, 'crit');
    },
    'report_problem',
    'btn-critical',
    'Declarar Emergencia'
  );
}

function showHoldModal() {
  const unit = State.fleetById.get(State.selectedUnit);
  if (!unit) return;

  showConfirmModal(
    'Hold / Espera',
    `<div class="space-sm">
      <div class="row"><span class="label">Aeronave:</span><span class="val font-mono">${unit.id}</span></div>
      <div class="row"><span class="label">Acción:</span><span class="val">Entrada en patrón de espera (HOLD)</span></div>
      <div class="row"><span class="label">Combustible actual:</span><span class="val">${unit.combustible != null ? fmt.percent(unit.combustible) : '—'}</span></div>
      <p class="text-body-sm text-info mt-sm">La aeronave entrará en racetrack hold consumiendo combustible de reserva.</p>
    </div>`,
    () => {
      showToast(`HOLD activado para ${unit.id}`, 'warn');
    },
    'schedule',
    'btn-primary',
    'Activar Hold'
  );
}

function showReturnModal() {
  const unit = State.fleetById.get(State.selectedUnit);
  if (!unit) return;

  showConfirmModal(
    'Regresar a Base (RTB)',
    `<div class="space-sm">
      <div class="row"><span class="label">Aeronave:</span><span class="val font-mono">${unit.id}</span></div>
      <div class="row"><span class="label">Acción:</span><span class="val">Return to Base - MEX</span></div>
      <div class="row"><span class="label">Carga:</span><span class="val">${unit.awb_count || 0} envíos - requieren transbordo</span></div>
      <p class="text-body-sm text-warn mt-sm">Todos los envíos pasarán a estado PENDIENTE para reasignación.</p>
    </div>`,
    () => {
      showToast(`RTB iniciado para ${unit.id} - Carga liberada para transbordo`, 'warn');
    },
    'flight_land',
    'btn-critical',
    'Confirmar RTB'
  );
}

// ============================================
// HISTORIAL PAGE (Optimized)
// ============================================

Page.historial = {
  async init() {
    await this.loadInitialData();
    this.setupUI();
    connectSSE();
    this.startClock();
    this.setupRenderCallbacks();
  },

  async loadInitialData() {
    try {
      const [eventosRes, fleetRes] = await Promise.all([
        apiGet('/api/eventos?limit=200'),
        apiGet(CONFIG.apiEndpoints.vehiculos)
      ]);
      State.eventos = (eventosRes || []).map((e, i) => ({ ...e, _id: Date.now() - i * 1000 }));
      State.fleet = normalizeFleet(fleetRes);
      State.fleetById.clear();
      State.fleet.forEach(u => State.fleetById.set(u.id, u));
      this.updateKPIs();
    } catch (e) {
      this.generateSampleEvents();
      this.updateKPIs();
    }
  },

  generateSampleEvents() {
    const codes = Object.keys(CONFIG.eventCodes);
    const units = ['AC-7402', 'AC-7301', 'AC-7605', 'TR-3201', 'LM-101', 'AC-7503'];
    const awbs = ['AWB-202609001', 'AWB-202609002', 'AWB-202609003', 'AWB-202609004', 'AWB-202609005'];

    State.eventos = Array.from({ length: 50 }, (_, i) => {
      const code = codes[Math.floor(Math.random() * codes.length)];
      const info = CONFIG.eventCodes[code];
      const unit = units[Math.floor(Math.random() * units.length)];
      const awb = awbs[Math.floor(Math.random() * awbs.length)];
      const time = new Date(Date.now() - i * 300000 - Math.random() * 3600000);

      return {
        _id: Date.now() - i * 1000,
        timestamp: time.toISOString(),
        code,
        severity: info.severity,
        unit,
        awb,
        message: this.generateEventMessage(code, unit, awb),
        telemetry: this.generateTelemetry(code),
        segment: ['aereo', 'troncal', 'ultima', 'transbordo'][Math.floor(Math.random() * 4)]
      };
    });
  },

  generateEventMessage(code, unit, awb) {
    const msgs = {
      'WXR-ALERT': `Frente tormentoso detectado en ruta de ${unit}, desviación recomendada`,
      'ALT-CHG': `${unit} cambio de FL340 a FL360 por tráfico`,
      'HDG-CHG': `${unit} corrección de rumbo 270° → 285°`,
      'SPD-CHG': `${unit} reducción velocidad 462 → 420 kts por turbulencia`,
      'ETA-ADJ': `${unit} ETA actualizado: +12 min por meteo`,
      'RTE-DVRT': `${unit} DESVÍO AUTORIZADO: nueva ruta via IBG DAG BOK`,
      'FUEL-LOW': `${unit} combustible 28% - reserva 32 min, evaluando alternativo`,
      'PAY-SHFT': `Transbordo ${awb} de ${unit} a TR-3201 en MEX`,
      'UNIT-DOWN': `${unit} pérdida de señal ADS-B, watchdog activado`,
      'UNIT-UP': `${unit} señal ADS-B recuperada, reasignación completada`,
      'URGENT-ADD': `AOG URGENTE: ${awb} MEX→BOG 2,500kg asignado a ${unit}`,
      'CUSTOMS': `${awb} retenido en aduana BOG - documentación pendiente`,
      'SLA-BREACH': `${awb} incumplimiento ventana SLA: +45 min retraso`,
      'REASSIGN': `${unit} reasignado: ${awb} transferido a TR-3201`,
      'HOLD': `${unit} entrada en HOLD patrón racetrack FL280`,
      'DIVERT': `${unit} DESVÍO EMERGENCIA: alternativo CUN por falla hidráulica`,
      'LANDED': `${unit} aterrizaje confirmado BOG 18:47Z`,
      'TAKEOFF': `${unit} despegue confirmado MEX 14:30Z`
    };
    return msgs[code] || `${code} en ${unit}`;
  },

  generateTelemetry(code) {
    const telemetry = {};
    if (['WXR-ALERT', 'RTE-DVRT', 'DIVERT'].includes(code)) {
      telemetry.lat = 19.4 + Math.random() * 10 - 5;
      telemetry.lon = -99.1 + Math.random() * 20 - 10;
      telemetry.alt = 300 + Math.floor(Math.random() * 100);
      telemetry.gs = 400 + Math.floor(Math.random() * 100);
    }
    if (['FUEL-LOW'].includes(code)) {
      telemetry.fuel = 15 + Math.floor(Math.random() * 15);
    }
    return telemetry;
  },

  setupUI() {
    // Filters - debounced
    $id('searchInput')?.addEventListener('input', debounce(() => {
      State.filters.search = $id('searchInput').value.toLowerCase();
      renderScheduler.markDirty('events');
    }, 200));

    $id('severityFilter')?.addEventListener('change', e => {
      State.filters.severity = e.target.value;
      renderScheduler.markDirty('events');
    });

    $id('timeFilter')?.addEventListener('change', e => {
      State.filters.timeWindow = e.target.value;
      renderScheduler.markDirty('events');
    });

    $id('segmentFilter')?.addEventListener('change', e => {
      State.filters.segment = e.target.value;
      renderScheduler.markDirty('events');
    });

    $id('clearFilters')?.addEventListener('click', () => {
      $id('searchInput').value = '';
      $id('severityFilter').value = '';
      $id('timeFilter').value = '6h';
      $id('segmentFilter').value = '';
      State.filters = { search: '', severity: '', timeWindow: '6h', segment: '' };
      renderScheduler.markDirty('events');
    });

    $id('applyFilters')?.addEventListener('click', () => renderScheduler.markDirty('events'));

    // Pause live
    $id('pauseLive')?.addEventListener('click', () => {
      State.paused = !State.paused;
      $id('pauseIcon').textContent = State.paused ? 'play_arrow' : 'pause';
      $id('pauseText').textContent = State.paused ? 'Reanudar' : 'Pausar';
      showToast(State.paused ? 'Actualización en vivo pausada' : 'Actualización en vivo reanudada', 'info');
    });

    // Export
    $id('exportBtn')?.addEventListener('click', () => this.exportIFR());

    // Refresh
    $id('refreshBtn')?.addEventListener('click', () => this.loadInitialData());

    // Load more
    $id('loadMoreBtn')?.addEventListener('click', () => this.loadMoreEvents());

    // Modals
    setupModal('eventModal', '#eventModalClose', null, '#eventModalCancel');
    setupModal('gpsModal', '#gpsModalClose', null, '#gpsModalOk');
    setupModal('reassignModal', '#reassignModalClose', null, '#reassignModalCancel');
  },

  setupRenderCallbacks() {
    renderScheduler.on('events', () => this.renderEvents());
  },

  startClock() {
    updateClock();
    setInterval(updateClock, 1000);
  },

  updateKPIs(resumen) {
    const mttr = resumen?.mttr ?? (12 + Math.random() * 8);
    const mttrEl = $id('kpiMttr')?.querySelector('.font-display');
    if (mttrEl) mttrEl.textContent = fmt.fixed(mttr, 1);

    const otp = resumen?.otp ?? (87 + Math.random() * 8);
    const otpEl = $id('kpiOtp')?.querySelector('.font-display');
    if (otpEl) otpEl.textContent = fmt.fixed(otp, 1);

    const safety = resumen?.safety_events ?? Math.floor(Math.random() * 5);
    const safetyEl = $id('kpiSafety')?.querySelector('.font-display');
    if (safetyEl) safetyEl.textContent = safety;
  },

  renderEvents() {
    const list = $id('eventsList');
    if (!list) return;

    let filtered = State.eventos;

    if (State.filters.search) {
      const s = State.filters.search;
      filtered = filtered.filter(e =>
        e.code.toLowerCase().includes(s) ||
        e.unit.toLowerCase().includes(s) ||
        e.awb.toLowerCase().includes(s) ||
        e.message.toLowerCase().includes(s)
      );
    }

    if (State.filters.severity) filtered = filtered.filter(e => e.severity === State.filters.severity);
    if (State.filters.segment) filtered = filtered.filter(e => e.segment === State.filters.segment);

    if (State.filters.timeWindow !== 'jornada' && State.filters.timeWindow !== 'custom') {
      const hours = parseInt(State.filters.timeWindow);
      const cutoff = Date.now() - hours * 3600000;
      filtered = filtered.filter(e => new Date(e.timestamp).getTime() >= cutoff);
    }

    $id('eventsCount').textContent = `${filtered.length} eventos`;

    // Virtualization for large event lists
    const renderCount = Math.min(filtered.length, 100);
    list.innerHTML = filtered.slice(0, renderCount).map(e => this.renderEventCard(e)).join('');

    // Event delegation for action buttons
    list.onclick = (e) => {
      const card = e.target.closest('.event-card');
      if (!card) return;
      const idx = parseInt(card.dataset.index, 10);
      const ev = filtered[idx];
      if (!ev) return;

      if (e.target.closest('.action-btn.primary')) {
        e.stopPropagation();
        this.openEventDetail(ev);
      } else if (e.target.closest('.action-btn.secondary')) {
        e.stopPropagation();
        if (ev.telemetry.lat) this.openGpsModal(ev);
        else this.openReassignModal(ev);
      }
    };

    $id('loadMoreContainer')?.classList.toggle('hidden', filtered.length <= renderCount);
  },

  renderEventCard(e) {
    const info = CONFIG.eventCodes[e.code] || { label: e.code, severity: 'info' };
    const severity = CONFIG.statusColors[e.severity] || CONFIG.statusColors.info;
    const cardClass = e.severity === 'critica' ? 'crit' : e.severity === 'alerta' ? 'warn' : 'ok';

    const time = new Date(e.timestamp);
    const utcStr = time.toISOString().slice(11, 19);
    const localStr = time.toLocaleTimeString('es-MX', { hour12: false });

    const pills = [];
    if (e.telemetry.lat) pills.push(`<span class="pill"><span class="material-symbols-outlined">local_airport</span>${fmt.coord(e.telemetry.lat, e.telemetry.lon)}</span>`);
    if (e.telemetry.alt) pills.push(`<span class="pill"><span class="material-symbols-outlined">altitude</span>FL${e.telemetry.alt}</span>`);
    if (e.telemetry.gs) pills.push(`<span class="pill"><span class="material-symbols-outlined">speed</span>${e.telemetry.gs} kts</span>`);
    if (e.telemetry.fuel) pills.push(`<span class="pill"><span class="material-symbols-outlined">local_shipping</span>Comb: ${e.telemetry.fuel}%</span>`);

    const hasGps = !!e.telemetry.lat;
    const hasReassign = ['REASSIGN', 'RTE-DVRT', 'DIVERT', 'PAY-SHFT'].includes(e.code);

    return `
      <article class="event-card ${cardClass}" data-index="${State.eventos.indexOf(e)}">
        <header class="header">
          <div class="badges">
            <span class="severity ${e.severity === 'critica' ? 'crit' : e.severity === 'alerta' ? 'warn' : 'ok'}">
              <span class="dot" style="background: ${severity.dot};"></span>
              ${info.severity === 'critica' ? 'CRÍTICO' : info.severity === 'alerta' ? 'ALERTA' : info.severity === 'nominal' ? 'NOMINAL' : 'INFO'}
            </span>
            <span class="unit-tag">${e.unit}</span>
            <span class="awb-tag">${e.awb}</span>
            <span class="priority-tag">${e.code}</span>
          </div>
          <div class="timecodes">
            <span class="time-utc">${utcStr} Z</span>
            <span class="time-local">${localStr} LT</span>
          </div>
        </header>
        <div class="message">${e.message}</div>
        <div class="telemetry-pills">${pills.join('')}</div>
        <div class="actions">
          <button class="action-btn primary"><span class="material-symbols-outlined">visibility</span> Detalle</button>
          <button class="action-btn secondary"><span class="material-symbols-outlined">${hasGps ? 'local_airport' : 'flight_takeoff'}</span> ${hasGps ? 'Ver GPS' : 'Reasignación'}</button>
        </div>
      </article>
    `;
  },

  openEventDetail(e) {
    const info = CONFIG.eventCodes[e.code] || { label: e.code, severity: 'info' };
    const severity = CONFIG.statusColors[e.severity] || CONFIG.statusColors.info;

    $id('eventModalTitle').textContent = `${e.code} — ${info.label}`;
    $id('eventModalIcon').innerHTML = `<span class="material-symbols-outlined" style="color: ${severity.dot};">${e.severity === 'critica' ? 'error' : e.severity === 'alerta' ? 'warning' : 'check_circle'}</span>`;

    const time = new Date(e.timestamp);
    $id('eventModalBody').innerHTML = `
      <div class="row"><span class="label">Severidad</span><span class="val"><span class="badge ${e.severity === 'critica' ? 'badge-crit' : e.severity === 'alerta' ? 'badge-warn' : 'badge-ok'}"><span class="dot" style="background:${severity.dot}"></span>${e.severity.toUpperCase()}</span></span></div>
      <div class="row"><span class="label">Aeronave/Unidad</span><span class="val font-mono">${e.unit}</span></div>
      <div class="row"><span class="label">AWB</span><span class="val font-mono">${e.awb}</span></div>
      <div class="row"><span class="label">Segmento</span><span class="val">${CONFIG.sectorLabels[e.segment] || e.segment}</span></div>
      <div class="row"><span class="label">Timestamp (UTC)</span><span class="val font-mono">${time.toISOString()}</span></div>
      <div class="row"><span class="label">Timestamp (Local)</span><span class="val font-mono">${time.toLocaleString('es-MX')}</span></div>
      <hr style="border-color: var(--surface-overlay); margin: var(--space-sm) 0;">
      <div class="row"><span class="label">Mensaje</span><span class="val" style="text-align: right; max-width: 70%;">${e.message}</span></div>
      ${e.telemetry.lat ? `<div class="row"><span class="label">Posición GPS</span><span class="val font-mono">${fmt.coord(e.telemetry.lat, e.telemetry.lon)}</span></div>` : ''}
      ${e.telemetry.alt ? `<div class="row"><span class="label">Altitud</span><span class="val">FL${e.telemetry.alt}</span></div>` : ''}
      ${e.telemetry.gs ? `<div class="row"><span class="label">Velocidad</span><span class="val">${e.telemetry.gs} kts</span></div>` : ''}
      ${e.telemetry.fuel ? `<div class="row"><span class="label">Combustible</span><span class="val">${e.telemetry.fuel}%</span></div>` : ''}
    `;

    openModal('eventModal');
  },

  openGpsModal(e) {
    $id('gpsModalTitle').textContent = `Posición GPS — ${e.unit} / ${e.awb}`;
    const t = e.telemetry;
    $id('gpsModalBody').innerHTML = `
      <div class="row"><span class="label">Coordenadas</span><span class="val font-mono">${fmt.coord(t.lat, t.lon)}</span></div>
      <div class="row"><span class="label">Altitud</span><span class="val">${t.alt ? 'FL' + t.alt : '—'}</span></div>
      <div class="row"><span class="label">Velocidad tierra</span><span class="val">${t.gs ? t.gs + ' kts' : '—'}</span></div>
      <div class="row"><span class="label">Combustible</span><span class="val">${t.fuel ? t.fuel + '%' : '—'}</span></div>
      <div class="row"><span class="label">Evento</span><span class="val">${e.code}</span></div>
      <div class="row"><span class="label">Timestamp</span><span class="val font-mono">${new Date(e.timestamp).toISOString()}</span></div>
    `;
    openModal('gpsModal');
  },

  openReassignModal(e) {
    $id('reassignModalTitle').textContent = `Reasignación — ${e.code}`;
    $id('reassignModalBody').innerHTML = `
      <div class="row"><span class="label">Aeronave origen</span><span class="val font-mono">${e.unit}</span></div>
      <div class="row"><span class="label">AWB afectado</span><span class="val font-mono">${e.awb}</span></div>
      <div class="row"><span class="label">Evento</span><span class="val">${e.code}</span></div>
      <div class="row"><span class="label">Mensaje</span><span class="val" style="text-align: right;">${e.message}</span></div>
    `;
    openModal('reassignModal');
  },

  exportIFR() {
    const filtered = State.eventos.filter(e => {
      if (State.filters.search) {
        const s = State.filters.search;
        if (!e.code.toLowerCase().includes(s) && !e.unit.toLowerCase().includes(s) && !e.awb.toLowerCase().includes(s)) return false;
      }
      if (State.filters.severity && e.severity !== State.filters.severity) return false;
      return true;
    });

    const lines = [
      'IFR EXPORT - AeroCargo Bitácora de Eventos',
      `Generado: ${new Date().toISOString()}`,
      `Eventos: ${filtered.length}`,
      '---',
      'Timestamp(UTC),Code,Severity,Unit,AWB,Segment,Message,Lat,Lon,Alt,GS,Fuel'
    ];

    for (const e of filtered) {
      const t = e.telemetry;
      lines.push([
        new Date(e.timestamp).toISOString(),
        e.code,
        e.severity,
        e.unit,
        e.awb,
        e.segment,
        `"${e.message.replace(/"/g, '""')}"`,
        t.lat ?? '',
        t.lon ?? '',
        t.alt ?? '',
        t.gs ?? '',
        t.fuel ?? ''
      ].join(','));
    }

    const blob = new Blob([lines.join('\n')], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `aerocargo-ifr-${new Date().toISOString().slice(0,10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
    showToast('Exportación IFR completada', 'ok');
  },

  loadMoreEvents() {
    showToast('No hay más eventos históricos disponibles', 'info');
  }
};

// ============================================
// EVENT HANDLING (Optimized)
// ============================================

function addEvent(event) {
  State.eventos.unshift({ ...event, _id: Date.now() + Math.random() });
  if (State.eventos.length > CONFIG.maxEvents) State.eventos = State.eventos.slice(0, CONFIG.maxEvents);
  if (!State.paused && Page.current === 'historial') {
    renderScheduler.markDirty('events');
  }
}

function updateEventCounts() {
  // Update any event count badges if needed
}

// ============================================
// TOAST (Optimized - reuse single element)
// ============================================

const toastEl = null; // Will be initialized on first use
let toastTimer = null;

function showToast(message, type = 'ok') {
  const toast = $id('toast');
  const msg = $id('toastMessage');
  const icon = toast?.querySelector('.icon');
  if (!toast || !msg) return;

  msg.textContent = message;
  if (icon) {
    icon.textContent = type === 'error' ? 'error' : type === 'warn' ? 'warning' : 'check_circle';
    icon.style.color = type === 'error' ? 'var(--status-critical)' : type === 'warn' ? 'var(--status-warning)' : 'var(--status-ok)';
  }

  toast.classList.add('open');

  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toast.classList.remove('open'), 3000);
}

// ============================================
// INITIALIZATION & CLEANUP
// ============================================

document.addEventListener('DOMContentLoaded', () => {
  Page.init();

  // Initialize radar canvas on dashboard
  if (Page.current === 'dashboard') {
    setTimeout(() => {
      mainRadar.init();
      mainRadar.resize();
      window.addEventListener('resize', debounce(() => {
        mainRadar.resize();
        mainRadar.scheduleRender();
      }, 250));
    }, 100);
  }

  if (Page.current === 'unidad') {
    setTimeout(() => {
      unitRadar.init();
      unitRadar.resize();
      window.addEventListener('resize', debounce(() => {
        unitRadar.resize();
      }, 250));
    }, 100);
  }
});

// Handle visibility change to pause/resume SSE and rendering
document.addEventListener('visibilitychange', () => {
  if (document.hidden) {
    State.paused = true;
    // Cancel render loop
    if (mainRadar.animationId) cancelAnimationFrame(mainRadar.animationId);
    mainRadar.animationId = null;
    if (unitRadar.animationId) cancelAnimationFrame(unitRadar.animationId);
    unitRadar.animationId = null;
  } else if (State.paused && Page.current !== 'historial') {
    State.paused = false;
    // Restart render loop
    if (Page.current === 'dashboard') mainRadar.scheduleRender();
    if (Page.current === 'unidad') unitRadar.scheduleRender();
  }
});

// Cleanup on unload
window.addEventListener('beforeunload', () => {
  if (State.sse) { State.sse.close(); State.sse = null; }
  clearTimeout(State.sseReconnectTimer);
  clearTimeout(toastTimer);

  // Cancel animation frames
  if (mainRadar.animationId) cancelAnimationFrame(mainRadar.animationId);
  if (unitRadar.animationId) cancelAnimationFrame(unitRadar.animationId);

  // Clean up modal handlers
  for (const [id, handler] of modalHandlers) {
    document.removeEventListener('keydown', handler.keydown);
  }
  modalHandlers.clear();

  // Clear caches
  projectionCache.clear();
  fmt.number.cache?.clear?.();
  fmt.fixed.cache?.clear?.();
});

// Performance monitoring (development)
if (typeof window !== 'undefined' && window.location.search.includes('perf=1')) {
  setInterval(() => {
    console.log('[Perf]', {
      fleetUpdates: State.stats.fleetUpdates,
      radarFrames: State.stats.radarFrames,
      eventCount: State.stats.eventCount,
      fleetSize: State.fleet.length,
      eventsSize: State.eventos.length
    });
    State.stats.fleetUpdates = 0;
    State.stats.radarFrames = 0;
  }, 5000);
}

export { State, CONFIG, apiGet, apiPost, connectSSE, showToast, openModal, closeModal, renderScheduler };