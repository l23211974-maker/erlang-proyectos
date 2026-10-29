/* Flotilla #29 — cliente de la API. Plano (sin frameworks): fetch para el
   estado inicial y SSE (/eventos) para el estado en vivo. Cada página declara
   su tipo en <body data-page="..."> y este módulo pinta lo que le corresponde.
   Las clases/IDs replica las maquetas de Stitch (design/Plantilla Flotilla de
   Reparto/); los datos vienen de /api/* y del evento "estado" del broadcaster. */

"use strict";

/* ---- utilerias ---- */
const $ = (id) => document.getElementById(id);
const pad = (n) => String(n).padStart(2, "0");
const horaDeTick = (tick) => {
  if (tick === null || tick === undefined || tick === "") return "--:--";
  const seg = 8 * 3600 + tick * 10;         // 08:00 simulada, 10 s de GPS/tick
  const h = Math.floor(seg / 3600) % 24, m = Math.floor((seg % 3600) / 60);
  return String(h).padStart(2, "0") + ":" + String(m).padStart(2, "0");
};
const suma = (obj) => Object.values(obj || {}).reduce((a, b) => a + b, 0);
const en = (obj, clave) => (obj || {})[clave] || 0;

const PILL = { en_ruta: "ok", entregada: "ok", pendiente: "off", averiado: "crit",
               sin_senal: "warn", fallida: "crit" };
const pill = (estado) => {
  const clase = PILL[estado] || "off";
  return `<span class="pill ${clase}"><span class="dot ${clase}"></span>${estado.replaceAll("_", " ")}</span>`;
};
const filaEntrega = (e) => `
  <tr>
    <td class="id">ENV-#${e.id}${e.urgente ? " ⚠" : ""}</td>
    <td>${e.colonia}</td>
    <td>${e.peso} kg</td>
    <td>${e.ventana_desde}–${e.ventana_hasta}</td>
    <td>${pill(e.estado)}</td>
    <td>${e.retraso > 0 ? "+" + e.retraso : "0"}</td>
  </tr>`;
const filaVacia = (cols, texto) =>
  `<tr><td colspan="${cols}" class="tabla-vacia">${texto}</td></tr>`;
const pctTxt = (x, total) => total ? `${Math.round(100 * x / total)}%` : "0%";

/* estado global de la jornada para las páginas */
const g = { resumen: null, unidades: [], entregas: [] };

/* estado del semaforo: normal / alerta / critico (para filtros y colores) */
const severidadDe = (estado) =>
  estado === "averiado" ? "critico" : estado === "sin_senal" ? "alerta" : "normal";

/* ---- pintar resumen (todas las páginas con datos de jornada) ---- */
const pintarResumen = (r) => {
  g.resumen = r;
  if (!$("tick-hora")) return;
  $("tick-hora").textContent = horaDeTick(r.tick);
  if ($("tick-hora2")) $("tick-hora2").textContent = horaDeTick(r.tick);
  if ($("dato-reasignaciones")) $("dato-reasignaciones").textContent = r.reasignaciones;
  if ($("dato-retraso")) {
    const min = (r.retraso_medio / 6).toFixed(0);
    $("dato-retraso").textContent = `+${min} min`;
  }
  const inv = r.invariantes;
  if (inv && $("badge-invariantes") && inv !== $("badge-invariantes").dataset.valor) {
    $("badge-invariantes").outerHTML =
      `<span id="badge-invariantes" class="pill ${inv === "ok" ? "ok" : "crit"}"
        data-valor="${inv}"><span class="dot ${inv === "ok" ? "ok" : "crit"}"></span>
        invariantes ${inv}</span>`;
  }
};

/* ---- KPIs del control (index) ---- */
const pintarKpis = (r, unidades) => {
  if (!$("kf-valor")) return;
  const e = r.entregas || {}, v = r.vehiculos || {};
  const vivas = unidades.filter((u) => u.estado === "en_ruta").length;
  const alertadas = unidades.filter((u) => u.estado === "sin_senal").length;
  const criticas = unidades.filter((u) => u.estado === "averiado").length;
  const total = suma(e);
  $("kf-valor").textContent = `${vivas} / ${unidades.length}`;
  $("kf-sub").textContent = "unidades";
  $("kf-enruta").textContent = en(e, "en_ruta");
  $("kf-entregadas").textContent = en(e, "entregada");
  $("kf-barra").style.width = pctTxt(vivas, unidades.length);

  $("ke-valor").textContent = en(e, "en_ruta");
  $("ke-pct").textContent = pctTxt(en(e, "en_ruta"), en(e, "en_ruta") + en(e, "pendiente"));
  $("ke-sub").textContent = `${en(e, "pendiente")} en cola`;
  $("ke-barra").style.width = pctTxt(en(e, "en_ruta"), en(e, "en_ruta") + en(e, "pendiente"));

  $("ka-valor").textContent = alertadas;
  $("ka-pct").textContent = pctTxt(alertadas, unidades.length);
  $("ka-sub").textContent = `+${(r.retraso_medio / 6).toFixed(0)} min`;
  $("ka-barra").style.width = pctTxt(alertadas, unidades.length);

  $("kc-valor").textContent = criticas;
  $("kc-pct").textContent = pctTxt(criticas, unidades.length);
  $("kc-sub").textContent = criticas;
  $("kc-barra").style.width = pctTxt(criticas, unidades.length);
  $("kc-sub").textContent = String(criticas);
  // barra minima para que la tarjeta critica nunca quede sin tira
  if (criticas > 0 && parseFloat($("kc-barra").style.width) < 6)
    $("kc-barra").style.width = "6%";

  const fb = { todas: unidades.length, normal: vivas, alerta: alertadas, critico: criticas };
  for (const [num, valor] of Object.entries(fb)) {
    const span = document.querySelector(`.c-${num}`);
    if (span) span.textContent = valor;
  }
};

/* ---- banner de incidente (index) ---- */
const banner = (unidades) => {
  const b = $("banner-incidente"), t = $("banner-texto");
  if (!b || !t) return;
  const alertadas = unidades.filter((u) => u.estado !== "en_ruta");
  if (alertadas.length === 0) {
    b.classList.remove("activo");
    t.textContent = "Flota nominal · sin incidentes en el canal de GPS";
    return;
  }
  b.classList.add("activo");
  t.innerHTML = alertadas
    .map((u) => `Unidad ${u.id}: <b>${u.estado.replaceAll("_", " ")}</b>, último GPS ${horaDeTick(u.ultimo_reporte)}`)
    .join(" · ");
};

/* ---- bitácora de eventos (index, 3 tarjetas) ---- */
const pintarBitacora = (r, unidades) => {
  const av = unidades.filter((u) => u.estado === "averiado");
  const ss = unidades.filter((u) => u.estado === "sin_senal");
  const hora = horaDeTick(r.tick);
  if ($("bit-critica-cuando")) {
    const m = $("bit-critica-mensaje");
    if (av.length === 0) {
      m.textContent = "Sin incidentes críticos detectados en la flota.";
      $("bit-critica-fuente").textContent = "flota nominal";
    } else {
      m.innerHTML = av
        .map((u) => `Unidad ${u.id} inmovilizada por avería (caos). Carga devuelta a la cola y reasignada por el despachador.`)
        .join(" ");
      $("bit-critica-fuente").textContent =
        `coord: (${av[0].x},${av[0].y}) · ${av.length} unidad(es)`;
    }
    $("bit-critica-cuando").textContent = hora;
  }
  if ($("bit-pre-mensaje")) {
    const m = $("bit-pre-mensaje");
    if (ss.length === 0) {
      m.textContent = "Unidades sinGPS no detectadas: el watchdog de la señal está en silencio.";
    } else {
      m.innerHTML = ss
        .map((u) => `Unidad ${u.id} sin señal GPS desde ${horaDeTick(u.ultimo_reporte)}; su carga queda en cola hasta el umbral sin_senal_ticks.`)
        .join(" ");
      $("bit-pre-fuente").textContent = `(${ss.length} unidad(es) · flota #29)`;
    }
    $("bit-pre-cuando").textContent = hora;
  }
  if ($("bit-info-mensaje")) {
    $("bit-info-mensaje").innerHTML =
      `Del despachador: <b>${r.reasignaciones}</b> reasignaciones hoy · retraso medio ` +
      `<b>+${(r.retraso_medio / 6).toFixed(0)} min</b> · ${en(r.entregas, "pendiente")} envíos pendientes en cola.`;
    $("bit-info-cuando").textContent = hora;
    $("bit-info-fuente").textContent = "p29_despachador · greedy first-fit";
  }
};

/* ---- mapa táctico (index) ---- */
const NIVEL_ZOOM = [1, 1.35, 1.8];
let nivelZoom = 0;
const mapZoom = (dir) => {
  nivelZoom = Math.min(NIVEL_ZOOM.length - 1, Math.max(0, nivelZoom + dir));
  const z = $("mapa-zoom");
  if (z) z.style.transform = `scale(${NIVEL_ZOOM[nivelZoom]})`;
};
const recenterMap = () => {
  nivelZoom = 0;
  const z = $("mapa-zoom");
  if (z) z.style.transform = "scale(1)";
};
const toggleCapa = (btn, cual) => {
  btn.classList.toggle("activo");
  const objetivo = cual === "rejilla"
    ? document.querySelector(".mapa-svg") : $("capa-velo");
  if (objetivo) objetivo.classList.toggle("oculto");
};
const MARCA = {
  en_ruta:    { clase: "",         icono: "local_shipping", color: "var(--ok)" },
  sin_senal:  { clase: "",         icono: "wifi_off",       color: "var(--warn)" },
  averiado:   { clase: "critico",  icono: "car_crash",      color: "var(--error)" },
};
const ET_CALLOUT = { en_ruta: "EN RUTA", sin_senal: "SIN SEÑAL", averiado: "DETENIDO" };

const pintarMapa = (r, unidades) => {
  const cont = $("marcadores");
  if (!cont) return;
  cont.innerHTML = "";
  let vivaMostradas = 0;
  const ordenadas = [...unidades].sort((a, b) =>
    severidadDe(b.estado).localeCompare(severidadDe(a.estado)));
  $("hud-tick").textContent = `TICK ${r.tick} · ${horaDeTick(r.tick)}`;
  for (const u of ordenadas) {
    const m = MARCA[u.estado] || MARCA.en_ruta;
    const llamable = u.estado !== "en_ruta" || vivaMostradas < 3;
    if (u.estado === "en_ruta") vivaMostradas++;
    const marcador = document.createElement("div");
    marcador.className = `marcador ${m.clase}`;
    marcador.style.left = `${(u.x + 0.5) * 10}%`;
    marcador.style.top = `${(9.5 - u.y + 0.5) * 10}%`;
    const colorPulso = u.estado === "averiado" ? "var(--error)" :
      u.estado === "sin_senal" ? "var(--warn)" : "var(--ok)";
    marcador.innerHTML = `
      <div class="pin-area">
        ${m.clase !== "" ? `<span class="pulso" style="background:transparent;box-shadow:0 0 0 1px ${colorPulso};width:40px;height:40px;left:0"></span>` : ""}
        <div class="pin" style="background:${m.color}">
          <span class="material-symbols-outlined">${m.icono}</span>
        </div>
      </div>
      ${llamable ? `
      <div class="callout ${u.estado === "averiado" ? "critico" : u.estado === "sin_senal" ? "ambar" : "verde"}">
        <div class="fila1">
          <span class="id">U-${pad(u.id)}${u.estado === "averiado" ? " [SOS]" : ""}</span>
          <span class="badge-peque">${ET_CALLOUT[u.estado] || ""}</span>
        </div>
        <span class="detalle">Carga ${u.carga} / ${u.capacidad} kg · ${u.entregadas} entregadas</span>
        <div class="datos">
          <span>(${u.x}, ${u.y})</span>
          <span>GPS ${horaDeTick(u.ultimo_reporte)}</span>
        </div>
        ${u.estado !== "en_ruta" ? `
        <button class="btn-despacho" onclick="abrirModal(${u.id})">Despachar asistencia</button>` : ""}
      </div>` : ""}
    `;
    marcador.onclick = (ev) => {
      if (ev.target.closest("button") === null)
        location.href = `unidad.html?id=${u.id}`;
    };
    cont.appendChild(marcador);
  }
};

/* ---- panel de atención requerida (index) ---- */
const pintarPanelUnidades = (unidades) => {
  const lista = $("lista-unidades");
  if (!lista) return;
  const ETIQUETA = { averiado: "SOS", sin_senal: "SIN SEÑAL", en_ruta: "NOMINAL" };
  const orden = { averiado: 0, sin_senal: 1, en_ruta: 2 };
  const lista2 = [...unidades].sort((a, b) => (orden[a.estado] ?? 3) - (orden[b.estado] ?? 3));
  lista.innerHTML = lista2.map((u) => {
    const sev = severidadDe(u.estado);
    return `
    <article class="unidad-card ${sev}" data-status="${sev}">
      <div class="cabezal">
        <div class="unidad-id">
          <div class="icono-unidad ${u.estado === "averiado" ? "crit" : u.estado === "sin_senal" ? "warn" : "ok"}">
            <span class="material-symbols-outlined">local_shipping</span>
          </div>
          <div style="min-width:0">
            <div style="display:flex;align-items:center;gap:4px">
              <span class="unidad-nombre">U-${pad(u.id)}</span>
              <span class="unidad-etiqueta ${u.estado === "averiado" ? "crit" : u.estado === "sin_senal" ? "warn" : "ok"}">${ETIQUETA[u.estado] || ""}</span>
            </div>
            <span class="unidad-sub">Unidad de reparto · flota #29</span>
          </div>
        </div>
        <div class="unidad-telemetria">
          <span class="vel ${sev}">${u.entregadas} ENTREGADAS</span>
          <span class="lb">CARGA ${u.carga}/${u.capacidad} KG</span>
        </div>
      </div>
      <div class="datos-mini">
        <div class="fila"><span class="et">Estado telemetría:</span>
          <span class="valor-dato ${sev}">${u.estado.replaceAll("_", " ")}</span></div>
        <div class="fila"><span class="et">Último GPS:</span>
          <span class="valor-dato">${horaDeTick(u.ultimo_reporte)} · (${u.x},${u.y})</span></div>
      </div>
      <div class="acciones-unidad">
        <a href="unidad.html?id=${u.id}" style="text-decoration:none">
          <button class="btn-tarjeta neutro" style="width:100%">
            <span class="material-symbols-outlined">visibility</span><span>Inspeccionar</span>
          </button>
        </a>
        <button class="btn-tarjeta ${sev === "normal" ? "neutro" : "grave"}" onclick="abrirModal(${u.id})">
          <span class="material-symbols-outlined">alt_route</span><span>Asistir / caos</span>
        </button>
      </div>
    </article>`;
  }).join("");
  const criticas = unidades.filter((u) => u.estado === "averiado").length +
    unidades.filter((u) => u.estado === "sin_senal").length;
  $("badge-panel").textContent = criticas > 0 ? `${criticas} nodos` : "flota saludable";
  $("badge-panel").className = `badge-cuenta ${criticas > 0 ? "crit" : "ok"}`;
};

/* ---- filtros de estado (index) ---- */
const setEstado = (estado, btn) => {
  if (btn) {
    document.querySelectorAll("#filter-status-group .btn-filtro").forEach((b) => {
      const es = b === btn;
      b.classList.toggle("activo", es);
      if (es) b.classList.remove("activo-v"); else b.classList.remove("activo-v");
    });
  } else {
    const botón = document.querySelector(`#filter-status-group .btn-filtro[data-estado="${estado}"]`);
    if (botón) { setEstado(estado, botón); return; }
  }
  document.querySelectorAll(".unidad-card").forEach((card) => {
    const s = card.getAttribute("data-status");
    const coincide = estado === "todos" || s === estado;
    card.style.display = coincide ? "" : "none";
  });
};

/* ---- modal operador (index) ---- */
let modalUnidad = null;
const abrirModal = (idUnidad) => {
  modalUnidad = idUnidad;
  const u = g.unidades.find((x) => x.id === idUnidad);
  $("modal-title").textContent = `Gestión de misión · U-${pad(idUnidad)}`;
  $("modal-desc").innerHTML =
    "Ordene la asistencia / inyección de avería (caos): la carga viva de la unidad " +
    "vuelve a la cola y el despachador reasigna en el mismo tick. Ideal para ver la " +
    "reelección de rutas bajo fallo en el vivo.";
  const detalles = u ? [
    ["Estado", u.estado.replaceAll("_", " ")],
    ["Carga vivida", `${u.carga} / ${u.capacidad} kg`],
    ["Entregas servidas", String(u.entregadas)],
    ["Último GPS", `${horaDeTick(u.ultimo_reporte)} · (${u.x},${u.y})`],
  ] : [];
  $("modal-details").innerHTML = detalles
    .map(([et, valor]) => `<div class="fila"><span class="et">${et}:</span><span>${valor}</span></div>`)
    .join("");
  $("btn-ejecutar").onclick = ejecutarDespacho;
  $("modal-operador").classList.add("abierto");
};
const cerrarModal = () => $("modal-operador").classList.remove("abierto");
const ejecutarDespacho = async () => {
  if (modalUnidad === null) return;
  const r = await postJSON("/api/averiar", { unidad: modalUnidad });
  cerrarModal();
  if (r.ok) {
    mostrarToast(`Orden de despacho aplicada a U-${pad(modalUnidad)}. Reasignando en el mismo tick…`);
  } else {
    mostrarToast(`Error: ${r.error || "unidad no disponible"}`, "error");
  }
};

/* ---- toast ---- */
let toastTimer = null;
const mostrarToast = (mensaje, tipo) => {
  const t = $("toast");
  if (!t) return;
  $("toast-texto").textContent = mensaje;
  $("toast-icono").textContent = tipo === "error" ? "report" : "check_circle";
  t.classList.add("abierto");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => t.classList.remove("abierto"), 4000);
};

/* ---- página index ---- */
const pintarIndex = async () => {
  const [resumen, unidades, entregas] = await Promise.all(
    [getJSON("/api/estado"), getJSON("/api/vehiculos"), getJSON("/api/entregas")]);
  g.unidades = unidades; g.entregas = entregas;
  pintarResumen(resumen);
  pintarKpis(resumen, unidades);
  pintarMapa(resumen, unidades);
  pintarPanelUnidades(unidades);
  pintarBitacora(resumen, unidades);
  banner(unidades);
};

/* ---- página unidad ---- */
const SEMAFORO = {
  en_ruta:   { clase: "verde", lb: "ESTADO: SEMÁFORO VERDE", dato: "EN RUTA · NOMINAL",
               chip: "EN RUTA", sub: "Reporte GPS al día · misión viva en curso." },
  sin_senal: { clase: "ambar", lb: "ESTADO: SEMÁFORO AMBAR", dato: "SIN SEÑAL GPS",
               chip: "SIN SEÑAL", sub: "El watchdog vigila el umbral sin_senal_ticks; si rebasa, reasigna la carga." },
  averiado:  { clase: "rojo",  lb: "ESTADO: SEMÁFORO ROJO",  dato: "AVERIADA · SOS",
               chip: "DETENIDA", sub: "Inmovilizada por avería (caos). p29_flota_sup la relanza vacía en el relanzamiento." },
};
const pintarUnidad = async () => {
  const id = parseInt(new URLSearchParams(location.search).get("id"), 10) || 1;
  const [unidades, entregas, resumen] = await Promise.all(
    [getJSON("/api/vehiculos"), getJSON("/api/entregas"), getJSON("/api/estado")]);
  g.unidades = unidades; g.entregas = entregas;
  pintarResumen(resumen);
  const u = unidades.find((x) => x.id === id);
  if (!u) { $("titulo").textContent = `Unidad ${id} no encontrada`; return; }
  const servidas = entregas.filter((e) => e.vehiculo === id);
  const cerradas = servidas.filter((e) => e.estado === "entregada");
  const vivas = servidas.filter((e) => e.estado === "en_ruta");
  const maxEntregas = Math.max(...unidades.map((x) => x.entregadas), 1);

  $("titulo").innerHTML = `U-${pad(id)} <span class="tramo">/ producción ${cerradas.length} entregas</span>`;
  $("chip-tipo").textContent = `Unidad de reparto #${id}`;
  $("tramo-unidad").innerHTML = vivas.length
    ? `Tramo vivo: ${vivas.map((e) => `${e.colonia} (ENV-#${e.id})`).join(" · ")}`
    : "Sin tramo activo: la cola la reparte el despachador (greedy first-fit) en el siguiente tick.";

  const sf = SEMAFORO[u.estado] || SEMAFORO.en_ruta;
  const sem = $("estado-unidad");
  sem.className = `semforo-retraso ${sf.clase}`;
  sem.querySelector(".lb").textContent = sf.lb;
  sem.querySelector(".dato").textContent =
    `${sf.dato} · CARGA ${u.carga}/${u.capacidad} KG`;
  $("motivo-retraso").innerHTML =
    `Último reporte GPS: <b>${horaDeTick(u.ultimo_reporte)}</b> (tick ${resumen.tick}) · ${sf.sub}`;
  $("banner-texto").textContent =
    u.estado === "en_ruta"
      ? `Unidad en operación nominal · último GPS ${horaDeTick(u.ultimo_reporte)}`
      : `Alerta de unidad: ${u.estado.replaceAll("_", " ")} desde el GPS ${horaDeTick(u.ultimo_reporte)} · revisar módulo de reasignación`;
  if (u.estado !== "en_ruta") $("banner-incidente").classList.add("activo");

  $("f1-entregadas").textContent = cerradas.length;
  $("f1-vivas").textContent = vivas.length;
  $("f1-barra").style.width = `${Math.min(100, (100 * cerradas.length) / maxEntregas)}%`;

  const b = $("banner-incidente"); void b;
  $("chip-sector").textContent = `(${u.x},${u.y})`;
  $("f2-xy").textContent = `(${u.x}, ${u.y})`;
  $("f2-pos").textContent = `${u.x} / ${u.y}`;
  $("f2-ultimo").textContent = horaDeTick(u.ultimo_reporte);
  const pin = $("pin-unidad");
  pin.style.left = `${(u.x + 0.5) * 10}%`;
  pin.style.top = `${(9.5 - u.y + 0.5) * 10}%`;

  const pctCarga = u.capacidad ? (100 * u.carga) / u.capacidad : 0;
  $("chip-carga").textContent = `${u.carga} KG A BORDO`;
  $("f3-carga-kg").textContent = u.carga;
  $("f3-capacidad").textContent = u.capacidad;
  $("f3-pct").textContent = `${Math.round(pctCarga)}%`;
  $("f3-barra").style.width = `${Math.min(100, pctCarga)}%`;
  $("f3-mision").textContent = vivas.length
    ? `${vivas.length} envío(s) en ruta` : "sin envíos en ruta";
  $("f3-plan").textContent = vivas.length;

  $("chip-estado-mini").textContent = sf.chip;
  $("f4-estado").textContent = sf.dato;
  $("f4-estado-sub").textContent = sf.sub;
  $("f4-capacidad").textContent = `${u.capacidad} kg`;

  $("registro-destino").textContent = vivas.length
    ? vivas.map((e) => e.colonia).slice(0, 2).join(" · ") +
      (vivas.length > 2 ? ` +${vivas.length - 2}` : "")
    : "— (cola vacía)";
  $("registro-estado").textContent =
    u.estado === "en_ruta" ? "RUTA ACTIVA" :
    u.estado === "sin_senal" ? "SEÑAL PERDIDA" : "UNIDAD DETENIDA";
  $("registro-estado").style.color =
    u.estado === "en_ruta" ? "var(--primary)" : "var(--error)";
  $("detalle-carga").textContent =
    `Capacidad ${u.capacidad} kg · ${vivas.length} envío(s) en ruta · ${cerradas.length} servidas hoy.`;

  $("tbody-cargas").innerHTML = vivas.map(filaEntrega).join("") || filaVacia(6, "sin cargas asignadas ahora");
  $("tbody-servidas").innerHTML =
    cerradas.slice(0, 30).map(filaEntrega).join("") || filaVacia(6, "aún no cierra entregas este día");

  $("campo-unidad").value = `U-${pad(id)} · carga ${u.carga}/${u.capacidad} kg · (${u.x},${u.y})`;
};

/* ---- módulo de reasignación (maqueta 2) ---- */
const TEXTOS_OPCION = {
  A: "AVERIAR UNIDAD. LA CARGA VIVA VUELVE A PENDIENTE Y EL DESPACHADOR REASIGNA POR GREEDY FIRST-FIT EN EL MISMO TICK. CONFIRMAR CONDICIÓN DE FLOTA EN /METRICS.",
  B: "MARCAR ENTREGA URGENTE PARA ESTA UNIDAD. EL DESPACHADOR LA ATENDERÁ CON PRIORIDAD AL VENCER SU VENTANA. MONITOREO POR SSE /EVENTOS.",
  C: "SOLO SUPERVISIÓN: NO SE TRANSMITE NINGÚN CAMBIO AL DOMINIO. OBSERVE LA TELEMETRÍA EN VIVO DESDE EL CONTROL.",
};
let opcionActual = "A";
const seleccionarOpcion = (tipo) => {
  opcionActual = tipo;
  for (const t of ["A", "B", "C"]) {
    const el = $(`opcion-${t.toLowerCase()}`);
    if (el) el.classList.toggle("elegida", t === tipo);
  }
  $("instruccion").value = TEXTOS_OPCION[tipo];
};
let prioridadActual = "Urgente";
const setPrioridad = (nivel, boton) => {
  prioridadActual = nivel;
  document.querySelectorAll(".btn-prio").forEach((b) => {
    b.classList.remove("activo", "grave");
  });
  boton.classList.add("activo");
  if (nivel === "Crítica") boton.classList.add("grave");
};
const transmitirReasignacion = async (ev) => {
  ev.preventDefault();
  const id = parseInt(new URLSearchParams(location.search).get("id"), 10) || 1;
  const btn = $("btn-transmitir");
  btn.disabled = true;
  if (opcionActual === "C") {
    mostrarToast("Modo observación: no se transmitió ningún cambio al dominio.");
    btn.disabled = false;
    return;
  }
  btn.innerHTML = `<span class="material-symbols-outlined">autorenew</span>
    <span>Transmitiendo a U-${pad(id)}…</span>`;
  const ruta = opcionActual === "A" ? "/api/averiar" : "/api/urgente";
  const r = await postJSON(ruta, { unidad: id });
  btn.disabled = false;
  btn.innerHTML = `<span class="material-symbols-outlined">send</span>
    <span>Confirmar y transmitir requerimiento</span>`;
  if (r.ok) {
    mostrarToast(opcionActual === "A"
      ? `¡Avería aplicada a U-${pad(id)}! La carga reasignada por el despachador.`
      : `¡Urgencia marcada para U-${pad(id)}! Atenderá con prioridad la entrega.`);
    pintarUnidad();
  } else {
    mostrarToast(`Error: ${r.error || "la unidad no está disponible"}`, "error");
  }
};
const abrirRadio = () => $("panel-radio").classList.remove("oculto");
const cerrarRadio = () => $("panel-radio").classList.add("oculto");

/* ---- página historial (maqueta 3) ---- */
let filtroCat = "todas";
let filtroSev = "todas";
const itemsCrono = (unidades, entregas) => {
  const items = [];
  const fallidas = entregas.filter((e) => e.estado === "fallida");
  for (const e of fallidas.slice(0, 20)) {
    items.push({ sev: "critica", cat: "sos", icono: "report_problem",
      titulo: `Entrega fallida · ENV-#${e.id}`, ref: `ENV-#${e.id} · ${e.colonia}`,
      sub: `Peso ${e.peso} kg · ventana ${e.ventana_desde}–${e.ventana_hasta}` +
        (e.vehiculo === null ? " · unidad: —" : ` · unidad U-${pad(e.vehiculo)}`),
      mensaje: "Cliente ausente u otro motivo de la corrida: el envío queda fuera de la meta del día (5–15 % objetivo del enunciado).",
      estadoTxt: "FALLIDA", estadoClase: "critica",
      accion: null,
      telem: [["Peso", `${e.peso} kg`], ["Ventana", `${e.ventana_desde}–${e.ventana_hasta}`],
              ["Retraso", `+${e.retraso}`],
              ["Unidad", e.vehiculo === null ? "sin asignar" : `U-${pad(e.vehiculo)}`]] });
  }
  for (const u of unidades.filter((x) => x.estado !== "en_ruta")) {
    const crit = u.estado === "averiado";
    items.push({ sev: crit ? "critica" : "precaucion", cat: "unidades",
      icono: crit ? "car_crash" : "wifi_off",
      titulo: `Unidad U-${pad(u.id)} — ${u.estado.replaceAll("_", " ")}`,
      ref: crit ? "CAOS AVERIADO" : "SEÑAL GPS PERDIDA",
      sub: `Último GPS ${horaDeTick(u.ultimo_reporte)} · carga ${u.carga}/${u.capacidad} kg · ${u.entregadas} entregadas`,
      mensaje: crit
        ? "Unidad inmovilizada por avería inyectada (caos). Su carga vuelve a la cola y el despachador reasigna; p29_flota_sup la relanza vacía."
        : "Sin señal GPS: su carga pasa a pendiente si rebasa el umbral; la señal de vuelta repone la unidad.",
      estadoTxt: crit ? "ACTIVO" : "AVISO", estadoClase: crit ? "critica" : "precaucion",
      accion: `unidad.html?id=${u.id}`, accionTxt: "Ver unidad",
      telem: [["Último GPS", horaDeTick(u.ultimo_reporte)],
              ["Carga", `${u.carga} / ${u.capacidad} kg`],
              ["Entregadas", String(u.entregadas)],
              ["Posición", `(${u.x}, ${u.y})`]] });
  }
  const cerradas = entregas.filter((e) => e.estado === "entregada");
  for (const e of cerradas.slice(-14).reverse()) {
    items.push({ sev: "nominal", cat: "servidas", icono: "task_alt",
      titulo: `Entrega cerrada · ENV-#${e.id}`, ref: `ENV-#${e.id} · ${e.colonia}`,
      sub: `Peso ${e.peso} kg · ventana ${e.ventana_desde}–${e.ventana_hasta}` +
        (e.vehiculo === null ? "" : ` · unidad U-${pad(e.vehiculo)}`),
      mensaje: "Servicio cerrado por la unidad terrestre asignada; el conteo va a /metrics como entregada.",
      estadoTxt: "ENTREGA CERRADA", estadoClase: "nominal",
      accion: null, accionTxt: null,
      telem: [["Peso", `${e.peso} kg`], ["Ventana", `${e.ventana_desde}–${e.ventana_hasta}`],
              ["Retraso", `+${e.retraso}`],
              ["Unidad", e.vehiculo === null ? "—" : `U-${pad(e.vehiculo)}`]] });
  }
  return items;
};
const pintarHistorial = async () => {
  const [entregas, unidades, resumen] = await Promise.all(
    [getJSON("/api/entregas"), getJSON("/api/vehiculos"), getJSON("/api/estado")]);
  g.unidades = unidades; g.entregas = entregas;
  pintarResumen(resumen);
  const e = resumen.entregas || {}, v = resumen.vehiculos || {};
  const averiadas = unidades.filter((u) => u.estado === "averiado").length;
  const sinSenal = unidades.filter((u) => u.estado === "sin_senal").length;

  $("kicker-ciclo").textContent = `Ciclo activo #29-TX · tick ${resumen.tick}`;
  $("bc-crit").textContent = averiadas + en(e, "fallida");
  $("bc-pre").textContent = sinSenal;
  $("bc-nom").textContent = en(e, "entregada");

  const b = $("banner-incidente"), t = $("banner-texto");
  const det = unidades.find((u) => u.estado !== "en_ruta");
  if (det) {
    b.classList.add("activo");
    $("banner-punto")?.classList.remove("oculto");
    t.innerHTML = `Unidad ${det.id}: <b>${det.estado.replaceAll("_", " ")}</b>, último GPS ${horaDeTick(det.ultimo_reporte)}.`;
  } else {
    b.classList.remove("activo");
    $("banner-punto")?.classList.add("oculto");
    t.textContent = "Flota nominal · sin incidencias activas en el canal.";
  }

  const cont = $("timeline-container");
  cont.innerHTML = itemsCrono(unidades, entregas).map((it, i) => `
    <article class="item-crono icono-${it.sev} estado-${it.sev}"
        data-category="${it.cat}" data-severity="${it.sev}" id="ev-${i}">
      <div class="cabeza-ev">
        <div class="badges-ev">
          <span class="severidad ${it.sev}"><span class="punto"></span>${it.sev === "critica" ? "CRÍTICO" : it.sev === "precaucion" ? "PRECAUCIÓN" : "NORMAL"}</span>
          <span class="chip-ev">${it.ref}</span>
        </div>
        <div class="estado-activo">
          <span class="txt">${it.estadoTxt}</span>
          <span class="material-symbols-outlined" style="font-size:18px">${it.icono}</span>
        </div>
      </div>
      <div class="cuerpo-ev">
        <div style="display:flex;align-items:flex-start;gap:var(--ss);min-width:0">
          <div class="icono-ev"><span class="material-symbols-outlined" style="font-size:24px">${it.icono}</span></div>
          <div class="detalle-ev">
            <div class="id-ev"><h2 class="titulo-ev">${it.titulo}</h2></div>
            <span class="sub-ev">${it.sub}</span>
          </div>
        </div>
        <div class="btns-ev">
          <button class="btn-detalle" onclick="toggleCrono('tel-${i}')">Telemetría</button>
          ${it.accion ? `<a href="${it.accion}" style="text-decoration:none"><button class="btn-ver">${it.accionTxt}</button></a>` : ""}
        </div>
      </div>
      <div style="margin-left:0">
        <p class="mensaje-ev">${it.mensaje}</p>
      </div>
      <div class="telemetria-ev oculto" id="tel-${i}">
        ${it.telem.map(([lb, dato]) => `
          <div class="col"><span class="lb">${lb}</span>
          <span class="dato ${it.sev}">${dato}</span></div>`).join("")}
      </div>
    </article>`).join("") || "";
  applyFilters();

  $("aud-invariantes").textContent = resumen.invariantes === "ok" ? "OK" : "ERROR";
  $("aud-invariantes").style.color =
    resumen.invariantes === "ok" ? "var(--primary)" : "var(--error)";
  $("aud-sello").textContent = `tick ${resumen.tick}`;
  $("aud-reasign").textContent = resumen.reasignaciones;
  $("aud-reasign-sub").textContent = "reasignaciones por greedy first-fit en el día";
  $("aud-retraso").textContent = `+${(resumen.retraso_medio / 6).toFixed(0)} min`;
  $("met-estado").textContent = sinSenal > 0 ? "Precaución parcial" : "Nominal";
  $("met-sub").innerHTML = sinSenal > 0
    ? `sin señal: <b>${sinSenal}</b> unidad(es) · reasignaciones: ${resumen.reasignaciones}`
    : "sin señal vacía · watchdog en silencio";

  const sel = $("unit-select");
  sel.innerHTML =
    `<option value="">Seleccione activo…</option>` +
    unidades.map((u) => `<option value="${u.id}">U-${pad(u.id)} · carga ${u.carga}/${u.capacidad} kg</option>`).join("");
};
const toggleCrono = (id) => $(id)?.classList.toggle("oculto");
const applyFilters = () => {
  const q = ($("timeline-search")?.value || "").toLowerCase().trim();
  $("clear-search-btn")?.classList.toggle("oculto", q.length === 0);
  const items = document.querySelectorAll(".item-crono");
  let visibles = 0;
  items.forEach((item) => {
    const cat = item.getAttribute("data-category") || "";
    const sev = item.getAttribute("data-severity") || "";
    const texto = item.textContent.toLowerCase();
    const okQ = q === "" || texto.includes(q);
    const okC = filtroCat === "todas" || cat.includes(filtroCat);
    const okS = filtroSev === "todas" || sev === filtroSev;
    const mostrar = okQ && okC && okS;
    item.classList.toggle("oculto", !mostrar);
    if (mostrar) visibles++;
  });
  $("active-event-count").textContent = `${visibles} eventos visibles`;
  const vacio = $("empty-state");
  if (vacio) vacio.classList.toggle("oculto", visibles > 0);
};
const clearSearch = () => { $("timeline-search").value = ""; applyFilters(); };
const resetAllFilters = () => {
  $("timeline-search").value = "";
  filtroSev = "todas";
  filterCategory("todas", document.querySelector(".chip-cat"));
};
const filterCategory = (cat, btn) => {
  filtroCat = cat;
  document.querySelectorAll(".chip-cat").forEach((c) => c.classList.remove("activo"));
  if (btn) btn.classList.add("activo");
  applyFilters();
};
const filterSeverity = (sev) => {
  filtroSev = filtroSev === sev ? "todas" : sev;
  applyFilters();
};
const setTimeframe = (f) => {
  const b24 = $("filter-btn-24h"), bt = $("filter-btn-shift");
  const activo = "padding:8px var(--ss);border:0;cursor:pointer;border-radius:.375rem;font:600 var(--tsm) var(--sans);background:var(--surface-lowest);color:var(--primary);box-shadow:0 1px 2px rgba(11,28,48,.1)";
  const neutro = "padding:8px var(--ss);border:0;border-radius:.375rem;font:600 var(--tsm) var(--sans);background:transparent;color:var(--on-variant)";
  b24.style.cssText = f === "24h" ? activo : neutro;
  bt.style.cssText = f === "24h" ? neutro : activo;
};
const handleLogSubmit = async (ev) => {
  ev.preventDefault();
  const unidad = parseInt($("unit-select").value, 10);
  if (Number.isNaN(unidad)) { alert("Seleccione una unidad."); return; }
  const sev = document.querySelector("input[name='severity-input']:checked").value;
  const btn = document.querySelector("#log-form button[type='submit']");
  const original = btn.innerHTML;
  btn.innerHTML = "<span>Aplicando…</span>";
  const ruta = sev === "critica" ? "/api/averiar" : "/api/urgente";
  const r = await postJSON(ruta, { unidad });
  btn.innerHTML = original;
  if (!r.ok) { mostrarToast(`Error: ${r.error || "unidad no disponible"}`, "error"); return; }
  $("form-toast-texto").textContent = sev === "critica"
    ? `Avería aplicada a U-${pad(unidad)} y firmada en la bitácora: la carga reasignada.`
    : `Urgencia marcada para U-${pad(unidad)} y firmada en la bitácora.`;
  $("form-toast").classList.remove("oculto");
  $("log-form").reset?.();
  pintarHistorial();
};

/* ---- red ---- */
async function getJSON(ruta) { return (await fetch(ruta)).json(); }
async function postJSON(ruta, cuerpo) {
  const resp = await fetch(ruta, { method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(cuerpo || {}) });
  return resp.json();
}

/* ---- arranque ---- */
document.addEventListener("DOMContentLoaded", async () => {
  const pagina = document.body.dataset.page;
  if (pagina === "index") await pintarIndex();
  else if (pagina === "unidad") await pintarUnidad();
  else if (pagina === "historial") await pintarHistorial();
  // en vivo: un evento "estado" por tick con resumen + instantánea de unidades
  const flujo = new EventSource("/eventos");
  flujo.addEventListener("estado", (m) => {
    const r = JSON.parse(m.data);
    pintarResumen(r);
    pintarKpis(r, r.unidades || []);
    if (pagina === "index") {
      g.unidades = r.unidades || [];
      pintarMapa(r, g.unidades);
      pintarPanelUnidades(g.unidades);
      pintarBitacora(r, g.unidades);
      banner(g.unidades);
    } else if (pagina === "unidad") {
      pintarUnidad();
    } else if (pagina === "historial") {
      pintarHistorial();
    }
  });
});
