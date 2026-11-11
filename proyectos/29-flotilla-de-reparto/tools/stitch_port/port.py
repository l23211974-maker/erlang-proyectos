"""Porta las maquetas Stitch (Tailwind CDN) a estáticos de cowboy.

- Quita el CDN y el tailwind.config.
- Reemplaza la cabecera por la del proyecto (fuentes + stitch.css).
- Reescribe la navegación (data-path -> páginas reales) y marca la activa.
- Sustituye el logo remoto por un icono local.
- Añade ganchos (ids) para que app.js hidrate datos reales.

Uso: python tools/stitch_port/port.py
"""
import re, pathlib, sys

BASE = pathlib.Path(r"C:\Users\Max\Downloads\stitch_gestor_de_flotilla_a_rea_extracted\stitch_gestor_de_flotilla_a_rea")
OUT = pathlib.Path(r"C:\Users\Max\dev\erlang-proyectos\proyectos\29-flotilla-de-reparto\priv\static")

PAGES = {
    "monitoreo-en-vivo": ("monitoreo_en_vivo_flotilla_aerocargo", "index.html",
                          "AeroCargo · Monitoreo en Vivo"),
    "bitacora-y-alertas": ("bit_cora_y_alertas_historial_de_flota", "historial.html",
                           "AeroCargo · Bitácora y Alertas"),
    "detalle-de-unidad-y-reasignacion": ("detalle_de_unidad_y_reasignaci_n_vuelo_ac_702_1", "unidad.html",
                                         "AeroCargo · Detalle de Unidad"),
    "detalle-enfocado": ("detalle_de_unidad_y_reasignaci_n_vuelo_ac_702_2", "unidad-enfocada.html",
                         "AeroCargo · AC-702 Despacho"),
}
ROUTES = {
    "monitoreo-en-vivo": "index.html",
    "bitacora-y-alertas": "historial.html",
    "detalle-de-unidad-y-reasignacion": "unidad.html",
    "configuracion-de-flota": "configuracion.html",
    "detalle-enfocado": "unidad-enfocada.html",
}

HEAD = """<!DOCTYPE html>
<html class="dark" lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="theme-color" content="#0b1326">
  <title>{title}</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Chivo:wght@600;700&family=Geist:wght@400;500;600;700&family=JetBrains+Mono:wght@500;700&display=swap" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="stitch.css">
</head>
<body class="bg-background font-body-md text-body-md text-on-surface antialiased" data-page="{page}">
"""
TAIL = """<script src="app.js"></script>
</body>
</html>
"""

ACTIVE_HEADER = ("px-space-md py-space-xs transition-colors bg-primary-container "
                 "text-on-primary-container font-semibold rounded-lg")
IDLE_HEADER = ("px-space-md py-space-xs font-body-md text-body-md text-on-surface-variant "
               "hover:bg-surface-container-high hover:text-on-surface transition-colors rounded-lg")
ACTIVE_ASIDE = ("flex items-center gap-space-sm px-space-md py-space-sm rounded-lg "
                "transition-colors bg-surface-container-high text-primary font-semibold")
IDLE_ASIDE = ("flex items-center gap-space-sm px-space-md py-space-sm rounded-lg "
              "text-on-surface-variant hover:bg-surface-container-high hover:text-on-surface transition-colors")


def body_inner(html):
    m = re.search(r"<body[^>]*>(.*)</body>", html, re.S)
    return m.group(1)


def body_class(html):
    m = re.search(r"<body([^>]*)>", html)
    attrs = m.group(1)
    c = re.search(r'class="([^"]*)"', attrs)
    return c.group(1) if c else "bg-background font-body-md text-body-md text-on-surface antialiased"


def fix_nav(body, page):
    def repl(m):
        tag = m.group(0)
        dp = re.search(r'data-path="([^"]+)"', tag).group(1)
        href = ROUTES.get(dp, "#")
        zone = "header" if "py-space-xs" in tag else "aside"
        active = dp == page
        if zone == "header":
            klass = ACTIVE_HEADER if active else IDLE_HEADER
        else:
            klass = ACTIVE_ASIDE if active else IDLE_ASIDE
        tag = re.sub(r'class="[^"]*"', 'class="%s"' % klass, tag, count=1)
        tag = re.sub(r'\s*aria-current="[^"]*"', "", tag)
        if active:
            tag = tag.replace("<a ", '<a aria-current="page" ', 1)
        tag = re.sub(r'href="[^"]*"', 'href="%s"' % href, tag, count=1)
        return tag

    return re.sub(r"<a\b[^>]*data-path=\"[^\"]+\"[^>]*>", repl, body)


def drop_logo(body):
    return re.sub(r'<img[^>]*alt="AeroCargo Logo"[^>]*/>',
                  '<span class="material-symbols-outlined text-primary" style="font-size:28px;">flight</span>',
                  body)


def add_id_nearest(body, anchor_re, id_name, tag="div"):
    """Añade id a la primera etiqueta que coincide con anchor_re."""
    return re.sub(anchor_re, lambda m: m.group(0).replace("<%s " % tag, '<%s id="%s" ' % (tag, id_name), 1),
                  body, count=1)


def strip_inline_scripts(body):
    """Elimina los <script> embebidos de la maqueta: app.js reimplementa sus
    interacciones sobre datos reales (evita closures con nodos obsoletos)."""
    return re.sub(r"<script(?![^>]*\bsrc=)[^>]*>.*?</script>", "", body, flags=re.S)


def hooks_monitoreo(body):
    body = re.sub(r'<tbody class="divide-y divide-surface-container font-body-sm text-body-sm text-on-surface">',
                  '<tbody id="fleetBody" class="divide-y divide-surface-container font-body-sm text-body-sm text-on-surface">',
                  body)
    # capa dinámica de marcadores: fuera los pines, waypoints y rutas de muestra
    body = re.sub(r"<!-- PIN FLOTANTE.*?(?=<!-- Overlay HUD)", "", body, flags=re.S)
    body = re.sub(r"<!-- WAYPOINTS NODALES -->.*?(?=<!-- Overlay HUD)", "", body, flags=re.S)
    body = re.sub(r"<path\b[^>]*>\s*</path>", "", body)
    body = body.replace(
        '<div class="absolute inset-0 bg-[radial-gradient(#1f2e4d_1px,transparent_1px)]',
        '<div id="mapPins" class="absolute inset-0 pointer-events-none z-10"></div>\n'
        '<div class="absolute inset-0 bg-[radial-gradient(#1f2e4d_1px,transparent_1px)]',
        1)
    # subtextos de los KPI
    body = body.replace("<span>Aeronaves: 19</span>",
                        '<span>Aeronaves: <span id="kpiAereas">15</span></span>')
    body = body.replace("<span>Tierra: 9</span>",
                        '<span>Tierra: <span id="kpiTierra">0</span></span>')
    body = body.replace("<span>Retraso prom: +38 min</span>",
                        '<span>Retraso prom: <span id="kpiRetraso">0</span> min</span>')
    body = body.replace("<span>318.4 Tons</span>", '<span id="kpiTonelaje">318.4 Tons</span>')
    body = re.sub(r'(<input[^>]*placeholder="Buscar por ID[^"]*"[^>]*)>',
                  lambda m: m.group(1).replace("<input ", '<input id="fleetSearch" ', 1) + ">", body)
    body = body.replace('<div class="relative w-full h-[520px] bg-[#070e1c] overflow-hidden select-none">',
                        '<div id="mapCanvas" class="relative w-full h-[520px] bg-[#070e1c] overflow-hidden select-none">')
    body = re.sub(r'<div>(Mostrando 5 de 35[^<]*)</div>', r'<div id="fleetPager">\1</div>', body)
    # KPIs: los cuatro números grandes, en orden
    kpis = ["kpiEnRuta", "kpiAlertas", "kpiCriticos", "kpiEntregas"]
    idx = {"i": 0}

    def kpi_repl(m):
        i = idx["i"]
        idx["i"] += 1
        if i < len(kpis):
            return m.group(0).replace("<span ", '<span id="%s" ' % kpis[i], 1)
        return m.group(0)
    body = re.sub(r'<span class="font-headline-xl text-headline-xl[^"]*">[^<]*</span>', kpi_repl, body)
    # leyenda del mapa
    body = body.replace("<span>Nominal (28)</span>", '<span>Nominal (<span id="legendOk">28</span>)</span>')
    body = body.replace("<span>Demora (5)</span>", '<span>Demora (<span id="legendAlert">5</span>)</span>')
    body = body.replace("<span>Crítico (2)</span>", '<span>Crítico (<span id="legendCrit">2</span>)</span>')
    return body


def ids_cabecera(body):
    """Los badges del header vienen de la maqueta con cifras fijas (42/98.4%/3).
    app.js los reescribe por SSE si llevan id; en la maqueta no existen."""
    for texto, ident in (("Operatividad 98.4%", "hdrOperatividad"),
                         ("42 Unidades Activas", "hdrUnidades"),
                         ("3 Alertas", "hdrAlertas")):
        body = body.replace('uppercase">%s</span>' % texto,
                            'uppercase"><span id="%s">%s</span></span>' % (ident, texto))
    return body


def hooks_historial(body):
    body = body.replace('<div class="space-y-space-md" id="events-container">',
                        '<div class="space-y-space-md" id="events-container">')
    # contadores de los filtros
    for status, cid in (("all", "countAll"), ("ok", "countOk"),
                        ("alert", "countAlert"), ("error", "countError")):
        pat = re.compile(r'(<button[^>]*data-filter-status="%s"[^>]*>.*?)<span class="px-1\.5 py-0\.2[^"]*">(\d+)</span>' % status, re.S)
        body = pat.sub(lambda m: m.group(1) + '<span id="%s" class="px-1.5 py-0.2 rounded-full bg-surface font-bold">%s</span>' % (cid, m.group(2)), body, count=1)
    body = re.sub(r'(<span class="font-label-code text-label-code text-secondary font-bold">)[^<]*(</span>)',
                  r'\1<span id="syncTime">14:14:52 UTC</span> · En Línea\2', body, count=1)
    return body


def hooks_unidad(body):
    body = body.replace(">AC-702 (HK-5491)<", '><span id="unitBreadcrumb">AC-702 (HK-5491)</span><')
    body = body.replace('<span class="font-headline-lg text-headline-lg text-on-surface tracking-wide">Boeing 767-300F</span>',
                        '<span id="unitTipo" class="font-headline-lg text-headline-lg text-on-surface tracking-wide">Boeing 767-300F</span>')
    body = body.replace('bg-surface-container-high text-primary rounded">HK-5491</span>',
                        'bg-surface-container-high text-primary rounded"><span id="unitMatricula">HK-5491</span></span>')
    # telemetría del encabezado
    body = body.replace('<div class="mt-1 font-telemetry-metric text-telemetry-metric text-secondary">72%</div>',
                        '<div id="unitFuel" class="mt-1 font-telemetry-metric text-telemetry-metric text-secondary">72%</div>')
    body = body.replace('<div class="bg-secondary h-full rounded-full" style="width: 72%;">',
                        '<div id="unitFuelBar" class="bg-secondary h-full rounded-full" style="width: 72%;">')
    body = body.replace('<span class="font-label-sm text-label-sm text-outline mt-1 block">3h 25m remanente</span>',
                        '<span id="unitFuelSub" class="font-label-sm text-label-sm text-outline mt-1 block">3h 25m remanente</span>')
    body = body.replace('<div class="mt-1 font-telemetry-metric text-telemetry-metric text-primary">FL310</div>',
                        '<div id="unitFl" class="mt-1 font-telemetry-metric text-telemetry-metric text-primary">FL310</div>')
    body = body.replace('<span class="font-label-sm text-label-sm text-outline mt-1 block">31,000 ft AMSL</span>',
                        '<span id="unitFlSub" class="font-label-sm text-label-sm text-outline mt-1 block">31,000 ft AMSL</span>')
    body = body.replace('<div class="mt-1 font-telemetry-metric text-telemetry-metric text-on-surface">M 0.78</div>',
                        '<div id="unitSpeed" class="mt-1 font-telemetry-metric text-telemetry-metric text-on-surface">M 0.78</div>')
    body = body.replace('<div class="font-body-sm text-body-sm text-on-surface-variant mt-2">452 kts GS</div>',
                        '<div id="unitSpeedSub" class="font-body-sm text-body-sm text-on-surface-variant mt-2">452 kts GS</div>')
    body = body.replace('<div class="mt-1 font-telemetry-metric text-telemetry-metric text-on-surface">38.4 t</div>',
                        '<div id="unitLoad" class="mt-1 font-telemetry-metric text-telemetry-metric text-on-surface">38.4 t</div>')
    body = body.replace('<div class="bg-primary-container h-full rounded-full" style="width: 84%;">',
                        '<div id="unitLoadBar" class="bg-primary-container h-full rounded-full" style="width: 84%;">')
    body = body.replace('Ruta: <strong class="text-on-surface font-medium">MIA → MDE (Ruta Troncal Andina)</strong>',
                        'Ruta: <strong id="unitRuta" class="text-on-surface font-medium">MIA → MDE (Ruta Troncal Andina)</strong>')
    body = body.replace('ETA Original: <strong class="text-on-surface font-medium">18:15 UTC</strong>',
                        'ETA Original: <strong id="unitEta" class="text-on-surface font-medium">18:15 UTC</strong>')
    return body


def hooks_enfocada(body):
    body = body.replace('>\n              AC-702\n            </h1>',
                        '>\n              <span id="unitVuelo">AC-702</span>\n            </h1>')
    body = body.replace('HK-5491 · B767-300F', '<span id="unitTipo">HK-5491 · B767-300F</span>')
    return body


HOOKS = {
    "monitoreo-en-vivo": hooks_monitoreo,
    "bitacora-y-alertas": hooks_historial,
    "detalle-de-unidad-y-reasignacion": hooks_unidad,
    "detalle-enfocado": hooks_enfocada,
}


CONFIG_PAGE = """
<main class="w-full pt-16 bg-surface min-h-screen">
    <div class="flex flex-col w-full space-y-space-md p-gutter-desktop max-w-[1720px] mx-auto">
      <div class="bg-surface-container-low p-space-lg rounded-xl shadow-md">
        <h1 class="font-headline-lg text-headline-lg text-on-surface tracking-tight">Configuración de Flota</h1>
        <p class="font-body-sm text-body-sm text-on-surface-variant mt-1">Parámetros de la jornada simulada leídos de <code class="font-label-code text-label-code text-primary">config/sys.config</code>.</p>
      </div>
      <div class="bg-surface-container-low rounded-xl shadow-md p-space-lg">
        <table class="w-full text-left border-collapse">
          <thead><tr class="bg-surface-container text-on-surface-variant font-label-badge text-label-badge uppercase tracking-wider"><th class="py-space-sm px-space-md">Parámetro</th><th class="py-space-sm px-space-md">Valor</th></tr></thead>
          <tbody class="divide-y divide-surface-container font-body-sm text-body-sm">
            <tr><td class="py-space-sm px-space-md font-label-code text-label-code text-on-surface">tick_interval_ms</td><td class="py-space-sm px-space-md font-telemetry-metric text-primary">33</td></tr>
            <tr><td class="py-space-sm px-space-md font-label-code text-label-code text-on-surface">ticks_jornada</td><td class="py-space-sm px-space-md font-telemetry-metric text-primary">2160</td></tr>
            <tr><td class="py-space-sm px-space-md font-label-code text-label-code text-on-surface">aeronaves</td><td class="py-space-sm px-space-md font-telemetry-metric text-primary">15</td></tr>
            <tr><td class="py-space-sm px-space-md font-label-code text-label-code text-on-surface">envios</td><td class="py-space-sm px-space-md font-telemetry-metric text-primary">900</td></tr>
            <tr><td class="py-space-sm px-space-md font-label-code text-label-code text-on-surface">ticks_por_parada</td><td class="py-space-sm px-space-md font-telemetry-metric text-primary">36</td></tr>
            <tr><td class="py-space-sm px-space-md font-label-code text-label-code text-on-surface">sin_senal_ticks</td><td class="py-space-sm px-space-md font-telemetry-metric text-primary">6</td></tr>
            <tr><td class="py-space-sm px-space-md font-label-code text-label-code text-on-surface">prob_fallida</td><td class="py-space-sm px-space-md font-telemetry-metric text-primary">0.10</td></tr>
            <tr><td class="py-space-sm px-space-md font-label-code text-label-code text-on-surface">web_port</td><td class="py-space-sm px-space-md font-telemetry-metric text-primary">8080</td></tr>
          </tbody>
        </table>
      </div>
      <div class="bg-surface-container-low rounded-xl shadow-md p-space-lg font-body-sm text-body-sm text-on-surface-variant">
        <p><strong class="text-on-surface">Acciones de caos</strong> (API del despachador): <code class="font-label-code text-primary">POST /api/averiar</code> con <code class="font-label-code">{"aeronave": N}</code> y <code class="font-label-code">POST /api/urgente</code> para un envío AOG.</p>
        <p class="mt-2">Estado en vivo: <code class="font-label-code text-primary">GET /api/estado</code>, <code class="font-label-code text-primary">GET /api/aeronaves</code>, <code class="font-label-code text-primary">GET /api/envios</code>, SSE <code class="font-label-code text-primary">GET /eventos</code>.</p>
      </div>
    </div>
  </main>
"""


def build_config(dash_html):
    """Usa el armazón (header+aside) del dashboard y cambia solo el <main>."""
    body = body_inner(dash_html)
    body = drop_logo(body)
    body = fix_nav(body, "configuracion-de-flota")
    body = ids_cabecera(body)
    principal = re.search(r"<main\b.*?</main>", body, re.S)
    nueva = re.search(r"<main\b.*?</main>", CONFIG_PAGE, re.S)
    body = body.replace(principal.group(0), nueva.group(0))
    classes = body_class(dash_html)
    head = HEAD.format(title="AeroCargo · Configuración de Flota", page="configuracion")
    head = re.sub(r'<body class="[^"]*"', '<body class="%s"' % classes, head, count=1)
    return head + body + TAIL


def main():
    dash_html = None
    for page, (folder, out, title) in PAGES.items():
        src = BASE / folder / "code.html"
        html = src.read_text(encoding="utf-8")
        classes = body_class(html)
        if page == "monitoreo-en-vivo":
            dash_html = html
        body = body_inner(html)
        body = drop_logo(body)
        body = fix_nav(body, page)
        body = ids_cabecera(body)
        body = HOOKS[page](body)
        if page in ("monitoreo-en-vivo", "bitacora-y-alertas"):
            body = strip_inline_scripts(body)
        out_html = HEAD.format(title=title, page=page).replace(
            '<body class="bg-background font-body-md text-body-md text-on-surface antialiased"',
            '<body class="%s"' % classes, 1) + body + TAIL
        (OUT / out).write_text(out_html, encoding="utf-8")
        print(f"{out}: {len(out_html)} bytes")
    (OUT / "configuracion.html").write_text(build_config(dash_html), encoding="utf-8")
    print("configuracion.html: ok")


if __name__ == "__main__":
    main()
