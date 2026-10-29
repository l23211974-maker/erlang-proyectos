/* Flotilla #29 — cliente de la API. Plano (sin frameworks): fetch para el
   estado inicial y SSE (/eventos) para el estado en vivo (un evento por tick
   con resumen e instantanea de las unidades). Cada pagina declara su tipo en
   <body data-page="..."> y este modulo pinta lo que le corresponde. */

"use strict";

/* ---- utilerias ---- */
const $ = (id) => document.getElementById(id);
const horaDeTick = (tick) => {
  if (tick === null || tick === undefined) return "—";
  const seg = 8 * 3600 + tick * 10;         // 08:00 simulada, 10 s de GPS/tick
  const h = Math.floor(seg / 3600) % 24, m = Math.floor((seg % 3600) / 60);
  return String(h).padStart(2, "0") + ":" + String(m).padStart(2, "0");
};
const PILL = { en_ruta: "ok", entregada: "ok", sin_senal: "warn", pendiente: "off",
               averiado: "crit", fallida: "crit" };
const pill = (estado) => {
  const clase = PILL[estado] || "off";
  return `<span class="pill ${clase}"><span class="dot ${clase}"></span>${estado.replaceAll("_", " ")}</span>`;
};
const filaEntrega = (e) => `
  <tr>
    <td class="id">${e.id}${e.urgente ? " ⚠" : ""}</td>
    <td>${e.colonia}</td>
    <td>${e.peso} kg</td>
    <td>${e.ventana_desde}–${e.ventana_hasta}</td>
    <td>${pill(e.estado)}</td>
    <td>${e.vehiculo === null ? "—" : e.vehiculo}</td>
    <td>${e.retraso > 0 ? "+" + e.retraso : "—"}</td>
  </tr>`;
const filaUnidad = (u) => `
  <tr>
    <td class="id"><a href="unidad.html?id=${u.id}">U-${String(u.id).padStart(2, "0")}</a></td>
    <td>${pill(u.estado)}</td>
    <td>${horaDeTick(u.ultimo_reporte)}</td>
    <td>${u.carga} / ${u.capacidad} kg</td>
    <td>${u.entregadas}</td>
    <td>${u.x},${u.y}</td>
    <td><a href="unidad.html?id=${u.id}">ver</a></td>
  </tr>`;
const suma = (obj) => Object.values(obj || {}).reduce((a, b) => a + b, 0);
const en = (obj, clave) => (obj || {})[clave] || 0;

const pintarResumen = (r) => {  if (!$("kpis")) return;
  const e = r.entregas || {}, v = r.vehiculos || {}, total = suma(e);
  const pct = (x) => total ? `${(100 * x / total).toFixed(1)}% del día` : "sin entregas";
  $("kpi-flota").querySelector(".valor").textContent =
    `${en(v, "en_ruta")} / ${suma(v)}`;
  $("kpi-flota").querySelector(".sub").textContent = "unidades reportando GPS";
  $("kpi-entregadas").querySelector(".valor").textContent = en(e, "entregada");
  $("kpi-entregadas").querySelector(".sub").textContent = pct(en(e, "entregada"));
  $("kpi-enruta").querySelector(".valor").textContent = en(e, "en_ruta");
  $("kpi-enruta").querySelector(".sub").textContent =
    `${en(e, "pendiente")} pendientes en cola`;
  $("kpi-fallidas").querySelector(".valor").textContent = en(e, "fallida");
  $("kpi-fallidas").querySelector(".sub").textContent = pct(en(e, "fallida"));
  $("kpi-alertas").querySelector(".valor").textContent =
    en(v, "sin_senal") + en(v, "averiado");
  $("kpi-alertas").querySelector(".sub").textContent = "unidades con alerta";
  if ($("dato-reasignaciones")) $("dato-reasignaciones").textContent = r.reasignaciones;
  if ($("dato-retraso")) $("dato-retraso").textContent = `+${(r.retraso_medio / 6).toFixed(0)} min`;
  if ($("tick-hora")) $("tick-hora").textContent = horaDeTick(r.tick);
  const inv = r.invariantes;
  if (inv && $("badge-invariantes") && inv !== $("badge-invariantes").dataset.valor) {
    $("badge-invariantes").outerHTML =
      `<span id="badge-invariantes" class="pill ${inv === "ok" ? "ok" : "crit"}"
        data-valor="${inv}"><span class="dot ${inv === "ok" ? "ok" : "crit"}"></span>
        invariantes ${inv}</span>`;
  }
};
const pintarUnidades = (unidades) => {
  if ($("tbody-flota")) {
    $("tbody-flota").innerHTML = unidades.map(filaUnidad).join("");
    $("cuenta-flota").textContent = `${unidades.length} unidades`;
  }
  pintarMapa(unidades);
  banner(unidades);
};
/* dibuja la rejilla vacia una vez; los chips de unidades se colocan encima */
const dibujarRejilla = () => {
  if (!$("mapa-celdas")) return;
  for (let i = 0; i < 100; i++) {
    const celda = document.createElement("div");
    celda.className = "celda";
    $("mapa-celdas").appendChild(celda);
  }
};
const pintarMapa = (unidades) => {
  if (!$("mapa-celdas")) return;
  for (const chip of document.querySelectorAll("#mapa-celdas .unidad-chip")) chip.remove();
  for (const u of unidades) {
    const chip = document.createElement("div");
    chip.className = `unidad-chip ${u.estado}`;
    chip.style.gridColumn = String(u.x + 1);
    chip.style.gridRow = String(u.y + 1);
    chip.title = `Unidad ${u.id} · ${u.estado} · (${u.x},${u.y})`;
    chip.onclick = () => { location.href = `unidad.html?id=${u.id}`; };
    $("mapa-celdas").appendChild(chip);
  }
};
const banner = (unidades) => {
  const b = $("banner-incidente");
  if (!b) return;
  const alertadas = unidades.filter((u) => u.estado !== "en_ruta");
  if (alertadas.length === 0) { b.classList.remove("activo"); return; }
  b.classList.add("activo");
  b.querySelector(".texto").innerHTML = alertadas
    .map((u) => `Unidad ${u.id}: <b>${u.estado.replaceAll("_", " ")}</b>, último GPS ${horaDeTick(u.ultimo_reporte)}`)
    .join(" · ");
};

/* ---- páginas ---- */
const pintarIndex = async () => {
  dibujarRejilla();
  const [resumen, unidades, entregas] = await Promise.all(
    [getJSON("/api/estado"), getJSON("/api/vehiculos"), getJSON("/api/entregas")]);
  pintarResumen(resumen);
  pintarUnidades(unidades);
  const vivas = entregas.filter((e) => e.estado === "en_ruta").slice(0, 12);
  $("tbody-manifiesto").innerHTML = vivas.map(filaEntrega).join("") ||
    `<tr><td colspan="7" style="text-align:center;color:var(--on-variant)">cola vacía</td></tr>`;
};

const pintarUnidad = async () => {
  const id = parseInt(new URLSearchParams(location.search).get("id"), 10) || 1;
  const [unidades, entregas, resumen] = await Promise.all(
    [getJSON("/api/vehiculos"), getJSON("/api/entregas"), getJSON("/api/estado")]);
  const u = unidades.find((x) => x.id === id);
  if (!u) { $("titulo").textContent = `Unidad ${id} no encontrada`; return; }
  $("titulo").innerHTML =
    `Unidad ${id} <span style="font:500 18px/24px var(--mono);color:var(--on-variant)">
      / ${u.carga} en ruta · ${u.entregadas} entregadas hoy</span>`;
  $("estado-unidad").innerHTML = pill(u.estado);
  $("tel-ultimo").textContent = horaDeTick(u.ultimo_reporte);
  $("tel-pos").textContent = `(${u.x}, ${u.y})`;
  $("tel-capacidad").textContent = `${u.carga} / ${u.capacidad} kg`;
  $("tick-hora").textContent = horaDeTick(resumen.tick);
  const cargas = entregas.filter((e) => e.vehiculo === id && e.estado === "en_ruta");
  $("tbody-cargas").innerHTML = cargas.map(filaEntrega).join("") ||
    `<tr><td colspan="7" style="text-align:center;color:var(--on-variant)">sin cargas asignadas</td></tr>`;
  const servidas = entregas.filter((e) => e.vehiculo === id && e.estado === "entregada");
  $("tbody-servidas").innerHTML = servidas.slice(0, 30).map(filaEntrega).join("") ||
    `<tr><td colspan="7" style="text-align:center;color:var(--on-variant)">aún no entregar paquetes este día</td></tr>`;
  $("btn-averiar").onclick = async () => {
    const texto = `¿Inyectar avería en la unidad ${id}? Sus cargas pasan a pendientes y se reasignan al instante.`;
    if (!confirm(texto)) return;
    const r = await postJSON("/api/averiar", { unidad: id });
    r.ok ? location.reload() : alert(`Error: ${r.error}`);
  };
};

const pintarHistorial = async () => {
  const [entregas, unidades, resumen] = await Promise.all(
    [getJSON("/api/entregas"), getJSON("/api/vehiculos"), getJSON("/api/estado")]);
  const fallidas = entregas.filter((e) => e.estado === "fallida");
  $("cuenta-fallidas").textContent = String(fallidas.length);
  $("tbody-fallidas").innerHTML = fallidas.map(filaEntrega).join("") ||
    `<tr><td colspan="7" style="text-align:center;color:var(--on-variant)">ninguna entrega fallada este día</td></tr>`;
  const alertadas = unidades.filter((u) => u.estado !== "en_ruta");
  $("cuenta-alertas").textContent = String(alertadas.length);
  $("tbody-alertas").innerHTML = alertadas.map((u) => `
    <tr>
      <td class="id"><a href="unidad.html?id=${u.id}">U-${String(u.id).padStart(2, "0")}</a></td>
      <td>${pill(u.estado)}</td>
      <td>${horaDeTick(u.ultimo_reporte)}</td>
      <td>${u.carga}</td>
      <td>${u.entregadas}</td>
    </tr>`).join("") ||
    `<tr><td colspan="5" style="text-align:center;color:var(--on-variant)">todas las unidades reportando GPS</td></tr>`;
  $("tick-hora").textContent = horaDeTick(resumen.tick);
};

/* ---- red ---- */
async function getJSON(ruta) { return (await fetch(ruta)).json(); }
async function postJSON(ruta, cuerpo) {
  const resp = await fetch(ruta, { method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(cuerpo || {}) });
  return resp.json();
}

document.addEventListener("DOMContentLoaded", async () => {
  const pagina = document.body.dataset.page;
  if (pagina === "index") await pintarIndex();
  else if (pagina === "unidad") await pintarUnidad();
  else if (pagina === "historial") await pintarHistorial();
  // mapa en vivo: un evento "estado" por tick con resumen + instantanea
  const flujo = new EventSource("/eventos");
  flujo.addEventListener("estado", (m) => {
    const r = JSON.parse(m.data);
    pintarResumen(r);
    if (pagina === "index") pintarUnidades(r.unidades);
  });
});
