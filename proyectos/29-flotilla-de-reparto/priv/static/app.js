/**
 * AeroCargo Telematics & Dispatch Operations
 * Main application module - handles Dashboard, Unit Detail, and Bitácora
 * Design tokens from Stitch export DESIGN.md
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
  refreshInterval: 5000,
  sseReconnectDelay: 3000,
  maxEvents: 500,
  mapDefaults: {
    center: { lat: 19.4326, lon: -99.1332 }, // MEX
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
// UTILITIES
// ============================================

const $ = (sel, ctx = document) => ctx.querySelector(sel);
const $$ = (sel, ctx = document) => [...ctx.querySelectorAll(sel)];

const fmt = {
  utc: () => new Date().toISOString().slice(11, 19),
  local: () => new Date().toLocaleTimeString('es-MX', { hour12: false }),
  number: (n, dec = 0) => Number(n).toLocaleString('es-MX', { minimumFractionDigits: dec, maximumFractionDigits: dec }),
  fixed: (n, dec = 1) => Number(n).toFixed(dec),
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

const clamp = (v, min, max) => Math.max(min, Math.min(max, v));
const lerp = (a, b, t) => a + (b - a) * t;

function debounce(fn, ms) {
  let t; return (...args) => { clearTimeout(t); t = setTimeout(() => fn(...args), ms); };
}

function throttle(fn, ms) {
  let last = 0; return (...args) => { const now = Date.now(); if (now - last >= ms) { last = now; fn(...args); } };
}

function showToast(message, type = 'ok') {
  const toast = $('#toast');
  const msg = $('#toastMessage');
  const icon = toast.querySelector('.icon');
  if (!toast || !msg) return;
  msg.textContent = message;
  icon.textContent = type === 'error' ? 'error' : type === 'warn' ? 'warning' : 'check_circle';
  icon.style.color = type === 'error' ? 'var(--status-critical)' : type === 'warn' ? 'var(--status-warning)' : 'var(--status-ok)';
  toast.classList.add('open');
  setTimeout(() => toast.classList.remove('open'), 3000);
}

function openModal(id) { $(`#${id}`).classList.add('open'); }
function closeModal(id) { $(`#${id}`).classList.remove('open'); }

// ============================================
// STATE MANAGEMENT
// ============================================

const State = {
  fleet: [],
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
  mapState: {
    zoom: 4,
    center: { x: 0.5, y: 0.5 },
    layers: { fleet: true, weather: false, routes: true, hubs: true },
    pinnedUnit: null
  },
  paused: false,
  lastTick: 0,
  renderScheduled: false
};

// ============================================
// API CLIENT
// ============================================

async function apiGet(endpoint) {
  try {
    const res = await fetch(endpoint, { headers: { 'Accept': 'application/json' } });
    if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
    return await res.json();
  } catch (e) {
    console.error(`API GET ${endpoint}:`, e);
    throw e;
  }
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
// SSE HANDLER
// ============================================

function connectSSE() {
  if (State.sse) { State.sse.close(); State.sse = null; }
  const url = new URL(CONFIG.sseEndpoint, window.location.origin);
  const es = new EventSource(url);
  State.sse = es;

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

  es.addEventListener('estado', (e) => {
    try {
      const data = JSON.parse(e.data);
      handleSSEData(data);
    } catch (err) {
      console.error('[SSE] Parse error:', err);
    }
  });

  return es;
}

function updateLiveBadge(connected) {
  const live = $('#liveBadge');
  const paused = $('#pausedBadge');
  if (live && paused) {
    live.classList.toggle('hidden', !connected);
    paused.classList.toggle('hidden', connected);
  }
}

function handleSSEData(data) {
  if (data.tick !== undefined) State.lastTick = data.tick;

  if (data.unidades) {
    State.fleet = data.unidades;
    updateFleetUI();
  }

  if (data.resumen) {
    updateKPIs(data.resumen);
    updateSidebarCounts(data.resumen);
  }

  if (data.eventos) {
    data.eventos.forEach(ev => addEvent(ev));
    updateEventCounts();
  }

  if (State.selectedUnit) {
    const unit = State.fleet.find(u => u.id === State.selectedUnit);
    if (unit) updateUnitDetail(unit);
  }

  updateClock();
}

function addEvent(event) {
  State.eventos.unshift({ ...event, _id: Date.now() + Math.random() });
  if (State.eventos.length > CONFIG.maxEvents) State.eventos = State.eventos.slice(0, CONFIG.maxEvents);
  if (!State.paused) renderEvents();
}

// ============================================
// DATA TRANSFORMATION
// ============================================

function normalizeFleet(raw) {
  return (raw || []).map(u => ({
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
  }));
}

function normalizeEntregas(raw) {
  return (raw || []).map(e => ({
    awb: e.awb || e.id,
    descripcion: e.descripcion || e.desc || 'Carga general',
    peso: e.peso ?? e.weight_kg ?? 0,
    volumen: e.volumen ?? e.volume ?? 0,
    prioridad: e.prioridad || e.priority || 'normal',
    origen: e.origen || e.origin_iata || e.origen_iata,
    destino: e.destino || e.dest_iata || e.destino_iata,
    estado: e.estado || e.status || 'pendiente',
    unidad: e.unidad || u.aeronave || e.assigned_unit,
    sla_ventana: e.sla_ventana || e.sla_window,
    retraso: e.retraso ?? e.delay ?? 0
  }));
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
// DASHBOARD PAGE (index.html)
// ============================================

Page.dashboard = {
  async init() {
    await this.loadInitialData();
    this.setupUI();
    connectSSE();
    this.startClock();
  },

  async loadInitialData() {
    try {
      const [fleetRes, entregasRes, estadoRes] = await Promise.all([
        apiGet(CONFIG.apiEndpoints.vehiculos),
        apiGet(CONFIG.apiEndpoints.entregas),
        apiGet(CONFIG.apiEndpoints.estado)
      ]);
      State.fleet = normalizeFleet(fleetRes);
      State.entregas = normalizeEntregas(entregasRes);
      if (estadoRes?.resumen) {
        updateKPIs(estadoRes.resumen);
        updateSidebarCounts(estadoRes.resumen);
      }
      updateFleetUI();
      renderRadar();
    } catch (e) {
      showToast('Error cargando datos iniciales', 'error');
    }
  },

  setupUI() {
    // Sidebar toggle
    $('#sidebarToggle')?.addEventListener('click', () => {
      $('#sidebar').classList.remove('-translate-x-full');
      $('#sidebarOverlay').classList.remove('hidden');
    });
    $('#sidebarClose')?.addEventListener('click', closeSidebar);
    $('#sidebarOverlay')?.addEventListener('click', closeSidebar);

    // Fleet search
    $('#fleetSearch')?.addEventListener('input', debounce(() => {
      State.filters.search = $('#fleetSearch').value.toLowerCase();
      updateFleetUI();
    }, 150));

    // Filter checkboxes
    $$('.filter-checkbox').forEach(cb => {
      cb.addEventListener('change', () => {
        const name = cb.name.replace('filter', '').toLowerCase();
        const vals = State.filters[name + 's'] || State.filters[name];
        if (cb.checked) { if (!vals.includes(cb.value)) vals.push(cb.value); }
        else { const i = vals.indexOf(cb.value); if (i >= 0) vals.splice(i, 1); }
        updateFleetUI();
        updateSidebarCounts();
      });
    });

    // Refresh
    $('#refreshFleet')?.addEventListener('click', () => loadInitialData());

    // Map layers
    $('#layerFleet')?.addEventListener('click', toggleLayer.bind(null, 'fleet', '#layerFleet'));
    $('#layerWeather')?.addEventListener('click', toggleLayer.bind(null, 'weather', '#layerWeather'));
    $('#layerRoutes')?.addEventListener('click', toggleLayer.bind(null, 'routes', '#layerRoutes'));
    $('#layerHubs')?.addEventListener('click', toggleLayer.bind(null, 'hubs', '#layerHubs'));

    // Map controls
    $('#zoomIn')?.addEventListener('click', () => adjustZoom(1));
    $('#zoomOut')?.addEventListener('click', () => adjustZoom(-1));
    $('#resetView')?.addEventListener('click', resetMapView);
    $('#centerFleet')?.addEventListener('click', centerOnFleet);
    $('#fullscreenMap')?.addEventListener('click', toggleFullscreen);

    // Settings
    $('#settingsBtn')?.addEventListener('click', () => showInfoModal('Configuración', 'Panel de configuración en desarrollo.'));

    // Close unit detail drawer on mobile
    $('#closeUnitDetail')?.addEventListener('click', closeUnitDrawer);
    $('#unitDetailOverlay')?.addEventListener('click', closeUnitDrawer);
  },

  startClock() {
    updateClock();
    setInterval(updateClock, 1000);
  }
};

function closeSidebar() {
  $('#sidebar')?.classList.add('-translate-x-full');
  $('#sidebarOverlay')?.classList.add('hidden');
}

function toggleLayer(layer, btnSel) {
  State.mapState.layers[layer] = !State.mapState.layers[layer];
  const btn = $(btnSel);
  if (btn) btn.setAttribute('aria-pressed', State.mapState.layers[layer]);
  renderRadar();
}

function adjustZoom(delta) {
  State.mapState.zoom = clamp(State.mapState.zoom + delta, CONFIG.mapDefaults.minZoom, CONFIG.mapDefaults.maxZoom);
  renderRadar();
}

function resetMapView() {
  State.mapState.zoom = CONFIG.mapDefaults.zoom;
  State.mapState.center = { x: 0.5, y: 0.5 };
  renderRadar();
}

function centerOnFleet() {
  const airborne = State.fleet.filter(u => u.estado !== 'tierra' && u.lat != null && u.lon != null);
  if (airborne.length) {
    const avgLat = airborne.reduce((s, u) => s + u.lat, 0) / airborne.length;
    const avgLon = airborne.reduce((s, u) => s + u.lon, 0) / airborne.length;
    State.mapState.center = latLonToMap(avgLat, avgLon);
    State.mapState.zoom = 5;
    renderRadar();
  }
}

function toggleFullscreen() {
  const container = $('#radarContainer');
  if (!container) return;
  if (!document.fullscreenElement) container.requestFullscreen();
  else document.exitFullscreen();
}

// ============================================
// FLEET UI UPDATES
// ============================================

function updateFleetUI() {
  const list = $('#fleetList');
  if (!list) return;

  let filtered = State.fleet.filter(u => {
    if (State.filters.search) {
      const s = State.filters.search;
      const match = u.id.toLowerCase().includes(s) ||
        u.tipo.toLowerCase().includes(s) ||
        u.envios?.some(e => e.awb?.toLowerCase().includes(s));
      if (!match) return false;
    }
    if (!State.filters.sectors.includes(u.sector)) return false;
    if (!State.filters.statuses.includes(u.estado)) return false;
    if (!State.filters.priorities.includes(u.prioridad)) return false;
    return true;
  });

  // Sort: airborne first, then by priority, then by ID
  filtered.sort((a, b) => {
    const aAir = a.estado !== 'tierra' ? 0 : 1;
    const bAir = b.estado !== 'tierra' ? 0 : 1;
    if (aAir !== bAir) return aAir - bAir;
    const prioOrder = { critica: 0, alta: 1, normal: 2 };
    return (prioOrder[a.prioridad] ?? 2) - (prioOrder[b.prioridad] ?? 2);
  });

  list.innerHTML = filtered.map(renderFleetCard).join('');

  // Click handlers
  $$('.fleet-card', list).forEach((card, i) => {
    card.addEventListener('click', () => openUnitDetail(filtered[i]));
  });
}

function renderFleetCard(u) {
  const status = CONFIG.statusColors[u.estado] || CONFIG.statusColors.tierra;
  const cardClass = u.estado === 'critico' ? 'critical' : u.estado === 'alerta' ? 'alert' : 'nominal';
  const iconType = u.sector === 'aereo' ? 'flight_takeoff' : u.sector === 'troncal' ? 'directions_runway' : 'local_shipping';
  const iconClass = u.estado === 'critico' ? 'crit' : u.estado === 'alerta' ? 'warn' : u.estado === 'tierra' ? 'info' : 'ok';

  const alt = u.altitud ? fmt.altitude(u.altitud) : '—';
  const gs = u.velocidad ? fmt.speed(u.velocidad) : '—';
  const payload = u.payload != null ? fmt.payload(u.payload) : '—';

  return `
    <article class="fleet-card ${cardClass}" role="listitem" tabindex="0" data-id="${u.id}" aria-label="${u.id}, ${u.tipo}, ${status.label}">
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
    $('#countAereo').textContent = bySector.aereo || 0;
    $('#countTroncal').textContent = bySector.troncal || 0;
    $('#countUltima').textContent = bySector.ultima || 0;
  }
  const byStatus = { nominal: 0, alerta: 0, critico: 0, tierra: 0 };
  const byPriority = { critica: 0, alta: 0, normal: 0 };
  State.fleet.forEach(u => {
    if (byStatus[u.estado] !== undefined) byStatus[u.estado]++;
    if (byPriority[u.prioridad] !== undefined) byPriority[u.prioridad]++;
  });
  $('#countNominal').textContent = byStatus.nominal;
  $('#countAlerta').textContent = byStatus.alerta;
  $('#countCritico').textContent = byStatus.critico;
  $('#countTierra').textContent = byStatus.tierra;
  $('#countPriCritica').textContent = byPriority.critica;
  $('#countPriAlta').textContent = byPriority.alta;
  $('#countPriNormal').textContent = byPriority.normal;
  $('#fleetCount').textContent = State.fleet.length;
}

// ============================================
// KPI UPDATES
// ============================================

function updateKPIs(resumen) {
  // Dashboard KPIs would go here if we had them in index.html
  // For now, historial.html has its own KPI section
  if (Page.current === 'historial') Page.historial.updateKPIs(resumen);
}

// ============================================
// CLOCK
// ============================================

function updateClock() {
  const utc = $('#clockUtc');
  if (utc) utc.textContent = fmt.utc();
}

// ============================================
// RADAR MAP (Canvas/SVG)
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

function latLonToMap(lat, lon) {
  // Simple equirectangular projection for the radar view
  // World bounds approx: lat -60 to 60, lon -130 to -30 for Americas focus
  const x = (lon + 130) / 100; // 0 to 1
  const y = 1 - (lat + 60) / 120; // 0 to 1 (inverted for screen coords)
  return { x: clamp(x, 0, 1), y: clamp(y, 0, 1) };
}

function mapToLatLon(x, y) {
  const lon = x * 100 - 130;
  const lat = (1 - y) * 120 - 60;
  return { lat, lon };
}

function renderRadar() {
  const container = $('#radarContainer');
  const pins = $('#radarPins');
  const svg = $('#radarSvg');
  if (!container || !pins || !svg) return;

  const rect = container.getBoundingClientRect();
  const w = rect.width;
  const h = rect.height;

  // Set SVG size
  svg.setAttribute('width', w);
  svg.setAttribute('height', h);
  svg.innerHTML = '';

  // Draw routes
  if (State.mapState.layers.routes) {
    State.fleet.filter(u => u.ruta?.length && u.estado !== 'tierra').forEach(u => {
      const points = u.ruta.map(wp => latLonToMap(wp.lat, wp.lon));
      if (points.length < 2) return;
      const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
      const d = points.map((p, i) => `${i === 0 ? 'M' : 'L'} ${p.x * w} ${p.y * h}`).join(' ');
      path.setAttribute('d', d);
      path.setAttribute('stroke', u.estado === 'critico' ? 'var(--status-critical)' : u.estado === 'alerta' ? 'var(--status-warning)' : 'var(--primary)');
      path.setAttribute('stroke-width', '2');
      path.setAttribute('fill', 'none');
      path.setAttribute('stroke-dasharray', u.estado === 'critico' ? '8,4' : u.estado === 'alerta' ? '6,6' : 'none');
      path.setAttribute('opacity', '0.7');
      svg.appendChild(path);

      // Progress indicator
      if (u.progreso > 0 && u.progreso < 1) {
        const progIdx = Math.floor(u.progreso * (points.length - 1));
        const p = points[progIdx];
        const circle = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
        circle.setAttribute('cx', p.x * w);
        circle.setAttribute('cy', p.y * h);
        circle.setAttribute('r', '6');
        circle.setAttribute('fill', 'var(--status-warning)');
        circle.setAttribute('stroke', 'var(--canvas-default)');
        circle.setAttribute('stroke-width', '2');
        svg.appendChild(circle);
      }
    });
  }

  // Draw hubs
  if (State.mapState.layers.hubs) {
    HUBS.forEach(hub => {
      const p = latLonToMap(hub.lat, hub.lon);
      const pin = document.createElement('div');
      pin.className = 'radar-pin';
      pin.style.left = `${p.x * 100}%`;
      pin.style.top = `${p.y * 100}%`;
      pin.innerHTML = `
        <div class="icon">
          <span class="material-symbols-outlined">local_airport</span>
        </div>
        <div class="radar-tooltip">
          <div class="header">
            <span class="title">${hub.id} — ${hub.name}</span>
          </div>
          <div class="grid">
            <span class="key">Tipo</span><span class="val">${hub.type === 'hub' ? 'Hub Principal' : 'Aeropuerto Mayor'}</span>
            <span class="key">Coords</span><span class="val">${fmt.coord(hub.lat, hub.lon)}</span>
          </div>
        </div>
      `;
      pins.appendChild(pin);
    });
  }

  // Draw fixes (waypoints)
  FIXES.forEach(fix => {
    const p = latLonToMap(fix.lat, fix.lon);
    const el = document.createElement('div');
    el.className = 'waypoint fix';
    el.style.left = `${p.x * 100}%`;
    el.style.top = `${p.y * 100}%`;
    el.innerHTML = `<div class="dot" style="background: var(--surface-overlay); width: 6px; height: 6px;"></div><span class="label" style="font-size: 8px; color: var(--text-muted);">${fix.id}</span>`;
    pins.appendChild(el);
  });

  // Draw fleet pins
  if (State.mapState.layers.fleet) {
    State.fleet.filter(u => u.lat != null && u.lon != null).forEach(u => {
      const p = latLonToMap(u.lat, u.lon);
      const status = CONFIG.statusColors[u.estado] || CONFIG.statusColors.tierra;
      const pinClass = u.estado === 'critico' ? 'crit' : u.estado === 'alerta' ? 'alert' : u.estado === 'tierra' ? 'info' : 'nominal';
      const icon = u.sector === 'aereo' ? 'flight_takeoff' : u.sector === 'troncal' ? 'directions_runway' : 'local_shipping';

      const pin = document.createElement('div');
      pin.className = `radar-pin ${pinClass}`;
      pin.style.left = `${p.x * 100}%`;
      pin.style.top = `${p.y * 100}%`;
      pin.dataset.id = u.id;

      const tooltipHtml = `
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
      `;

      pin.innerHTML = `
        <div class="icon">
          <span class="material-symbols-outlined">${icon}</span>
        </div>
        <div class="pulse" style="box-shadow: 0 0 0 1px ${status.dot};"></div>
        <div class="radar-tooltip">${tooltipHtml}</div>
      `;

      pin.addEventListener('click', (e) => {
        e.stopPropagation();
        openUnitDetail(u);
      });
      pins.appendChild(pin);
    });
  }

  // Update unit radar if open
  if (Page.current === 'unidad' && State.selectedUnit) {
    renderUnitRadar();
  }
}

function renderUnitRadar() {
  const svg = $('#unitRadarSvg');
  const pins = $('#unitRadarPins');
  if (!svg || !pins) return;

  const container = $('#unitRadarContainer');
  const rect = container.getBoundingClientRect();
  const w = rect.width;
  const h = rect.height;

  svg.setAttribute('width', w);
  svg.setAttribute('height', h);
  svg.innerHTML = '';
  pins.innerHTML = '';

  const unit = State.fleet.find(u => u.id === State.selectedUnit);
  if (!unit) return;

  // Draw route
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

// ============================================
// UNIT DETAIL PAGE (unidad.html)
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
  },

  async loadUnit() {
    $('#loadingState')?.classList.remove('hidden');
    try {
      const [fleetRes, entregasRes] = await Promise.all([
        apiGet(CONFIG.apiEndpoints.vehiculos),
        apiGet(CONFIG.apiEndpoints.entregas)
      ]);
      State.fleet = normalizeFleet(fleetRes);
      State.entregas = normalizeEntregas(entregasRes);
      const unit = State.fleet.find(u => u.id === this.unitId);
      if (unit) {
        State.selectedUnit = this.unitId;
        updateUnitDetail(unit);
        renderUnitRadar();
      } else {
        showToast('Aeronave no encontrada', 'error');
      }
    } catch (e) {
      showToast('Error cargando aeronave', 'error');
    } finally {
      $('#loadingState')?.classList.add('hidden');
      $('#unitContent')?.classList.remove('hidden');
    }
  },

  setupUI() {
    $('#closeUnitDetail')?.addEventListener('click', closeUnitDrawer);
    $('#unitDetailOverlay')?.addEventListener('click', closeUnitDrawer);

    // Action buttons
    $('#btnReassign')?.addEventListener('click', () => showReassignModal());
    $('#btnDiversion')?.addEventListener('click', () => showDiversionModal());
    $('#btnHold')?.addEventListener('click', () => showHoldModal());
    $('#btnReturn')?.addEventListener('click', () => showReturnModal());

    // ACARS
    $('#acarsSend')?.addEventListener('click', sendAcars);
    $('#acarsInput')?.addEventListener('keydown', e => e.key === 'Enter' && sendAcars());

    // Modals
    setupModal('confirmModal', '#confirmClose', '#confirmCancel', '#confirmOk');
    setupModal('infoModal', '#infoClose', null, '#infoOk');
    setupModal('reassignModal', '#reassignModalClose', '#reassignModalCancel', '#reassignModalOk');
  },

  startClock() {
    updateClock();
    setInterval(updateClock, 1000);
  }
};

function openUnitDetail(unit) {
  State.selectedUnit = unit.id;
  if (Page.current === 'dashboard') {
    // Open drawer on desktop, navigate on mobile
    if (window.innerWidth >= 1024) {
      $('#unitDetailDrawer')?.classList.remove('translate-x-full');
      updateUnitDetail(unit);
      renderUnitRadar();
    } else {
      window.location.href = `unidad.html?id=${unit.id}`;
    }
  } else if (Page.current === 'unidad') {
    updateUnitDetail(unit);
    renderUnitRadar();
  }
}

function closeUnitDrawer() {
  $('#unitDetailDrawer')?.classList.add('translate-x-full');
  $('#unitDetailOverlay')?.classList.add('hidden');
  State.selectedUnit = null;
}

function updateUnitDetail(unit) {
  if (!unit) return;

  // Header
  $('#unitTitle').textContent = unit.id;
  $('#unitSub').textContent = `${unit.tipo} · ${unit.ruta?.[0]?.id || '—'} → ${unit.ruta?.[unit.ruta.length - 1]?.id || '—'}`;
  $('#unitBadge').className = `badge ${unit.estado === 'critico' ? 'badge-crit' : unit.estado === 'alerta' ? 'badge-warn' : unit.estado === 'tierra' ? 'badge-info' : 'badge-ok'}`;
  $('#unitBadge').innerHTML = `<span class="dot" style="background: ${CONFIG.statusColors[unit.estado]?.dot || 'var(--status-info)'};"></span> ${CONFIG.statusColors[unit.estado]?.label || 'EN TIERRA'}`;
  $('#unitPid').textContent = `PID: ${unit.pid || '—'}`;

  // Gauges
  updateGauge('Alt', unit.altitud, 0, 430, 'FL', val => `FL${val}`, v => v > 410 ? 'warn' : 'ok');
  updateGauge('Gs', unit.velocidad, 0, 530, 'kts', val => fmt.speed(val), v => v > 500 ? 'warn' : '');
  updateGauge('Hdg', unit.heading, 0, 360, '°', val => val + '°', () => '');
  updateGauge('Vs', unit.vs, -6000, 6000, 'ft/min', val => val >= 0 ? '+' + val : val, v => v > 2000 || v < -2000 ? 'warn' : '');
  updateGauge('Fuel', unit.combustible, 0, 100, '%', val => fmt.percent(val), v => v < 20 ? 'crit' : v < 35 ? 'warn' : 'ok');
  updateGauge('Payload', unit.payload, 0, unit.max_payload || 186880, 'kg', val => fmt.payload(val), v => v && unit.max_payload && v / unit.max_payload > 0.9 ? 'warn' : '');

  // Manifest
  renderManifest(unit.envios || []);

  // Reassignment options
  renderReassignOptions(unit);

  // Route info
  $('#routeProgress').textContent = `Progreso: ${unit.progreso != null ? fmt.fixed(unit.progreso * 100) + '%' : '—'}`;
  $('#routeEta').textContent = `ETA: ${unit.eta ? new Date(unit.eta).toLocaleTimeString('es-MX', { hour12: false }) + ' Z' : '—'}`;
  $('#routeNextFix').textContent = `Próximo FIX: ${unit.next_fix || '—'}`;

  // ACARS - simulate some messages
  renderAcars(unit);
}

function updateGauge(prefix, value, min, max, unit, fmtFn, statusFn) {
  const valEl = $(`#gauge${prefix}`);
  const barEl = $(`#gauge${prefix}Bar`);
  const footerEl = $(`#gauge${prefix}Footer`);
  if (!valEl || !barEl) return;

  if (value == null) {
    valEl.textContent = '—';
    barEl.style.width = '0%';
    return;
  }

  valEl.textContent = fmtFn(value);
  valEl.className = 'gauge-value text-telemetry ' + (statusFn(value) || '');
  const pct = clamp((value - min) / (max - min) * 100, 0, 100);
  barEl.style.width = `${pct}%`;

  // Color the bar based on status
  const status = statusFn(value);
  barEl.style.background = status === 'crit' ? 'var(--status-critical)' : status === 'warn' ? 'var(--status-warning)' : 'var(--status-ok)';
}

function renderManifest(envios) {
  const tbody = $('#manifestBody');
  const countEl = $('#manifestCount');
  if (!tbody || !countEl) return;

  countEl.textContent = `${envios.length} AWB`;

  if (!envios.length) {
    tbody.innerHTML = '<tr><td colspan="7" class="table-empty">Sin carga asignada</td></tr>';
    return;
  }

  tbody.innerHTML = envios.map(e => {
    const status = CONFIG.statusColors[e.estado] || CONFIG.statusColors.pendiente;
    return `
      <tr>
        <td class="font-mono text-label-code text-primary">${e.awb}</td>
        <td>${e.descripcion}</td>
        <td class="text-right font-mono text-label-code">${fmt.number(e.peso)}</td>
        <td class="text-right font-mono text-label-code">${fmt.fixed(e.volumen, 2)} m³</td>
        <td>
          <span class="badge ${e.prioridad === 'critica' ? 'badge-crit' : e.prioridad === 'alta' ? 'badge-warn' : 'badge-ok'}">
            ${e.prioridad.toUpperCase()}
          </span>
        </td>
        <td class="font-mono text-label-code">${e.origen} → ${e.destino}</td>
        <td>
          <span class="badge ${e.estado === 'entregada' ? 'badge-ok' : e.estado === 'fallida' ? 'badge-crit' : e.estado === 'desviada' ? 'badge-warn' : e.estado === 'en_ruta' ? 'badge-info' : 'badge-ok'}">
            <span class="dot" style="background:${status.dot}"></span>
            ${status.label}
          </span>
        </td>
      </tr>
    `;
  }).join('');
}

function renderReassignOptions(unit) {
  const container = $('#reassignOptions');
  if (!container) return;

  if (unit.estado === 'tierra' || !unit.ruta?.length) {
    container.innerHTML = '<p class="text-secondary text-body-sm text-center py-md">Aeronave en tierra o sin ruta activa. No hay opciones de reasignación disponibles.</p>';
    return;
  }

  // Generate mock alternatives based on current route
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

  // Click handlers
  $$('.reassign-option', container).forEach(opt => {
    opt.addEventListener('click', () => {
      $$('.reassign-option', container).forEach(o => { o.classList.remove('selected'); o.querySelector('input').checked = false; o.setAttribute('aria-checked', 'false'); });
      opt.classList.add('selected');
      opt.querySelector('input').checked = true;
      opt.setAttribute('aria-checked', 'true');
    });
  });
}

function renderAcars(unit) {
  const feed = $('#acarsFeed');
  if (!feed) return;

  // Simulated ACARS messages
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
  const input = $('#acarsInput');
  const feed = $('#acarsFeed');
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

  // Simulate ground response after 1-2s
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
// MODAL HELPERS
// ============================================

function setupModal(modalId, closeSel, cancelSel, okSel) {
  const modal = $(`#${modalId}`);
  if (!modal) return;
  $(closeSel)?.addEventListener('click', () => closeModal(modalId));
  $(cancelSel)?.addEventListener('click', () => closeModal(modalId));
  $(okSel)?.addEventListener('click', () => closeModal(modalId));
  modal.addEventListener('click', e => { if (e.target === modal) closeModal(modalId); });
  document.addEventListener('keydown', e => { if (e.key === 'Escape' && modal.classList.contains('open')) closeModal(modalId); });
}

function showConfirmModal(title, body, onConfirm, icon = 'warning', okClass = 'btn-primary', okText = 'Confirmar') {
  $('#confirmTitle').textContent = title;
  $('#confirmBody').innerHTML = body;
  $('#confirmIcon').innerHTML = `<span class="material-symbols-outlined">${icon}</span>`;
  const okBtn = $('#confirmOk');
  okBtn.className = `btn ${okClass}`;
  okBtn.textContent = okText;
  okBtn.onclick = () => { onConfirm(); closeModal('confirmModal'); };
  openModal('confirmModal');
}

function showInfoModal(title, body, icon = 'info') {
  $('#infoTitle').textContent = title;
  $('#infoBody').innerHTML = body;
  $('#infoIcon').innerHTML = `<span class="material-symbols-outlined">${icon}</span>`;
  openModal('infoModal');
}

function showReassignModal() {
  const unit = State.fleet.find(u => u.id === State.selectedUnit);
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
      // TODO: API call to p29_despachador:reasignar/2
    },
    'flight_takeoff',
    'btn-primary',
    'Reasignar'
  );
}

function showDiversionModal() {
  const unit = State.fleet.find(u => u.id === State.selectedUnit);
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
      // TODO: API call to p29_despachador:desviar/1
    },
    'report_problem',
    'btn-critical',
    'Declarar Emergencia'
  );
}

function showHoldModal() {
  const unit = State.fleet.find(u => u.id === State.selectedUnit);
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
      // TODO: API call
    },
    'schedule',
    'btn-primary',
    'Activar Hold'
  );
}

function showReturnModal() {
  const unit = State.fleet.find(u => u.id === State.selectedUnit);
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
      // TODO: API call to p29_despachador:rtb/1
    },
    'flight_land',
    'btn-critical',
    'Confirmar RTB'
  );
}

// ============================================
// HISTORIAL PAGE (historial.html)
// ============================================

Page.historial = {
  async init() {
    await this.loadInitialData();
    this.setupUI();
    connectSSE();
    this.startClock();
    this.renderEvents();
  },

  async loadInitialData() {
    try {
      const [eventosRes, fleetRes] = await Promise.all([
        apiGet('/api/eventos?limit=200'), // Assuming an eventos endpoint exists
        apiGet(CONFIG.apiEndpoints.vehiculos)
      ]);
      State.eventos = (eventosRes || []).map((e, i) => ({ ...e, _id: Date.now() - i * 1000 }));
      State.fleet = normalizeFleet(fleetRes);
      this.updateKPIs();
    } catch (e) {
      // Fallback: generate sample events
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
    // Filters
    $('#searchInput')?.addEventListener('input', debounce(() => {
      State.filters.search = $('#searchInput').value.toLowerCase();
      this.renderEvents();
    }, 200));

    $('#severityFilter')?.addEventListener('change', e => {
      State.filters.severity = e.target.value;
      this.renderEvents();
    });

    $('#timeFilter')?.addEventListener('change', e => {
      State.filters.timeWindow = e.target.value;
      this.renderEvents();
    });

    $('#segmentFilter')?.addEventListener('change', e => {
      State.filters.segment = e.target.value;
      this.renderEvents();
    });

    $('#clearFilters')?.addEventListener('click', () => {
      $('#searchInput').value = '';
      $('#severityFilter').value = '';
      $('#timeFilter').value = '6h';
      $('#segmentFilter').value = '';
      State.filters = { search: '', severity: '', timeWindow: '6h', segment: '' };
      this.renderEvents();
    });

    $('#applyFilters')?.addEventListener('click', () => this.renderEvents());

    // Pause live
    $('#pauseLive')?.addEventListener('click', () => {
      State.paused = !State.paused;
      $('#pauseIcon').textContent = State.paused ? 'play_arrow' : 'pause';
      $('#pauseText').textContent = State.paused ? 'Reanudar' : 'Pausar';
      showToast(State.paused ? 'Actualización en vivo pausada' : 'Actualización en vivo reanudada', 'info');
    });

    // Export
    $('#exportBtn')?.addEventListener('click', () => this.exportIFR());

    // Refresh
    $('#refreshBtn')?.addEventListener('click', () => this.loadInitialData());

    // Load more
    $('#loadMoreBtn')?.addEventListener('click', () => this.loadMoreEvents());

    // Modals
    setupModal('eventModal', '#eventModalClose', null, '#eventModalCancel');
    setupModal('gpsModal', '#gpsModalClose', null, '#gpsModalOk');
    setupModal('reassignModal', '#reassignModalClose', null, '#reassignModalCancel');
  },

  startClock() {
    updateClock();
    setInterval(updateClock, 1000);
  },

  updateKPIs(resumen) {
    // MTTR
    const mttr = resumen?.mttr ?? (12 + Math.random() * 8);
    $('#kpiMttr').querySelector('.font-display').textContent = fmt.fixed(mttr, 1);

    // OTP
    const otp = resumen?.otp ?? (87 + Math.random() * 8);
    $('#kpiOtp').querySelector('.font-display').textContent = fmt.fixed(otp, 1);

    // Safety
    const safety = resumen?.safety_events ?? Math.floor(Math.random() * 5);
    $('#kpiSafety').querySelector('.font-display').textContent = safety;
  },

  renderEvents() {
    const list = $('#eventsList');
    if (!list) return;

    let filtered = State.eventos.filter(e => {
      if (State.filters.search) {
        const s = State.filters.search;
        if (!e.code.toLowerCase().includes(s) &&
            !e.unit.toLowerCase().includes(s) &&
            !e.awb.toLowerCase().includes(s) &&
            !e.message.toLowerCase().includes(s)) return false;
      }
      if (State.filters.severity && e.severity !== State.filters.severity) return false;
      if (State.filters.segment && e.segment !== State.filters.segment) return false;
      if (State.filters.timeWindow !== 'jornada' && State.filters.timeWindow !== 'custom') {
        const hours = parseInt(State.filters.timeWindow);
        const cutoff = Date.now() - hours * 3600000;
        if (new Date(e.timestamp).getTime() < cutoff) return false;
      }
      return true;
    });

    $('#eventsCount').textContent = `${filtered.length} eventos`;

    list.innerHTML = filtered.map(e => this.renderEventCard(e)).join('');

    // Click handlers for event cards
    $$('.event-card', list).forEach((card, i) => {
      const ev = filtered[i];
      card.querySelector('.action-btn.primary')?.addEventListener('click', e => {
        e.stopPropagation();
        this.openEventDetail(ev);
      });
      card.querySelector('.action-btn.secondary')?.addEventListener('click', e => {
        e.stopPropagation();
        if (ev.telemetry.lat) this.openGpsModal(ev);
        else this.openReassignModal(ev);
      });
    });

    // Show/hide load more
    $('#loadMoreContainer')?.classList.toggle('hidden', filtered.length < State.eventos.length);
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
      <article class="event-card ${cardClass}" data-id="${e._id}">
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

    $('#eventModalTitle').textContent = `${e.code} — ${info.label}`;
    $('#eventModalIcon').innerHTML = `<span class="material-symbols-outlined" style="color: ${severity.dot};">${e.severity === 'critica' ? 'error' : e.severity === 'alerta' ? 'warning' : 'check_circle'}</span>`;

    const time = new Date(e.timestamp);
    $('#eventModalBody').innerHTML = `
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
    $('#gpsModalTitle').textContent = `Posición GPS — ${e.unit} / ${e.awb}`;
    const t = e.telemetry;
    $('#gpsModalBody').innerHTML = `
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
    $('#reassignModalTitle').textContent = `Reasignación — ${e.code}`;
    $('#reassignModalBody').innerHTML = `
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

    filtered.forEach(e => {
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
    });

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
    // In a real app, this would fetch more from API
    showToast('No hay más eventos históricos disponibles', 'info');
  }
};

// ============================================
// INITIALIZATION
// ============================================

document.addEventListener('DOMContentLoaded', () => {
  Page.init();
});

// Handle visibility change to pause/resume SSE
document.addEventListener('visibilitychange', () => {
  if (document.hidden) {
    State.paused = true;
  } else if (State.paused && Page.current !== 'historial') {
    State.paused = false;
  }
});

// Cleanup on unload
window.addEventListener('beforeunload', () => {
  if (State.sse) { State.sse.close(); State.sse = null; }
  clearTimeout(State.sseReconnectTimer);
});

export { State, CONFIG, apiGet, apiPost, connectSSE, showToast, openModal, closeModal };