/* AeroCargo · hidratación de las pantallas Stitch con datos reales.
 *
 * Una sola hoja para las 5 páginas: el <body data-page="..."> decide qué
 * pintar. El SSE /eventos alimenta el dashboard a ~6 Hz (acumula el último
 * evento y pinta con temporizador); el resto de páginas refresca por API con
 * guarda anti-solapado, nunca por tick.
 */
(function () {
  'use strict';

  var page = document.body.getAttribute('data-page') || '';
  var $id = function (id) { return document.getElementById(id); };
  var $$ = function (sel, ctx) { return Array.prototype.slice.call((ctx || document).querySelectorAll(sel)); };

  var nf = new Intl.NumberFormat('es-CO');

  // Tipos de aeronave del dominio -> etiqueta comercial.
  var TIPO = {
    b767_300f: 'Boeing 767-300F',
    b737_800f: 'Boeing 737-800F',
    atr_72f: 'ATR-72-500F',
    b777_f: 'Boeing 777F',
    a330_200f: 'Airbus A330-200F'
  };

  var AEROPUERTOS = {
    MEX: [19.4363, -99.0721, 'MEX'], GDL: [20.5218, -103.3112, 'GDL (MMGL)'],
    MTY: [25.7785, -100.1069, 'MTY'], CUN: [21.0365, -86.8771, 'CUN'],
    SAL: [13.4409, -89.0557, 'SAL'], GUA: [14.5833, -90.5275, 'GUA'],
    PTY: [9.0714, -79.3836, 'PTY'], BOG: [4.7016, -74.1469, 'BOG / SKBO [HUB]'],
    CLO: [3.5431, -76.3816, 'CLO'], MDE: [6.1645, -75.4231, 'MDE'],
    UIO: [-0.1292, -78.3575, 'UIO'], LIM: [-12.0219, -77.1143, 'LIM'],
    SCL: [-33.3930, -70.7858, 'SCL'], EZE: [-34.8222, -58.5358, 'EZE'],
    MIA: [25.7959, -80.2870, 'MIA (KMIA)']
  };

  var state = {
    aeronaves: [],
    envios: [],
    resumen: null,
    tick: 0,
    cargando: false
  };

  // ---- utilidades ---------------------------------------------------------

  function esc(v) {
    return String(v == null ? '' : v).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }

  function num(v, def) {
    var n = Number(v);
    return isFinite(n) ? n : (def == null ? 0 : def);
  }

  function pad2(n) { return n < 10 ? '0' + n : String(n); }

  function kg(v) { return nf.format(Math.round(num(v))) + ' kg'; }

  function horaDeTick(tick) {
    if (tick == null) return '--:--';
    var seg = 8 * 3600 + num(tick) * 10;
    var h = Math.floor(seg / 3600) % 24;
    var m = Math.floor((seg % 3600) / 60);
    return pad2(h) + ':' + pad2(m);
  }

  function horaLocal(utc) {
    if (!/^\d\d:\d\d$/.test(utc || '')) return '--:-- LOCAL (GMT-5)';
    var p = utc.split(':');
    var h = (parseInt(p[0], 10) + 19) % 24; // UTC-5
    return pad2(h) + ':' + p[1] + ' LOCAL (GMT-5)';
  }

  function matricula(a) { return 'HK-' + (5100 + num(a.id)); }

  function vueloDe(a) { return a.vuelo || ('AC-' + (700 + num(a.id))); }

  function estadoInfo(estado) {
    switch (estado) {
      case 'en_ruta':
        return { key: 'ok', label: 'Nominal OK', badge: 'bg-secondary/15 text-secondary', dot: 'bg-secondary', tone: 'text-secondary' };
      case 'alerta_meteo':
        return { key: 'alert', label: 'Alerta meteo', badge: 'bg-tertiary-container/30 text-tertiary', dot: 'bg-tertiary animate-pulse', tone: 'text-tertiary' };
      case 'alerta_mecanica':
        return { key: 'alert', label: 'Alerta mecánica', badge: 'bg-tertiary-container/30 text-tertiary', dot: 'bg-tertiary animate-pulse', tone: 'text-tertiary' };
      case 'sin_senal':
        return { key: 'alert', label: 'Sin señal ADS-B', badge: 'bg-tertiary-container/30 text-tertiary', dot: 'bg-tertiary animate-pulse', tone: 'text-tertiary' };
      case 'desvio_critico':
        return { key: 'crit', label: 'Desvío crítico', badge: 'bg-error-container/40 text-error', dot: 'bg-error animate-ping', tone: 'text-error' };
      case 'mantenimiento':
        return { key: 'ground', label: 'Mantenimiento', badge: 'bg-surface-container-high text-on-surface-variant', dot: 'bg-outline', tone: 'text-on-surface-variant' };
      default:
        return { key: 'ground', label: 'En tierra', badge: 'bg-surface-container-high text-on-surface-variant', dot: 'bg-outline', tone: 'text-on-surface-variant' };
    }
  }

  function esTerrestre(a) { return estadoInfo(a.estado).key === 'ground'; }

  function buscarAeronave(id) {
    for (var i = 0; i < state.aeronaves.length; i++) {
      if (num(state.aeronaves[i].id) === num(id)) return state.aeronaves[i];
    }
    return null;
  }

  function enviosDe(aeronaveId) {
    return state.envios.filter(function (e) { return num(e.aeronave) === num(aeronaveId); });
  }

  function rutaDe(a) {
    var vivos = enviosDe(a.id).filter(function (e) { return e.estado === 'en_ruta'; });
    if (!vivos.length) vivos = enviosDe(a.id);
    if (!vivos.length) return null;
    var e = vivos[0];
    return {
      origen: e.origen_iata || 'BOG',
      destino: e.destino_iata || '---',
      eta: e.ventana_hasta || null,
      envio: e
    };
  }

  function fetchJSON(url) {
    return fetch(url, { headers: { accept: 'application/json' } })
      .then(function (r) { if (!r.ok) throw new Error('HTTP ' + r.status); return r.json(); });
  }

  function postJSON(url, cuerpo) {
    return fetch(url, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(cuerpo)
    }).then(function (r) { return r.json(); });
  }

  function totalEstado(estado) {
    var m = (state.resumen && state.resumen.envios) || {};
    if (m[estado] != null) return num(m[estado]);
    return state.envios.filter(function (e) { return e.estado === estado; }).length;
  }

  // ---- dashboard: KPIs, mapa y tabla --------------------------------------

  var filtro = { modo: 'all', q: '' };

  function pintarDashboard() {
    var aero = state.aeronaves || [];
    var enRuta = aero.filter(function (a) { return !esTerrestre(a); });
    var tierra = aero.filter(esTerrestre);
    var alertas = aero.filter(function (a) { return estadoInfo(a.estado).key === 'alert'; });
    var criticos = aero.filter(function (a) { return estadoInfo(a.estado).key === 'crit'; });
    var ok = aero.filter(function (a) { return estadoInfo(a.estado).key === 'ok'; });
    var entregadas = totalEstado('entregada');
    var retrasoMin = Math.round(num(state.resumen && state.resumen.retraso_medio) * 10 / 60);
    var cargaTotal = aero.reduce(function (s, a) { return s + num(a.carga_kg); }, 0);
    var totalUnidades = aero.length;
    var operatividad = totalUnidades ? (ok.length * 100 / totalUnidades).toFixed(1) : '0.0';
    var metaDiurna = 145;
    var restante = Math.max(0, metaDiurna - entregadas);
    var sli = totalUnidades ? (ok.length * 100 / totalUnidades).toFixed(1) : '0.0';

    if ($id('kpiEnRuta')) $id('kpiEnRuta').textContent = String(enRuta.length);
    if ($id('kpiEnRutaTrend')) $id('kpiEnRutaTrend').textContent = (enRuta.length > 0 ? '+' : '') + String(enRuta.length - 28) + ' vs 12:00Z';
    if ($id('kpiEnRutaBar')) $id('kpiEnRutaBar').style.width = totalUnidades ? Math.round(enRuta.length * 100 / totalUnidades) + '%' : '0%';
    if ($id('kpiAlertas')) $id('kpiAlertas').textContent = pad2(alertas.length);
    if ($id('kpiAlertasDetail')) $id('kpiAlertasDetail').textContent = alertas.length ? alertas[0].estado : 'Sin alertas';
    if ($id('kpiAlertasBar')) $id('kpiAlertasBar').style.width = totalUnidades ? Math.round(alertas.length * 100 / totalUnidades) + '%' : '0%';
    if ($id('kpiCriticos')) $id('kpiCriticos').textContent = pad2(criticos.length);
    if ($id('kpiCriticosDetail')) $id('kpiCriticosDetail').textContent = criticos.length ? 'SOP Activo' : 'Sin contingencias';
    if ($id('kpiCriticosBar')) $id('kpiCriticosBar').style.width = totalUnidades ? Math.round(criticos.length * 100 / totalUnidades) + '%' : '0%';
    if ($id('kpiCritico1')) $id('kpiCritico1').textContent = criticos[0] ? vueloDe(criticos[0]) + ': ' + estadoInfo(criticos[0].estado).label : '--';
    if ($id('kpiCritico2')) $id('kpiCritico2').textContent = criticos[1] ? vueloDe(criticos[1]) + ': ' + estadoInfo(criticos[1].estado).label : '--';
    if ($id('kpiEntregas')) $id('kpiEntregas').textContent = nf.format(entregadas);
    if ($id('kpiEntregasBar')) $id('kpiEntregasBar').style.width = metaDiurna ? Math.round(entregadas * 100 / metaDiurna) + '%' : '0%';
    if ($id('kpiSLI')) $id('kpiSLI').textContent = sli + '%';
    if ($id('kpiMeta')) $id('kpiMeta').textContent = String(metaDiurna);
    if ($id('kpiRestante')) $id('kpiRestante').textContent = String(restante);
    if ($id('kpiAereas')) $id('kpiAereas').textContent = String(enRuta.length);
    if ($id('kpiTierra')) $id('kpiTierra').textContent = String(tierra.length);
    if ($id('kpiRetraso')) $id('kpiRetraso').textContent = String(retrasoMin);
    if ($id('kpiHoldFuel')) $id('kpiHoldFuel').textContent = '140m'; // placeholder
    if ($id('kpiTonelaje')) $id('kpiTonelaje').textContent = (cargaTotal / 1000).toFixed(1) + ' Tons';

    if ($id('legendOk')) $id('legendOk').textContent = String(ok.length);
    if ($id('legendAlert')) $id('legendAlert').textContent = String(alertas.length);
    if ($id('legendCrit')) $id('legendCrit').textContent = String(criticos.length);

    pintarMapa(aero);
    pintarTabla();
  }

  function proyectar(lat, lon) {
    var latMin = -40, latMax = 40, lonMin = -110, lonMax = -55;
    var x = ((lon - lonMin) / (lonMax - lonMin)) * 100;
    var y = ((latMax - lat) / (latMax - latMin)) * 100;
    return {
      x: Math.max(3, Math.min(97, x)),
      y: Math.max(8, Math.min(92, y))
    };
  }

  function pintarMapa(aero) {
    var cont = $id('mapPins');
    if (!cont) return;

    // nodos de aeropuerto (una vez)
    if (!cont.getAttribute('data-hubs')) {
      var html = Object.keys(AEROPUERTOS).map(function (iata) {
        var w = AEROPUERTOS[iata];
        var p = proyectar(w[0], w[1]);
        var hub = iata === 'BOG';
        return '<div class="absolute flex flex-col items-center pointer-events-none" style="top:' + p.y.toFixed(2) + '%;left:' + p.x.toFixed(2) + '%">' +
          '<div class="' + (hub ? 'w-3.5 h-3.5 rounded-full bg-secondary ring-4 ring-secondary/25 flex items-center justify-center' : 'w-2 h-2 rounded-full bg-outline-variant') + '">' +
          (hub ? '<div class="w-1.5 h-1.5 rounded-full bg-on-secondary"></div>' : '') +
          '</div>' +
          '<span class="mt-0.5 font-label-badge text-label-badge ' + (hub ? 'text-secondary bg-surface-container-lowest/90 px-1.5 py-0.5 rounded shadow' : 'text-on-surface-variant bg-surface-container-lowest/70 px-1 rounded') + '">' + esc(w[2]) + '</span>' +
          '</div>';
      }).join('');
      cont.setAttribute('data-hubs', '1');
      cont.insertAdjacentHTML('beforeend', html);
    }

    var vivos = {};
    aero.forEach(function (a) {
      if (a.lat == null || a.lon == null) return;
      var p = proyectar(num(a.lat), num(a.lon));
      var info = estadoInfo(a.estado);
      var ruta = rutaDe(a);
      var id = 'pin-' + a.id;
      vivos[id] = true;
      var el = document.getElementById(id);
      var tooltip = el ? el.querySelector('.pin-tooltip') : null;
      if (!el) {
        el = document.createElement('div');
        el.id = id;
        el.className = 'absolute -translate-x-1/2 -translate-y-1/2 group cursor-pointer z-20 pointer-events-auto';
        cont.appendChild(el);
      }
      // Actualizar posición del pin (no toca el tooltip interno)
      el.style.left = p.x.toFixed(2) + '%';
      el.style.top = p.y.toFixed(2) + '%';
      el.className = 'absolute -translate-x-1/2 -translate-y-1/2 group cursor-pointer z-20 pointer-events-auto ' + info.tone;

      // Contenido del pin (icono) - solo crear si no existe
      var pinIcon = el.querySelector('.pin-icon');
      if (!pinIcon) {
        pinIcon = document.createElement('div');
        pinIcon.className = 'pin-icon w-8 h-8 rounded-full bg-surface-container-high/90 shadow-xl flex items-center justify-center transform group-hover:scale-110 transition-transform';
        pinIcon.innerHTML = '<span class="material-symbols-outlined text-[20px] -rotate-45" style="font-variation-settings:\'FILL\' 1;">flight</span>';
        el.appendChild(pinIcon);
      }
      pinIcon.className = 'pin-icon w-8 h-8 rounded-full bg-surface-container-high/90 shadow-xl flex items-center justify-center ' + info.tone + ' transform group-hover:scale-110 transition-transform';

      // Tooltip - crear si no existe, actualizar contenido y posición lateral
      if (!tooltip) {
        tooltip = document.createElement('div');
        tooltip.className = 'pin-tooltip hidden group-hover:block absolute left-10 -top-8 w-60 bg-surface-container-high/95 backdrop-blur-md p-space-sm rounded-lg shadow-xl z-30';
        el.appendChild(tooltip);
      }
      // Actualizar lado del tooltip según posición horizontal
      tooltip.className = 'pin-tooltip hidden group-hover:block absolute ' + (p.x > 65 ? 'right-10 left-auto' : 'left-10 -top-8') + ' w-60 bg-surface-container-high/95 backdrop-blur-md p-space-sm rounded-lg shadow-xl z-30';
      // Actualizar contenido del tooltip
      tooltip.innerHTML =
        '<div class="flex items-center justify-between border-b border-outline-variant/30 pb-1 mb-1">' +
        '<span class="font-label-code text-label-code text-on-surface font-bold">' + esc(vueloDe(a)) + ' · ' + esc(TIPO[a.tipo] || a.tipo) + '</span>' +
        '<span class="font-label-badge text-label-badge px-1 py-0.5 rounded ' + info.badge + '">' + esc(info.label) + '</span></div>' +
        '<div class="grid grid-cols-2 gap-1 text-[11px] font-telemetry-metric">' +
        '<div class="text-on-surface-variant">ALT: <span class="text-on-surface">' + (a.altitud_ft ? 'FL' + Math.round(num(a.altitud_ft) / 100) + ' (' + nf.format(num(a.altitud_ft)) + ' ft)' : '---') + '</span></div>' +
        '<div class="text-on-surface-variant">GS: <span class="text-on-surface">' + nf.format(num(a.velocidad_kts)) + ' kts</span></div>' +
        '<div class="text-on-surface-variant">ETA: <span class="' + info.tone + ' font-bold">' + esc(ruta && ruta.eta ? ruta.eta + ' UTC' : '---') + '</span></div>' +
        '<div class="text-on-surface-variant">CARGA: <span class="text-on-surface">' + (num(a.carga_kg) / 1000).toFixed(1) + ' T</span></div>' +
        '</div>' +
        '<div class="mt-1 flex items-center justify-between text-[10px] text-on-surface-variant pt-1 border-t border-outline-variant/20">' +
        '<span>Ruta: ' + esc(ruta ? ruta.origen + ' → ' + ruta.destino : 'sin asignar') + '</span>' +
        '<a class="text-primary hover:underline font-bold" href="unidad.html?id=' + encodeURIComponent(a.id) + '">Detalle →</a>' +
        '</div>';
    });

    $$('[id^="pin-"]', cont).forEach(function (el) {
      if (!vivos[el.id]) el.remove();
    });
  }

  function filaTabla(a) {
    var info = estadoInfo(a.estado);
    var ruta = rutaDe(a);
    var cap = num(a.capacidad_kg, 1) || 1;
    var pct = Math.max(0, Math.min(100, Math.round(num(a.carga_kg) / cap * 100)));
    var barra = info.key === 'crit' ? 'bg-error' : info.key === 'alert' ? 'bg-tertiary' : info.key === 'ground' ? 'bg-outline' : 'bg-secondary';
    var fl = a.altitud_ft ? 'FL' + Math.round(num(a.altitud_ft) / 100) : '---';
    var fondo = info.key === 'crit' ? 'bg-error-container/10 hover:bg-error-container/20' : 'hover:bg-surface-container/50';
    return '<tr class="' + fondo + ' transition-colors">' +
      '<td class="py-space-md px-space-md"><div class="flex items-center gap-space-sm">' +
      '<div class="w-8 h-8 rounded-lg ' + (info.key === 'crit' ? 'bg-error/20 text-error' : 'bg-surface-container text-primary') + ' flex items-center justify-center">' +
      '<span class="material-symbols-outlined text-[20px]" style="font-variation-settings:\'FILL\' 1;">flight</span></div>' +
      '<div><div class="font-label-code text-label-code ' + (info.key === 'crit' ? 'text-error' : 'text-on-surface') + ' font-bold">' + esc(vueloDe(a)) + ' · ' + esc(matricula(a)) + '</div>' +
      '<div class="font-label-sm text-label-sm text-on-surface-variant">' + esc(TIPO[a.tipo] || a.tipo) + '</div></div></div></td>' +
      '<td class="py-space-md px-space-md"><div class="flex items-center gap-1.5 font-label-code text-label-code">' +
      '<span class="text-on-surface font-bold">' + esc(ruta ? ruta.origen : '---') + '</span>' +
      '<span class="material-symbols-outlined text-[14px] ' + (info.key === 'crit' ? 'text-error' : 'text-outline') + '">arrow_forward</span>' +
      '<span class="' + (info.key === 'crit' ? 'text-error' : 'text-primary') + ' font-bold">' + esc(ruta ? ruta.destino : '---') + '</span></div>' +
      '<div class="font-label-sm text-label-sm text-on-surface-variant">' + (ruta && ruta.envio ? 'Envío #' + esc(ruta.envio.id) + ' · ' + esc(ruta.envio.tipo_carga || 'carga') : 'Sin carga viva') + '</div></td>' +
      '<td class="py-space-md px-space-md"><div class="font-label-code text-label-code text-on-surface">' + kg(a.carga_kg) + ' <span class="' + (pct > 80 ? 'text-tertiary' : 'text-secondary') + '">(' + pct + '%)</span></div>' +
      '<div class="w-24 bg-surface-container-highest h-1 rounded-full overflow-hidden mt-1"><div class="' + barra + ' h-full rounded-full" style="width:' + pct + '%"></div></div></td>' +
      '<td class="py-space-md px-space-md font-telemetry-metric text-on-surface-variant"><div>' + fl + (a.altitud_ft ? ' <span class="font-label-sm text-label-sm text-outline">(' + nf.format(num(a.altitud_ft)) + ' ft)</span>' : '') + '</div>' +
      '<div class="text-[12px] text-on-surface">' + nf.format(num(a.velocidad_kts)) + ' kts GS</div></td>' +
      '<td class="py-space-md px-space-md"><span class="inline-flex items-center gap-1.5 px-space-sm py-0.5 rounded-full ' + info.badge + ' font-label-badge text-label-badge uppercase">' +
      '<span class="w-1.5 h-1.5 rounded-full ' + info.dot + '"></span>' + esc(info.label) + '</span></td>' +
      '<td class="py-space-md px-space-md font-telemetry-metric"><div class="text-on-surface font-bold">' + (a.estado === 'en_ruta' || a.estado === 'alerta_meteo' || a.estado === 'alerta_mecanica' || a.estado === 'desvio_critico' ? esc(ruta && ruta.eta ? ruta.eta + ' UTC' : '---') : '---') + '</div>' +
      '<div class="font-label-sm text-label-sm ' + info.tone + '">' + (ruta && ruta.envio && num(ruta.envio.retraso) > 0 ? 'Retraso ' + Math.round(num(ruta.envio.retraso) * 10 / 60) + ' min' : info.label) + '</div></td>' +
      '<td class="py-space-md px-space-md text-right"><a class="px-space-md py-1 bg-surface-container-high hover:bg-primary hover:text-on-primary text-on-surface font-headline-sm text-headline-sm rounded-lg transition-colors inline-flex items-center gap-1 shadow-sm" href="unidad.html?id=' + encodeURIComponent(a.id) + '">' +
      '<span>Detalle</span><span class="material-symbols-outlined text-[16px]">chevron_right</span></a></td></tr>';
  }

  function pintarTabla() {
    var cuerpo = $id('fleetBody');
    if (!cuerpo) return;
    var q = filtro.q.trim().toLowerCase();
    var filas = state.aeronaves.filter(function (a) {
      if (filtro.modo === 'air' && esTerrestre(a)) return false;
      if (filtro.modo === 'ground' && !esTerrestre(a)) return false;
      if (!q) return true;
      var ruta = rutaDe(a);
      var texto = [vueloDe(a), matricula(a), TIPO[a.tipo] || a.tipo, ruta && ruta.origen, ruta && ruta.destino, estadoInfo(a.estado).label].join(' ').toLowerCase();
      return texto.indexOf(q) !== -1;
    });
    cuerpo.innerHTML = filas.map(filaTabla).join('') ||
      '<tr><td colspan="7" class="py-space-lg px-space-md text-center font-body-sm text-body-sm text-on-surface-variant">Sin unidades que coincidan con el filtro.</td></tr>';
    if ($id('fleetPager')) $id('fleetPager').textContent = 'Mostrando ' + filas.length + ' de ' + state.aeronaves.length + ' unidades';
  }

  function activarFiltroModo(boton) {
    ['filter-all', 'filter-air', 'filter-ground'].forEach(function (id) {
      var b = $id(id);
      if (!b) return;
      if (b === boton) {
        b.className = 'px-space-md py-1 rounded bg-surface-container-high text-primary font-label-badge text-label-badge uppercase shadow-sm';
      } else {
        b.className = 'px-space-md py-1 rounded text-on-surface-variant hover:text-on-surface font-label-badge text-label-badge uppercase transition-colors';
      }
    });
  }

  function iniciarDashboard() {
    var botones = { 'filter-all': 'all', 'filter-air': 'air', 'filter-ground': 'ground' };
    Object.keys(botones).forEach(function (id) {
      var b = $id(id);
      if (b) b.addEventListener('click', function () { filtro.modo = botones[id]; activarFiltroModo(b); pintarTabla(); });
    });
    var buscar = $id('fleetSearch');
    if (buscar) {
      var t = null;
      buscar.addEventListener('input', function () {
        clearTimeout(t);
        t = setTimeout(function () { filtro.q = buscar.value; pintarTabla(); }, 120);
      });
    }

    Promise.all([fetchJSON('/api/aeronaves'), fetchJSON('/api/envios')]).then(function (r) {
      state.aeronaves = r[0] || [];
      state.envios = r[1] || [];
      pintarDashboard();
    }).catch(function () { pintarDashboard(); });

    conectarSSE(function (p) {
      if (p.unidades) state.aeronaves = p.unidades;
      state.resumen = p;
      state.tick = num(p.tick);
      pintarDashboard();
    });

    // refresco lento de rutas/ETA (el SSE no trae la lista de envíos)
    setInterval(function () {
      if (document.hidden) return;
      fetchJSON('/api/envios').then(function (envios) { state.envios = envios || []; pintarDashboard(); }).catch(function () {});
    }, 20000);
  }

  // ---- cabecera: badges del header (maqueta trae cifras fijas) ------------

  function pintarCabecera(unidades) {
    if (!unidades) return;
    var enRuta = unidades.filter(function (a) { return !esTerrestre(a); });
    var alertas = unidades.filter(function (a) {
      var k = estadoInfo(a.estado).key;
      return k === 'alert' || k === 'crit';
    });
    var ok = unidades.filter(function (a) { return estadoInfo(a.estado).key === 'ok'; });
    var pct = unidades.length ? (ok.length * 100 / unidades.length).toFixed(1) : '0.0';

    if ($id('hdrUnidades')) $id('hdrUnidades').textContent = enRuta.length + ' Unidades Activas';
    if ($id('hdrAlertas')) $id('hdrAlertas').textContent = alertas.length + (alertas.length === 1 ? ' Alerta' : ' Alertas');
    if ($id('hdrOperatividad')) $id('hdrOperatividad').textContent = 'Operatividad ' + pct + '%';
  }

  // ---- SSE con coalescencia (máx. ~6 pintadas/s) --------------------------

  function conectarSSE(alRecibir) {
    if (!window.EventSource) return;
    var pendiente = null;
    var programado = false;

    function programar() {
      if (programado) return;
      programado = true;
      setTimeout(function () {
        programado = false;
        if (pendiente == null) return;
        var p = pendiente;
        pendiente = null;
        if (!document.hidden) { pintarCabecera(p.unidades); alRecibir(p); }
      }, 160);
    }

    var es = new EventSource('/eventos');
    es.addEventListener('estado', function (ev) {
      try {
        pendiente = JSON.parse(ev.data);
        programar();
      } catch (e) { /* evento corrupto: se ignora */ }
    });
  }

  // ---- bitácora y alertas -------------------------------------------------

  var bitacora = { sev: 'all', q: '' };

  function eventosDeEnvios(envios) {
    var cubos = { error: [], alert: [], ok: [] };
    envios.forEach(function (e) {
      var sev = null;
      if (e.estado === 'fallida') sev = 'error';
      else if (e.estado === 'desviada') sev = 'alert';
      else if (e.estado === 'entregada') sev = num(e.retraso) > 0 ? 'alert' : 'ok';
      if (!sev) return;
      cubos[sev].push({ e: e, sev: sev, tick: e.tick_entregado != null ? num(e.tick_entregado) : num(e.desde) });
    });
    // muestra equilibrada: la bitácora no debe ahogarse en 700 fallidas
    var out = [];
    ['error', 'alert', 'ok'].forEach(function (k) {
      cubos[k].sort(function (a, b) { return b.tick - a.tick; });
      out = out.concat(cubos[k].slice(0, 20));
    });
    out.sort(function (a, b) { return b.tick - a.tick; });
    return out;
  }

  var ESTILO_SEV = {
    error: { chip: 'bg-error/20 text-error', dot: 'bg-error animate-ping', borde: '0 0 0 1px #ef4444, 0 0 16px rgba(239,68,68,0.2)', titulo: 'FALLA CRÍTICA / AOG', tono: 'text-error', etiqueta: 'PRIORIDAD AOG-1' },
    alert: { chip: 'bg-tertiary/20 text-tertiary', dot: 'bg-tertiary', borde: '0 0 0 1px #f59e0b, 0 0 12px rgba(245,158,11,0.15)', titulo: 'ALERTA / DEMORA', tono: 'text-tertiary', etiqueta: 'RADAR WXR-ACTIVE' },
    ok: { chip: 'bg-secondary/20 text-secondary', dot: 'bg-secondary', borde: '0 0 0 1px #10b981, 0 0 10px rgba(16,185,129,0.12)', titulo: 'OPERACIÓN NOMINAL (OK)', tono: 'text-secondary', etiqueta: 'A TIEMPO' }
  };

  function tarjetaEvento(ev) {
    var e = ev.e;
    var s = ESTILO_SEV[ev.sev];
    var a = buscarAeronave(e.aeronave);
    var unidad = a ? (TIPO[a.tipo] || 'Unidad') + ' · ' + vueloDe(a) : 'SIN UNIDAD';
    var hora = horaDeTick(ev.tick);
    var retraso = num(e.retraso);
    var mensaje;
    if (ev.sev === 'error') {
      mensaje = 'Envío <span class="font-bold text-on-surface">#' + esc(e.id) + '</span> con ' + esc(e.tipo_carga || 'carga') +
        ' no pudo completarse en la ruta <span class="font-bold text-on-surface">' + esc(e.origen_iata) + ' → ' + esc(e.destino_iata) + '</span>' +
        (e.motivo ? ': <span class="text-error font-medium">' + esc(e.motivo) + '</span>' : '') +
        '. Requiere reasignación de ' + kg(e.peso_kg) + '.';
    } else if (e.estado === 'desviada') {
      mensaje = 'Envío <span class="font-bold text-on-surface">#' + esc(e.id) + '</span> desviado de la ruta ' +
        '<span class="font-bold text-on-surface">' + esc(e.origen_iata) + ' → ' + esc(e.destino_iata) + '</span> por contingencia operacional. Carga de ' + kg(e.peso_kg) + ' en curso.';
    } else if (retraso > 0) {
      mensaje = 'Envío <span class="font-bold text-on-surface">#' + esc(e.id) + '</span> entregado en <span class="font-bold text-on-surface">' + esc(e.destino_iata) +
        '</span> con <span class="font-bold text-tertiary">' + Math.round(retraso * 10 / 60) + ' min de retraso</span> respecto a la ventana comprometida.';
    } else {
      mensaje = 'Envío <span class="font-bold text-on-surface">#' + esc(e.id) + '</span> (' + esc(e.tipo_carga || 'carga') + ', ' + kg(e.peso_kg) +
        ') entregado a tiempo en <span class="font-bold text-on-surface">' + esc(e.destino_iata) + '</span>. Manifiesto cerrado sin novedad.';
    }
    var coords = a && a.lat != null ? (num(a.lat).toFixed(2) + ' / ' + num(a.lon).toFixed(2)) : '---';
    var unitCode = a ? vueloDe(a) : 'N/D';

    return '<article class="event-card group relative bg-surface-container rounded-xl p-space-md shadow-xl transition-all duration-200 hover:bg-surface-container-high" data-severity="' + ev.sev + '" style="box-shadow:' + s.borde + ';">' +
      '<div class="flex flex-col md:flex-row md:items-start justify-between gap-space-sm pb-space-sm border-b border-surface-container-highest">' +
      '<div class="flex items-center gap-space-sm flex-wrap">' +
      '<span class="px-2.5 py-1 rounded ' + s.chip + ' font-label-badge text-label-badge flex items-center gap-1.5 uppercase font-bold"><span class="w-2 h-2 rounded-full ' + s.dot + '"></span>' + s.titulo + '</span>' +
      '<span class="font-label-code text-label-code text-on-surface font-bold bg-surface-container-lowest px-2 py-1 rounded">' + esc(unidad) + '</span>' +
      '<span class="font-label-code text-label-code text-outline">AWB: ' + esc(e.id) + '</span>' +
      '<span class="px-2 py-0.5 rounded bg-surface-container-high font-label-sm text-label-sm ' + s.tono + '">' + s.etiqueta + '</span></div>' +
      '<div class="flex md:flex-col items-center md:items-end justify-between gap-1 text-right">' +
      '<div class="font-telemetry-metric text-telemetry-metric ' + s.tono + ' tracking-tight">' + esc(hora) + ' <span class="text-sm font-normal text-on-surface-variant">UTC</span></div>' +
      '<div class="font-label-sm text-label-sm text-on-surface-variant">' + esc(horaLocal(hora)) + '</div></div></div>' +
      '<div class="py-space-md space-y-space-sm"><p class="font-body-lg text-body-lg text-on-surface leading-relaxed">' + mensaje + '</p>' +
      '<div class="flex flex-wrap items-center gap-space-xs pt-1">' +
      '<span class="bg-surface-container-lowest px-2.5 py-1 rounded font-label-code text-label-code text-on-surface-variant flex items-center gap-1"><span class="material-symbols-outlined text-[14px] ' + s.tono + '">inventory_2</span>' + kg(e.peso_kg) + '</span>' +
      '<span class="bg-surface-container-lowest px-2.5 py-1 rounded font-label-code text-label-code text-on-surface-variant flex items-center gap-1"><span class="material-symbols-outlined text-[14px] text-primary">flight_land</span>Ruta: ' + esc(e.origen_iata) + ' → ' + esc(e.destino_iata) + '</span>' +
      '<span class="bg-surface-container-lowest px-2.5 py-1 rounded font-label-code text-label-code text-tertiary flex items-center gap-1"><span class="material-symbols-outlined text-[14px]">schedule</span>' + (retraso > 0 ? 'Impacto: +' + Math.round(retraso * 10 / 60) + ' min' : 'Ventana: ' + esc(e.ventana_desde || '--:--') + '–' + esc(e.ventana_hasta || '--:--')) + '</span>' +
      '</div></div>' +
      '<div class="pt-space-sm flex flex-wrap items-center justify-between gap-space-sm"><div class="flex flex-wrap items-center gap-space-xs">' +
      '<button class="action-btn px-space-sm py-1.5 rounded-lg bg-surface-container-high hover:bg-surface-bright text-on-surface font-label-sm text-label-sm flex items-center gap-1.5 transition-colors" data-pdf="1"><span class="material-symbols-outlined text-[16px] text-primary">picture_as_pdf</span><span>Descargar reporte PDF/Telemetría</span></button>' +
      '<button class="action-btn px-space-sm py-1.5 rounded-lg bg-surface-container-high hover:bg-surface-bright text-on-surface font-label-sm text-label-sm flex items-center gap-1.5 transition-colors" data-modal="gps" data-unit="' + esc(unitCode) + '" data-coords="' + esc(coords) + '"><span class="material-symbols-outlined text-[16px] text-secondary">explore</span><span>Ver traza GPS</span></button></div>' +
      '<button class="action-btn px-space-md py-1.5 rounded-lg ' + (ev.sev === 'error' ? 'bg-error hover:bg-error-container text-white' : 'bg-surface-container-high hover:bg-surface-bright ' + s.tono) + ' font-label-badge text-label-badge uppercase flex items-center gap-1.5 transition-colors shadow-sm" data-modal="reassign" data-unit="' + esc(unitCode) + '"><span class="material-symbols-outlined text-[16px]">swap_horiz</span><span>Inspeccionar Reasignación</span></button></div></article>';
  }

  function pintarBitacora() {
    var cont = $id('events-container');
    if (!cont) return;
    var eventos = eventosDeEnvios(state.envios);
    var cuenta = { all: eventos.length, ok: 0, alert: 0, error: 0 };
    eventos.forEach(function (ev) { cuenta[ev.sev]++; });

    cont.innerHTML = eventos.map(tarjetaEvento).join('') ||
      '<div class="bg-surface-container rounded-xl p-space-lg text-center font-body-sm text-body-sm text-on-surface-variant">Aún no hay eventos terminales en la jornada.</div>';

    if ($id('countAll')) $id('countAll').textContent = String(cuenta.all);
    if ($id('countOk')) $id('countOk').textContent = String(cuenta.ok);
    if ($id('countAlert')) $id('countAlert').textContent = String(cuenta.alert);
    if ($id('countError')) $id('countError').textContent = String(cuenta.error);

    aplicarFiltroBitacora();
  }

  function aplicarFiltroBitacora() {
    var cont = $id('events-container');
    if (!cont) return;
    var q = bitacora.q.trim().toLowerCase();
    var visibles = 0;
    $$('.event-card', cont).forEach(function (card) {
      var sev = card.getAttribute('data-severity');
      var ok = (bitacora.sev === 'all' || sev === bitacora.sev) && (!q || card.textContent.toLowerCase().indexOf(q) !== -1);
      card.classList.toggle('hidden', !ok);
      if (ok) visibles++;
    });
    var sin = $id('no-results');
    if (sin) sin.classList.toggle('hidden', visibles !== 0);
  }

  function mostrarToast(msg) {
    var toast = $id('toast');
    var texto = $id('toast-message');
    if (!toast || !texto) return;
    texto.textContent = msg;
    toast.classList.remove('translate-y-24', 'opacity-0');
    toast.classList.add('translate-y-0', 'opacity-100');
    setTimeout(function () {
      toast.classList.add('translate-y-24', 'opacity-0');
      toast.classList.remove('translate-y-0', 'opacity-100');
    }, 3200);
  }

  function iniciarBitacora() {
    var buscar = $id('input-search');
    if (buscar) {
      buscar.addEventListener('input', function () { bitacora.q = buscar.value; aplicarFiltroBitacora(); });
    }

    $$('.filter-status-btn').forEach(function (btn) {
      btn.addEventListener('click', function () {
        $$('.filter-status-btn').forEach(function (b) {
          b.classList.remove('active', 'bg-surface-container-high', 'text-primary');
          b.classList.add('bg-surface-container-lowest');
        });
        btn.classList.add('active', 'bg-surface-container-high', 'text-primary');
        btn.classList.remove('bg-surface-container-lowest');
        bitacora.sev = btn.getAttribute('data-filter-status') || 'all';
        aplicarFiltroBitacora();
      });
    });

    var reset = $id('btn-reset-filters');
    if (reset) {
      reset.addEventListener('click', function () {
        if (buscar) buscar.value = '';
        bitacora.q = '';
        bitacora.sev = 'all';
        $$('.filter-status-btn').forEach(function (b, i) {
          if (i === 0) {
            b.classList.add('active', 'bg-surface-container-high', 'text-primary');
            b.classList.remove('bg-surface-container-lowest');
          } else {
            b.classList.remove('active', 'bg-surface-container-high', 'text-primary');
            b.classList.add('bg-surface-container-lowest');
          }
        });
        aplicarFiltroBitacora();
        mostrarToast('Filtros restablecidos a la vista predeterminada');
      });
    }

    $$('.range-btn').forEach(function (btn) {
      btn.addEventListener('click', function () {
        $$('.range-btn').forEach(function (b) {
          b.classList.remove('bg-surface', 'text-primary', 'shadow-sm');
          b.classList.add('text-on-surface-variant');
        });
        btn.classList.add('bg-surface', 'text-primary', 'shadow-sm');
        btn.classList.remove('text-on-surface-variant');
        mostrarToast('Ventana temporal actualizada: ' + btn.textContent.trim());
      });
    });

    // modales + acciones delegadas
    document.addEventListener('click', function (e) {
      var gps = e.target.closest('[data-modal="gps"]');
      if (gps) {
        if ($id('gps-modal-unit')) $id('gps-modal-unit').textContent = 'UNIDAD AUDITADA: ' + gps.getAttribute('data-unit');
        if ($id('gps-modal-coords')) $id('gps-modal-coords').textContent = 'POSICIÓN RADAR: ' + gps.getAttribute('data-coords');
        abrirModal('gps-modal');
        return;
      }
      var reas = e.target.closest('[data-modal="reassign"]');
      if (reas) {
        if ($id('reassign-modal-unit')) $id('reassign-modal-unit').textContent = reas.getAttribute('data-unit');
        abrirModal('reassign-modal');
        return;
      }
      if (e.target.closest('[data-pdf]')) {
        mostrarToast('Generando telemetría oficial y reporte PDF IFR...');
      }
    });

    [['close-gps-modal', 'gps-modal'], ['close-reassign-modal', 'reassign-modal'], ['cancel-reassign', 'reassign-modal']].forEach(function (par) {
      var b = $id(par[0]);
      if (b) b.addEventListener('click', function () { cerrarModal(par[1]); });
    });

    var confirmar = $id('confirm-reassign');
    if (confirmar) {
      confirmar.addEventListener('click', function () {
        cerrarModal('reassign-modal');
        mostrarToast('Orden de transbordo transmitida exitosamente a Centro de Despacho.');
      });
    }

    var exportar = $id('btn-export-log');
    if (exportar) {
      exportar.addEventListener('click', function () {
        mostrarToast('Descargando archivo consolidado de eventos en formato seguro (CSV/PDF)...');
      });
    }

    function tickReloj() {
      if ($id('syncTime')) {
        var d = new Date();
        $id('syncTime').textContent = pad2(d.getUTCHours()) + ':' + pad2(d.getUTCMinutes()) + ':' + pad2(d.getUTCSeconds()) + ' UTC';
      }
    }
    tickReloj();
    setInterval(tickReloj, 1000);

    cargarBitacora();
    setInterval(function () {
      if (document.hidden) return;
      cargarBitacora();
    }, 5000);
  }

  function abrirModal(id) {
    var m = $id(id);
    if (!m) return;
    m.classList.remove('hidden');
    m.classList.add('flex');
  }

  function cerrarModal(id) {
    var m = $id(id);
    if (!m) return;
    m.classList.add('hidden');
    m.classList.remove('flex');
  }

  function cargarBitacora() {
    if (state.cargando) return;
    state.cargando = true;
    fetchJSON('/api/envios').then(function (envios) {
      state.envios = envios || [];
    }).catch(function () {}).then(function () {
      state.cargando = false;
      pintarBitacora();
    });
  }

  // ---- detalle de unidad --------------------------------------------------

  function idDeQuery() {
    var m = /[?&]id=([^&]+)/.exec(window.location.search);
    return m ? decodeURIComponent(m[1]) : null;
  }

  function setTexto(id, valor) {
    var el = $id(id);
    if (el) el.textContent = valor;
  }

  function reemplazarPorTexto(patron, valor) {
    var nodos = $$('span, div');
    for (var i = 0; i < nodos.length; i++) {
      var t = (nodos[i].textContent || '').trim();
      if (patron.test(t) && nodos[i].children.length === 0) {
        nodos[i].textContent = valor;
        return true;
      }
    }
    return false;
  }

  function pintarManifiesto(a) {
    var cont = $id('manifestList');
    if (!cont) return;
    var envios = enviosDe(a.id).filter(function (e) { return e.estado === 'en_ruta' || e.estado === 'pendiente'; }).slice(0, 5);
    if (!envios.length) {
      cont.innerHTML = '<div class="p-space-sm bg-surface-container rounded-lg font-body-sm text-body-sm text-on-surface-variant">Sin carga viva asignada a esta unidad.</div>';
      return;
    }
    cont.innerHTML = envios.map(function (e) {
      var frio = /refrig|frio|frío|medic|vacun/i.test(e.tipo_carga || '');
      var chip = frio
        ? '<span class="px-1.5 py-0.5 bg-error-container text-on-error-container font-label-badge text-label-badge rounded uppercase flex items-center gap-1"><span class="material-symbols-outlined text-[12px]">ac_unit</span>Urgente - Frío</span>'
        : '<span class="px-1.5 py-0.5 bg-surface-container-highest text-on-surface font-label-badge text-label-badge rounded uppercase">' + (e.urgente ? 'AOG / Crítico' : 'Carga regular') + '</span>';
      return '<div class="p-space-sm bg-surface-container rounded-lg shadow-sm space-y-space-xs hover:bg-surface-container-high transition-colors">' +
        '<div class="flex items-start justify-between gap-space-xs"><div>' +
        '<div class="flex items-center gap-space-xs"><span class="font-label-code text-label-code text-primary font-bold">PKG-' + esc(e.id) + '</span>' + chip + '</div>' +
        '<span class="font-body-md text-body-md text-on-surface font-medium block mt-0.5">' + esc(e.tipo_carga || 'Carga general') + ' · Envío #' + esc(e.id) + '</span></div>' +
        '<div class="text-right shrink-0"><span class="font-label-badge text-label-badge text-tertiary block">Ventana ' + esc(e.ventana_hasta || '--:--') + '</span>' +
        '<span class="font-label-sm text-label-sm text-outline">' + kg(e.peso_kg) + '</span></div></div>' +
        '<div class="flex items-center justify-between pt-1 font-body-sm text-body-sm text-on-surface-variant">' +
        '<span class="flex items-center gap-1"><span class="material-symbols-outlined text-[14px] text-outline">flight_land</span> Destino: <strong class="text-on-surface">' + esc(e.destino_iata) + '</strong></span>' +
        '<span class="font-label-badge text-label-badge text-secondary">' + esc(estadoInfo(e.estado).label) + '</span></div></div>';
    }).join('');

    var etiqueta = $$('span').filter(function (s) { return /Envíos Primarios$/.test((s.textContent || '').trim()); })[0];
    if (etiqueta) etiqueta.textContent = envios.length + ' Envíos Primarios';
  }

  function hidratarUnidad(a) {
    var ruta = rutaDe(a);
    setTexto('unitTipo', TIPO[a.tipo] || a.tipo || 'Unidad');
    setTexto('unitMatricula', matricula(a));
    setTexto('unitBreadcrumb', vueloDe(a) + ' (' + matricula(a) + ')');
    setTexto('unitRuta', ruta ? ruta.origen + ' → ' + ruta.destino : 'sin ruta asignada');
    setTexto('unitEta', ruta && ruta.eta ? ruta.eta + ' UTC' : '---');
    setTexto('unitFuel', Math.round(num(a.combustible_pct, 0)) + '%');
    setTexto('unitFuelSub', Math.round(num(a.combustible_pct, 0) / 100 * 5) + 'h de autonomía estimada');
    setTexto('unitFl', a.altitud_ft ? 'FL' + Math.round(num(a.altitud_ft) / 100) : '---');
    setTexto('unitFlSub', a.altitud_ft ? nf.format(num(a.altitud_ft)) + ' ft AMSL' : 'sin telemetría');
    setTexto('unitSpeed', nf.format(num(a.velocidad_kts)) + ' kts');
    setTexto('unitSpeedSub', nf.format(num(a.velocidad_kts)) + ' kts GS');
    setTexto('unitLoad', (num(a.carga_kg) / 1000).toFixed(1) + ' t');
    var pct = Math.max(0, Math.min(100, Math.round(num(a.carga_kg) / (num(a.capacidad_kg, 1) || 1) * 100)));
    if ($id('unitFuelBar')) $id('unitFuelBar').style.width = Math.round(num(a.combustible_pct, 0)) + '%';
    if ($id('unitLoadBar')) $id('unitLoadBar').style.width = pct + '%';
    var info = estadoInfo(a.estado);
    reemplazarPorTexto(/^ALERTA: .+$/, 'ESTADO: ' + info.label.toUpperCase());
    pintarManifiesto(a);
  }

  function iniciarUnidad() {
    cargarUnidad();
    setInterval(function () { if (!document.hidden) cargarUnidad(); }, 5000);

    // Reasignación real: usa la API de caos del despachador y luego reproduce
    // la confirmación visual de la maqueta.
    var confirmacionMock = window.triggerReassignment;
    window.triggerReassignment = function () {
      var btn = $id('btnSubmitReassignment');
      if (btn) { btn.disabled = true; btn.classList.add('opacity-75'); }
      var a = buscarAeronave(idDeQuery());
      var accion = a ? postJSON('/api/averiar', { aeronave: num(a.id) }) : Promise.resolve();
      accion.catch(function () {}).then(function () {
        if (btn) { btn.disabled = false; btn.classList.remove('opacity-75'); }
        if (typeof confirmacionMock === 'function') confirmacionMock();
      });
    };
  }

  function cargarUnidad() {
    if (state.cargando) return;
    state.cargando = true;
    Promise.all([fetchJSON('/api/aeronaves'), fetchJSON('/api/envios')]).then(function (r) {
      state.aeronaves = r[0] || [];
      state.envios = r[1] || [];
      var a = buscarAeronave(idDeQuery()) || state.aeronaves[0];
      if (a) hidratarUnidad(a);
    }).catch(function () {}).then(function () { state.cargando = false; });
  }

  function iniciarUnidadEnfocada() {
    var confirmacionMock = window.confirmDispatch;
    cargarEnfocada();
    setInterval(function () { if (!document.hidden) cargarEnfocada(); }, 5000);

    window.confirmDispatch = function () {
      var btn = $id('btnConfirm');
      var texto = $id('btnText');
      if (btn) { btn.disabled = true; btn.classList.add('opacity-70'); }
      if (texto) texto.textContent = 'Transmitiendo por ACARS...';
      var a = buscarAeronave(idDeQuery());
      var accion = a ? postJSON('/api/averiar', { aeronave: num(a.id) }) : Promise.resolve();
      accion.catch(function () {}).then(function () {
        if (btn) { btn.disabled = false; btn.classList.remove('opacity-70'); }
        if (typeof confirmacionMock === 'function') confirmacionMock();
      });
    };
  }

  function cargarEnfocada() {
    if (state.cargando) return;
    state.cargando = true;
    Promise.all([fetchJSON('/api/aeronaves'), fetchJSON('/api/envios')]).then(function (r) {
      state.aeronaves = r[0] || [];
      state.envios = r[1] || [];
      var a = buscarAeronave(idDeQuery()) || state.aeronaves[0];
      if (!a) return;
      var ruta = rutaDe(a);
      setTexto('unitVuelo', vueloDe(a));
      setTexto('unitTipo', matricula(a) + ' · ' + (TIPO[a.tipo] || a.tipo));
      setTexto('headerEta', ruta && ruta.eta ? ruta.eta : '--:--');
      setTexto('touchdownTime', ruta && ruta.eta ? ruta.eta + ' Z' : '--:-- Z');
      var info = estadoInfo(a.estado);
      reemplazarPorTexto(/^ALERTA: .+$/, 'ESTADO: ' + info.label.toUpperCase());
    }).catch(function () {}).then(function () { state.cargando = false; });
  }

  // ---- arranque -----------------------------------------------------------

  if (page === 'monitoreo-en-vivo') iniciarDashboard();
  else if (page === 'bitacora-y-alertas') iniciarBitacora();
  else if (page === 'detalle-de-unidad-y-reasignacion') iniciarUnidad();
  else if (page === 'detalle-enfocado') iniciarUnidadEnfocada();
})();
