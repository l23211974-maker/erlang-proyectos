/* app.js — interfaz del gemelo digital #29
 *
 * Solo consulta /api/* y pinta. No calcula capacidad, ventanas, prioridades
 * ni veredictos: todo eso lo decide reglas.pl y llega ya resuelto.
 */

'use strict';

const $ = (sel) => document.querySelector(sel);
const SVGNS = 'http://www.w3.org/2000/svg';
let JORNADA = { inicio: 0, fin: 360 };
let ESTADO = null;

/* El modelo cuenta en minutos desde las 08:00 (jornada_inicio(0) en hechos.pl).
   Ese desfase es solo de presentación: las ventanas y los veredictos llegan
   ya calculados por reglas.pl en la misma escala. */
const HORA_ARRANQUE = 8 * 60;

/* ---------- utilidades de presentación ---------- */

function hhmm(minuto) {
  if (minuto === null || minuto === undefined) return '—';
  const total = HORA_ARRANQUE + JORNADA.inicio * 60 + minuto;
  const h = Math.floor(total / 60) % 24;
  const m = Math.round(total % 60);
  return String(h).padStart(2, '0') + ':' + String(m).padStart(2, '0');
}

function texto(valor) {
  if (valor === null || valor === undefined) return '—';
  if (typeof valor === 'object') {
    if (Array.isArray(valor)) return valor.map(texto).join(', ');
    return Object.entries(valor)
      .map(([k, v]) => k.replace(/_/g, ' ') + ': ' + texto(v))
      .join(' · ');
  }
  return String(valor).replace(/_/g, ' ');
}

function el(tag, clase, hijo) {
  const nodo = document.createElement(tag);
  if (clase) nodo.className = clase;
  if (hijo !== undefined && hijo !== null) nodo.append(hijo);
  return nodo;
}

function vacio(donde, mensaje) {
  donde.replaceChildren(el('p', 'vacio', mensaje));
}

async function api(ruta) {
  const res = await fetch('/api/' + ruta, { headers: { accept: 'application/json' } });
  if (!res.ok) throw new Error('api ' + ruta + ': ' + res.status);
  return res.json();
}

function insignia(estado) {
  const clase = estado === 'averiada' ? 'averiada'
    : estado === 'en_duda' ? 'en_duda'
    : estado === 'ok' ? 'ok' : 'neutra';
  return el('span', 'insignia ' + clase, texto(estado));
}

/* ---------- mapa ---------- */

function nodoSvg(tag, attrs) {
  const n = document.createElementNS(SVGNS, tag);
  for (const [k, v] of Object.entries(attrs)) n.setAttribute(k, v);
  return n;
}

function pintarMapa(estado) {
  const svg = $('#rutas');
  svg.replaceChildren();

  const xy = {};
  for (const p of estado.puntos) xy[p.id] = [p.x, 100 - p.y];

  // tramos base, tenues
  for (const t of estado.tramos) {
    const a = xy[t.origen], b = xy[t.destino];
    if (!a || !b) continue;
    svg.append(nodoSvg('line', {
      x1: a[0], y1: a[1], x2: b[0], y2: b[1],
      stroke: t.lento ? '#ef6a6a' : '#22384a',
      'stroke-width': t.lento ? 0.9 : 0.35,
      'stroke-dasharray': t.lento ? '2 1.4' : '',
    }));
  }

  // rutas pendientes de cada unidad
  for (const u of estado.unidades) {
    const puntos = [];
    if (u.posicion.punto && xy[u.posicion.punto]) puntos.push(xy[u.posicion.punto]);
    for (const parada of u.ruta) {
      if (xy[parada.punto]) puntos.push(xy[parada.punto]);
    }
    if (puntos.length < 2) continue;
    svg.append(nodoSvg('polyline', {
      points: puntos.map((p) => p.join(',')).join(' '),
      fill: 'none',
      stroke: u.estado === 'averiada' ? '#ef6a6a' : '#39d0c4',
      'stroke-width': 0.45,
      'stroke-opacity': 0.55,
    }));
  }

  // puntos del mapa con etiqueta
  for (const p of estado.puntos) {
    const [x, y] = xy[p.id];
    svg.append(nodoSvg('circle', { cx: x, cy: y, r: 0.8, fill: '#2c4254', stroke: '#4d6b83', 'stroke-width': 0.25 }));
    const t = nodoSvg('text', {
      x: x, y: y + 3, 'text-anchor': 'middle', 'font-size': 2.4,
      fill: '#8aa3b8', 'font-family': 'Segoe UI, sans-serif',
    });
    t.textContent = p.nombre;
    svg.append(t);
  }

  // unidades encima
  for (const u of estado.unidades) {
    const ref = u.posicion.punto || (u.ruta[0] && u.ruta[0].punto);
    if (!ref || !xy[ref]) continue;
    const [x, y] = xy[ref];
    const color = u.estado === 'averiada' ? '#ef6a6a'
      : u.estado === 'en_duda' ? '#f5b84c' : '#39d0c4';
    svg.append(nodoSvg('circle', { cx: x, cy: y, r: 1.7, fill: color, stroke: '#0a141c', 'stroke-width': 0.5 }));
    const t = nodoSvg('text', {
      x: x, y: y - 2.8, 'text-anchor': 'middle', 'font-size': 2.6,
      fill: '#dce7f1', 'font-weight': 700, 'font-family': 'Cascadia Mono, monospace',
    });
    t.textContent = u.id;
    svg.append(t);
  }
}

/* ---------- flota ---------- */

function barra(etiqueta, usado, capacidad, unidad) {
  const porcentaje = capacidad > 0 ? Math.min(100, (usado / capacidad) * 100) : 0;
  const clase = porcentaje >= 90 ? 'lleno' : porcentaje >= 60 ? 'alto' : '';
  const caja = el('div', 'barra');
  const fila = el('div', 'fila');
  fila.append(el('span', null, etiqueta), el('span', 'mono', usado + '/' + capacidad + ' ' + unidad));
  const carril = el('div', 'carril');
  const relleno = el('div', 'relleno ' + clase);
  relleno.style.width = porcentaje + '%';
  carril.append(relleno);
  caja.append(fila, carril);
  return caja;
}

function pintarFlota(estado) {
  const cont = $('#flota');
  cont.replaceChildren();
  $('#resumen-flota').textContent =
    estado.unidades.length + ' unidades · silencio > ' + estado.umbral_silencio + ' min';

  for (const u of estado.unidades) {
    const caja = el('article', 'unidad');
    const cab = el('header');
    const titulo = el('div');
    titulo.append(el('h3', null, u.id.toUpperCase()));
    titulo.append(el('p', 'quien', u.conductor));
    cab.append(titulo, insignia(u.estado));

    caja.append(cab);
    caja.append(barra('Peso', u.carga.peso, u.capacidad.peso, 'kg'));
    caja.append(barra('Volumen', u.carga.volumen, u.capacidad.volumen, 'u'));

    const meta = el('p', 'quien');
    meta.textContent = 'Posición ' + texto(u.posicion.punto) + ' (' + hhmm(u.posicion.minuto) +
      ') · al volante ' + u.manejado + ' min · quedan ' + u.horas_restantes + ' min';
    caja.append(meta);

    if (u.ruta.length) {
      const ruta = el('div', 'ruta');
      for (const parada of u.ruta) {
        const chip = el('span', 'parada');
        chip.append(el('b', null, parada.entrega), el('em', null, '→ ' + parada.punto + ' · ' + hhmm(parada.hasta)));
        ruta.append(chip);
      }
      caja.append(ruta);
    } else {
      caja.append(el('p', 'quien', 'Sin paradas pendientes.'));
    }
    cont.append(caja);
  }
}

/* ---------- entregas ---------- */

const NOMBRE_ESTADO = {
  pendiente: 'pendiente', en_ruta: 'en ruta', entregada: 'entregada', fallida: 'fallida',
};

function pintarEntregas(estado) {
  const cuerpo = $('#tabla-entregas tbody');
  cuerpo.replaceChildren();

  const nombres = {};
  for (const p of estado.puntos) nombres[p.id] = p.nombre;
  const cuenta = {};
  for (const e of estado.entregas) cuenta[e.estado] = (cuenta[e.estado] || 0) + 1;
  $('#resumen-entregas').textContent = estado.entregas.length + ' · ' +
    Object.entries(cuenta).map(([k, v]) => v + ' ' + texto(k)).join(' · ');

  for (const e of estado.entregas) {
    const tr = el('tr');
    const clase = e.estado === 'fallida' ? 'averiada'
      : e.estado === 'entregada' ? 'ok' : 'neutra';
    tr.append(el('td', 'mono', e.id));
    tr.append(el('td', null, nombres[e.punto] || texto(e.punto)));
    tr.append(el('td', 'mono', hhmm(e.desde) + '–' + hhmm(e.hasta)));
    const td = el('td');
    td.append(el('span', 'insignia ' + clase, NOMBRE_ESTADO[e.estado] || texto(e.estado)));
    tr.append(td);
    tr.append(el('td', 'mono', e.unidad || '—'));
    cuerpo.append(tr);
  }
}

/* ---------- situaciones ---------- */

function pintarSituaciones(estado) {
  const cont = $('#situaciones');
  cont.replaceChildren();
  if (!estado.situaciones.length) {
    cont.append(el('span', 'chip neutra', 'sin situaciones deducidas'));
    return;
  }
  for (const s of estado.situaciones) {
    const clase = s.tipo === 'averiada' || s.tipo === 'no_ubicable' ? 'chip rojo'
      : s.tipo === 'en_duda' || s.tipo === 'huerfana' || s.tipo === 'duplicada' ? 'chip ambar'
      : 'chip';
    const chip = el('span', clase);
    chip.append(el('b', null, texto(s.tipo)), document.createTextNode(' · ' + texto(s.entidad)));
    cont.append(chip);
  }
}

/* ---------- situación 1: plan ---------- */

function pintarPlan(datos) {
  const cont = $('#plan');
  cont.replaceChildren();

  if (!datos.planes.length) {
    const caja = el('div', 'tarjeta');
    caja.append(el('h3', null, 'No existe ningún reparto válido'));
    caja.append(el('p', null, 'El gemelo dice qué lo impide, no falla en silencio:'));
    caja.append(el('p', 'por-que', texto(datos.sin_plan)));
    cont.append(caja);
    return;
  }

  const elegido = datos.planes[0];
  const caja = el('div', 'tarjeta');
  caja.append(el('h3', null, 'Reparto propuesto'));
  const tabla = el('table');
  tabla.innerHTML = '<thead><tr><th>#</th><th>Entrega</th><th>Unidad</th></tr></thead>';
  const cuerpo = el('tbody');
  for (const a of elegido.asignaciones) {
    const tr = el('tr');
    tr.append(el('td', 'mono', a.orden), el('td', 'mono', a.entrega), el('td', 'mono', a.unidad));
    cuerpo.append(tr);
  }
  tabla.append(cuerpo);
  caja.append(tabla);
  cont.append(caja);

  const porQue = el('div', 'tarjeta');
  porQue.append(el('h3', null, 'Por qué a cada unidad'));
  const lista = el('ul', 'lista-pasos');
  for (const e of elegido.explicacion) {
    const li = el('li');
    li.append(el('b', null, e.entrega + ' → ' + e.unidad + ': '));
    li.append(el('span', 'por-que', texto(e.porque)));
    lista.append(li);
  }
  porQue.append(lista);
  cont.append(porQue);

  const extra = el('div', 'tarjeta');
  extra.append(el('h3', null, 'Alcance del cambio'));
  extra.append(el('p', null, 'A quién se le falla: a nadie. Las ' + datos.entregas.length +
    ' entregas quedan cubiertas exactamente una vez y el reparto respeta peso, volumen, ventanas y horas.'));
  extra.append(el('p', null, datos.planes.length + ' repartos válidos para estas ' +
    datos.entregas.length + ' entregas (se muestran todos si se piden).'));
  extra.append(el('p', null, datos.no_cambia.length
    ? 'Asignaciones que no hacía falta tocar: ' + datos.no_cambia.map((a) => a.entrega + '→' + a.unidad).join(', ')
    : 'No se tocó ninguna asignación ajena.'));
  cont.append(extra);
}

async function cargarPlan() {
  const campo = $('#entregas-plan').value.trim();
  const ruta = campo ? 'plan?entregas=' + encodeURIComponent(campo) : 'plan';
  try {
    pintarPlan(await api(ruta));
  } catch (e) {
    vacio($('#plan'), 'No se pudo consultar el plan: ' + e.message);
  }
}

/* ---------- situación 2: urgente ---------- */

function pintarUrgente(datos) {
  const cont = $('#urgente');
  cont.replaceChildren();
  if (!datos.pedido) { vacio(cont, 'Sin pedido urgente.'); return; }

  const pedido = el('div', 'tarjeta');
  pedido.append(el('h3', null, 'Pedido urgente ' + datos.pedido.id));
  pedido.append(el('p', null,
    'Punto ' + datos.pedido.punto + ' · ' + datos.pedido.peso + ' kg / ' +
    datos.pedido.volumen + ' u · ventana ' +
    hhmm(datos.pedido.desde) + '–' + hhmm(datos.pedido.hasta)));
  cont.append(pedido);

  if (datos.elegida) {
    const ev = datos.elegida.evaluacion;
    const caja = el('div', 'tarjeta');
    caja.append(el('h3', null, 'Se asigna a ' + datos.elegida.unidad));
    caja.append(el('p', null, 'Lugar en la ruta: ' + ev.posicion + ' · retraso total: ' +
      (ev.retrasos || []).reduce((s, r) => s + (r.minutos || r[1] || 0), 0) + ' min'));
    if (ev.rompe && ev.rompe !== 'ninguna') {
      caja.append(el('p', null, 'Rompe: ' + texto(ev.rompe)));
    } else {
      caja.append(el('p', null, 'No rompe ninguna ventana prometida.'));
    }
    cont.append(caja);
  } else {
    const caja = el('div', 'tarjeta');
    caja.append(el('h3', null, 'Ninguna unidad puede tomarlo sin romper una promesa'));
    caja.append(el('p', null, 'Se elige la menos mala y se dice a quién se le falla.'));
    cont.append(caja);
  }

  const tabla = el('table');
  tabla.innerHTML = '<thead><tr><th>Unidad</th><th>Pos.</th><th>Retrasos</th><th>Rompe</th></tr></thead>';
  const cuerpo = el('tbody');
  for (const c of datos.candidatas) {
    const tr = el('tr');
    const ev = c.evaluacion;
    tr.append(el('td', 'mono', c.unidad));
    if (ev && ev.posicion !== undefined) {
      const retrasos = (ev.retrasos || []).map((r) => {
        if (Array.isArray(r)) return r[0] + ' +' + r[1];
        return r.entrega + ' +' + r.minutos;
      }).join(', ') || 'ninguno';
      tr.append(el('td', 'mono', ev.posicion), el('td', null, retrasos),
        el('td', null, texto(ev.rompe)));
    } else {
      tr.append(el('td', null, '—'), el('td', null, texto(ev)), el('td', null, '—'));
    }
    cuerpo.append(tr);
  }
  tabla.append(cuerpo);
  cont.append(tabla);

  if (datos.que_falta && datos.que_falta.length) {
    const caja = el('div', 'tarjeta');
    caja.append(el('h3', null, 'Qué tendría que cambiar para no fallarle a nadie'));
    const chips = el('div', 'chips');
    for (const a of datos.que_falta) chips.append(el('span', 'chip', texto(a)));
    caja.append(chips);
    cont.append(caja);
  }
}

/* ---------- situación 3: silencio ---------- */

function pintarSilencio(datos) {
  const cont = $('#silencio');
  cont.replaceChildren();

  const cab = el('div', 'tarjeta');
  cab.append(el('h3', null, 'Unidad ' + datos.unidad));
  cab.append(el('p', null, datos.reporte
    ? 'Reporte en lote recibido en ' + hhmm(datos.reporte.minuto) + ': lo anterior a ese minuto se sabe; lo posterior, no.'
    : 'Sin reporte todavía: lo dudoso no se trata como hecho.'));
  cont.append(cab);

  if (!datos.en_duda) {
    cont.append(el('p', 'vacio',
      'Esta unidad no está ni estuvo en duda: no hay ninguna entrega que el gemelo deba dar por dudosa.'));
    return;
  }

  const tabla = el('table');
  tabla.innerHTML = '<thead><tr><th>Entrega</th><th>Veredicto</th><th>Evidencia</th></tr></thead>';
  const cuerpo = el('tbody');
  for (const v of datos.veredictos) {
    const tr = el('tr');
    const clase = v.veredicto === 'se_entrego' ? 'ok'
      : v.veredicto === 'no_se_entrego' ? 'averiada' : 'en_duda';
    tr.append(el('td', 'mono', v.entrega));
    const td = el('td');
    td.append(el('span', 'insignia ' + clase, texto(v.veredicto)));
    tr.append(td, el('td', 'por-que', texto(v.evidencia)));
    cuerpo.append(tr);
  }
  tabla.append(cuerpo);
  cont.append(tabla);

  if (datos.reasignadas.length || datos.huerfanas.length) {
    const caja = el('div', 'tarjeta');
    caja.append(el('h3', null, 'Consecuencias de una decisión ya tomada'));
    if (datos.reasignadas.length) {
      caja.append(el('p', null, 'Reasignadas durante el silencio: ' +
        datos.reasignadas.map((r) => r.entrega + ' ' + r.original + '→' + r.nueva + ' (' + hhmm(r.desde) + ')').join(', ')));
    }
    if (datos.huerfanas.length) {
      caja.append(el('p', null, 'Huérfanas ahora: ' + datos.huerfanas.map((h) => h.entrega).join(', ')));
    }
    cont.append(caja);
  }
}

async function cargarSilencio() {
  try {
    pintarSilencio(await api('silencio?unidad=' + encodeURIComponent($('#sel-silencio').value)));
  } catch (e) {
    vacio($('#silencio'), 'No se pudo consultar: ' + e.message);
  }
}

/* ---------- situación 4: llegadas ---------- */

function pintarLlegadas(datos) {
  const cont = $('#llegadas');
  cont.replaceChildren();
  if (datos.averiada) {
    cont.append(el('p', 'vacio',
      'Ojo: esta unidad está averiada. Sus paradas pendientes no van a ocurrir tal cual; los veredictos de abajo son la estimación sobre la ruta que tenía asignada.'));
  }
  if (!datos.llegadas.length) { vacio(cont, 'Sin paradas pendientes.'); return; }

  const tabla = el('table');
  tabla.innerHTML = '<thead><tr><th>Entrega</th><th>Llegada</th><th>Veredicto</th></tr></thead>';
  const cuerpo = el('tbody');
  for (const l of datos.llegadas) {
    const tr = el('tr');
    const clase = l.veredicto === 'en_ventana' ? 'ok'
      : l.veredicto === 'tarde' ? 'averiada' : 'en_duda';
    tr.append(el('td', 'mono', l.entrega),
      el('td', 'mono', hhmm(l.minimo) + '–' + hhmm(l.maximo)));
    const td = el('td');
    td.append(el('span', 'insignia ' + clase, texto(l.veredicto)));
    tr.append(td);
    cuerpo.append(tr);
  }
  tabla.append(cuerpo);
  cont.append(tabla);

  if (datos.horas) {
    const caja = el('div', 'tarjeta');
    caja.append(el('h3', null, 'Horas del conductor'));
    const clase = datos.horas.veredicto === 'si' ? 'ok'
      : datos.horas.veredicto === 'no' ? 'averiada' : 'en_duda';
    const p = el('p');
    p.append(el('span', 'insignia ' + clase, 'alcanza: ' + texto(datos.horas.veredicto)));
    caja.append(p, el('p', 'por-que', texto(datos.horas.evidencia)));
    cont.append(caja);
  }

  if (datos.tramos_lentos.length) {
    const caja = el('div', 'tarjeta');
    caja.append(el('h3', null, 'Tramo lento y rutas que toca'));
    for (const t of datos.tramos_lentos) {
      caja.append(el('p', null,
        t.tramo.origen + '–' + t.tramo.destino + ': ' + t.minutos + ' min · toca a ' +
        (t.unidades.length ? t.unidades.join(', ') : 'ninguna unidad')));
    }
    cont.append(caja);
  }
}

async function cargarLlegadas() {
  try {
    pintarLlegadas(await api('llegadas?unidad=' + encodeURIComponent($('#sel-llegadas').value)));
  } catch (e) {
    vacio($('#llegadas'), 'No se pudo consultar: ' + e.message);
  }
}

/* ---------- situación 5: fallidas ---------- */

function pintarFallidas(datos) {
  const cont = $('#fallidas');
  cont.replaceChildren();
  if (!datos.fallidas.length) { vacio(cont, 'Ninguna entrega fallida.'); return; }

  for (const f of datos.fallidas) {
    const caja = el('div', 'tarjeta');
    caja.append(el('h3', null, f.entrega + ' · ' + texto(f.motivo)));
    caja.append(el('p', null, 'Punto ' + texto(f.punto) + ' · ' + f.peso + ' kg / ' + f.volumen + ' u'));
    caja.append(el('p', null, 'Destino: ' + texto(f.destino)));
    if (f.impacto) {
      caja.append(el('p', null,
        'Capacidad de ' + f.impacto.unidad + ' si no se contara el paquete: ' +
        texto(f.impacto.sin_contar) + ' · contándolo: ' + texto(f.impacto.contando)));
    }
    caja.append(el('p', 'por-que', texto(f.evidencia)));
    cont.append(caja);
  }
}

/* ---------- qué falta ---------- */

async function pintarQueFalta() {
  const cont = $('#que-falta');
  cont.replaceChildren();
  for (const objetivo of ['urgente_sin_romper', 'plan_averia']) {
    try {
      const datos = await api('que_falta?objetivo=' + objetivo);
      const caja = el('div', 'tarjeta');
      caja.append(el('h3', null, texto(objetivo)));
      const chips = el('div', 'chips');
      for (const a of datos.alternativas) chips.append(el('span', 'chip', texto(a)));
      caja.append(chips);
      cont.append(caja);
    } catch (e) {
      cont.append(el('p', 'vacio', objetivo + ': ' + e.message));
    }
  }
}

/* ---------- arranque ---------- */

async function arrancar() {
  try {
    ESTADO = await api('estado');
  } catch (e) {
    vacio($('#flota'), 'El servidor del gemelo no responde: ' + e.message);
    return;
  }
  JORNADA = ESTADO.jornada;
  $('#ahora').textContent = hhmm(ESTADO.ahora);
  $('#jornada').textContent = hhmm(ESTADO.jornada.inicio) + '–' + hhmm(ESTADO.jornada.fin);

  pintarMapa(ESTADO);
  pintarFlota(ESTADO);
  pintarEntregas(ESTADO);
  pintarSituaciones(ESTADO);

  for (const id of ['#sel-silencio', '#sel-llegadas']) {
    const sel = $(id);
    sel.replaceChildren();
    for (const u of ESTADO.unidades) {
      const opcion = el('option', null, u.id + ' · ' + u.conductor);
      opcion.value = u.id;
      sel.append(opcion);
    }
  }
  $('#sel-silencio').value = ESTADO.unidades[1] ? ESTADO.unidades[1].id : ESTADO.unidades[0].id;
  $('#sel-llegadas').value = ESTADO.unidades[0].id;

  const leyenda = $('#leyenda');
  leyenda.replaceChildren();
  for (const [texto_, clase] of [['ruta pendiente', ''], ['tramo lento', 'lento']]) {
    const li = el('li');
    li.append(el('span', 'muestra ' + clase), document.createTextNode(texto_));
    leyenda.append(li);
  }

  await Promise.all([
    cargarPlan(),
    api('urgente').then(pintarUrgente).catch((e) => vacio($('#urgente'), e.message)),
    cargarSilencio(),
    cargarLlegadas(),
    api('fallidas').then(pintarFallidas).catch((e) => vacio($('#fallidas'), e.message)),
    pintarQueFalta(),
  ]);
}

$('#btn-plan').addEventListener('click', cargarPlan);
$('#entregas-plan').addEventListener('keydown', (ev) => { if (ev.key === 'Enter') cargarPlan(); });
$('#sel-silencio').addEventListener('change', cargarSilencio);
$('#sel-llegadas').addEventListener('change', cargarLlegadas);

arrancar();
