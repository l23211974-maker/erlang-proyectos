"""Genera priv/static/stitch.css a partir de las clases Tailwind usadas en las
maquetas de Stitch (gestor de flotilla AeroCargo). Sin CDN: el CSS resultante
implementa solo el vocabulario realmente usado, con los tokens del DESIGN.md.
"""
import re, pathlib, collections, sys

BASE = pathlib.Path(r"C:\Users\Max\Downloads\stitch_gestor_de_flotilla_a_rea_extracted\stitch_gestor_de_flotilla_a_rea")
OUT = pathlib.Path(r"C:\Users\Max\dev\erlang-proyectos\proyectos\29-flotilla-de-reparto\priv\static\stitch.css")

# ---- tokens -----------------------------------------------------------------
COLORS = {
    "on-primary": "#003351", "primary": "#93ccff", "primary-container": "#3198dc",
    "on-primary-container": "#002c47", "primary-fixed": "#cce5ff",
    "primary-fixed-dim": "#93ccff", "on-primary-fixed": "#001d31",
    "on-primary-fixed-variant": "#004b73", "inverse-primary": "#006398",
    "secondary": "#4edea3", "on-secondary": "#003824", "secondary-container": "#00a572",
    "on-secondary-container": "#00311f", "secondary-fixed": "#6ffbbe",
    "secondary-fixed-dim": "#4edea3", "on-secondary-fixed": "#002113",
    "on-secondary-fixed-variant": "#005236",
    "tertiary": "#ffb95f", "on-tertiary": "#472a00", "tertiary-container": "#ca8100",
    "on-tertiary-container": "#3e2400", "tertiary-fixed": "#ffddb8",
    "tertiary-fixed-dim": "#ffb95f", "on-tertiary-fixed": "#2a1700",
    "on-tertiary-fixed-variant": "#653e00",
    "error": "#ffb4ab", "on-error": "#690005", "error-container": "#93000a",
    "on-error-container": "#ffdad6",
    "surface": "#0b1326", "surface-dim": "#0b1326", "surface-bright": "#31394d",
    "surface-container-lowest": "#060e20", "surface-container-low": "#131b2e",
    "surface-container": "#171f33", "surface-container-high": "#222a3d",
    "surface-container-highest": "#2d3449", "on-surface": "#dae2fd",
    "on-surface-variant": "#bfc7d2", "inverse-surface": "#dae2fd",
    "inverse-on-surface": "#283044", "surface-tint": "#93ccff",
    "surface-variant": "#2d3449",
    "outline": "#89929b", "outline-variant": "#3f4850",
    "background": "#0b1326", "on-background": "#dae2fd",
}
# alias del sistema "glass" usado por las pantallas nuevas
COLORS.update({
    "accent": COLORS["primary"],
    "danger": COLORS["error"],
    "warning": COLORS["tertiary"],
    "canvas": "#0b1120",
    "text": COLORS["on-surface"],
    "subtle": COLORS["on-surface-variant"],
    "muted": COLORS["outline"],
    "panel-solid": COLORS["surface-container"],
    "glass-stroke": "rgba(255,255,255,0.08)",
    "white": "#ffffff",
})

SPACE = {
    "space-xs": "0.25rem", "space-sm": "0.5rem", "space-md": "0.75rem",
    "space-lg": "1.25rem", "space-xl": "1.75rem",
    "gutter": "1rem", "gutter-desktop": "1.25rem",
    "margin": "1rem", "margin-desktop": "1.5rem",
}
# escala Tailwind (rem)
SCALE = {
    "0": "0", "0.5": "0.125rem", "0.2": "0.05rem", "1": "0.25rem", "1.5": "0.375rem",
    "2": "0.5rem", "2.5": "0.625rem", "3": "0.75rem", "3.5": "0.875rem", "4": "1rem",
    "5": "1.25rem", "6": "1.5rem", "7": "1.75rem", "8": "2rem", "9": "2.25rem",
    "10": "2.5rem", "11": "2.75rem", "12": "3rem", "14": "3.5rem", "16": "4rem",
    "20": "5rem", "24": "6rem", "28": "7rem", "32": "8rem", "36": "9rem",
    "40": "10rem", "44": "11rem", "48": "12rem", "52": "13rem", "56": "14rem",
    "60": "15rem", "64": "16rem", "72": "18rem", "80": "20rem", "96": "24rem",
    "px": "1px", "full": "100%", "auto": "auto", "screen": "100vh",
}
RADIUS = {"": "0.125rem", "sm": "0.125rem", "md": "0.375rem", "lg": "0.25rem",
          "xl": "0.5rem", "2xl": "1rem", "3xl": "1.5rem", "full": "0.75rem"}

TYPO = {
    "headline-xl": ("Chivo", "36px", "700", "44px"),
    "headline-xl-mobile": ("Chivo", "26px", "700", "32px"),
    "headline-lg": ("Chivo", "28px", "600", "36px"),
    "headline-md": ("Chivo", "20px", "600", "28px"),
    "headline-sm": ("Chivo", "16px", "600", "24px"),
    "body-lg": ("Geist", "16px", "400", "24px"),
    "body-md": ("Geist", "14px", "400", "20px"),
    "body-sm": ("Geist", "12px", "400", "16px"),
    "telemetry-metric": ("JetBrains Mono", "22px", "700", "26px"),
    "label-code": ("JetBrains Mono", "12px", "500", "16px"),
    "label-badge": ("JetBrains Mono", "11px", "700", "14px"),
    "label-sm": ("Geist", "11px", "500", "14px"),
}
FAMILY = {"display": "Chivo", "sans": "Geist", "mono": "JetBrains Mono"}
WEIGHT = {"bold": "700", "semibold": "600", "medium": "500", "normal": "400"}


def hex_rgba(h, a):
    h = h.lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
    return f"rgba({r},{g},{b},{a})"


def alpha_value(a):
    """Tailwind usa /90 = 90 % de opacidad, no 90.0."""
    f = float(a)
    return f / 100 if f > 1 else f


def color_value(name, alpha=None):
    """Devuelve valor CSS para un nombre de color + alpha opcional."""
    if name not in COLORS:
        return None
    v = COLORS[name]
    if alpha is None:
        return v
    if v.startswith("rgba(") or v.startswith("rgb("):
        return v
    return hex_rgba(v, alpha)


def size_value(tok):
    if tok in SPACE:
        return SPACE[tok]
    if tok in SCALE:
        return SCALE[tok]
    return None


def cls_to_css(cls):
    """Devuelve (selector_sufijo, declaraciones) o None si no se reconoce."""
    variants = []
    rest = cls
    if not rest.startswith("[") and ":" in rest:
        while ":" in rest:
            v, _, rest = rest.partition(":")
            variants.append(v)
    vsel = {
        "hover": ":hover", "focus": ":focus", "active": ":active",
        "group-hover": None, "selection": None, "placeholder": None,
    }
    decls = None
    sel = ""
    u = rest

    # ---- valores negativos de posicion -----------------------------------
    m = re.fullmatch(r"-(top|left|right|bottom)-(.+)", u)
    if m:
        val = size_value(m.group(2))
        if val:
            return ("arb", f"{{ {m.group(1)}: -{val}; }}")

    # ---- utilidades ya definidas en el bloque de componentes ---------------
    if u in ("accent-primary", "action-btn", "active", "beacon-dot", "dark", "event-card",
             "filter", "filter-status-btn", "glass-card", "group", "material-symbols-outlined",
             "placeholder-muted", "plane-node", "radar-pulse-ring", "radar-sweep", "range-btn",
             "divide-y", "divide-surface-container", "from-surface-container-lowest",
             "to-transparent", "via-transparent", "bg-gradient-to-t", "py-"):
        return ("noop", "")

    # ---- arbitrary values -------------------------------------------------
    m = re.fullmatch(r"\[([a-z-]+):(.+)\]", u)
    if m:
        prop, val = m.group(1), m.group(2).replace("_", " ")
        if prop == "background-size":
            return ("bg-size", f"{{ background-size: {val}; }}")
        return ("arb", f"{{ {prop}: {val}; }}")

    m = re.fullmatch(r"(bg|text|w|h|max-w|min-w|max-h|left|top|right|bottom|shadow|border)-\[(.+)\]", u)
    if m:
        kind, val = m.group(1), m.group(2).replace("_", " ")
        if "/" in val and val.startswith("0"):
            pass
        props = {
            "bg": "background-color", "text": "color", "w": "width", "h": "height",
            "max-w": "max-width", "min-w": "min-width", "max-h": "max-height",
            "left": "left", "top": "top", "right": "right", "bottom": "bottom",
            "shadow": "box-shadow", "border": "border-color",
        }
        if kind == "text" and val.endswith(("px", "rem", "em")):
            props["text"] = "font-size"
        if val.startswith("radial-gradient") or val.startswith("linear-gradient"):
            props["bg"] = "background-image"
        if kind == "border" and val.startswith("white"):
            return ("arb", f"{{ border-color: {val}; }}")
        return ("arb", f"{{ {props.get(kind, 'all')}: {val}; }}")

    # ---- bg ---------------------------------------------------------------
    m = re.fullmatch(r"bg-(.+)", u)
    if m:
        t = m.group(1)
        if t == "transparent":
            return ("arb", "{ background-color: transparent; }")
        if t == "gradient-to-t":
            return ("arb", "{ background-image: linear-gradient(to top, var(--tw-from, transparent), var(--tw-via, transparent), var(--tw-to, transparent)); }")
        alpha = None
        if "/" in t:
            base, _, a = t.partition("/")
            a = a.strip("[]")
            alpha = alpha_value(a) if a.replace(".", "").isdigit() else None
            t = base
        v = color_value(t, alpha)
        if v:
            return ("arb", f"{{ background-color: {v}; }}")

    # ---- text -------------------------------------------------------------
    m = re.fullmatch(r"text-(.+)", u)
    if m:
        t = m.group(1)
        if t in TYPO:
            fam, size, w, lh = TYPO[t]
            return ("arb", f"{{ font-family: '{fam}', sans-serif; font-size: {size}; font-weight: {w}; line-height: {lh}; }}")
        if t in ("left", "center", "right"):
            return ("arb", f"{{ text-align: {t}; }}")
        sizes = {"xs": "12px", "sm": "14px", "base": "16px", "lg": "18px", "xl": "20px",
                 "2xl": "24px", "3xl": "30px"}
        if t in sizes:
            return ("arb", f"{{ font-size: {sizes[t]}; }}")
        alpha = None
        if "/" in t:
            base, _, a = t.partition("/")
            a = a.strip("[]")
            alpha = alpha_value(a) if a.replace(".", "").isdigit() else None
            t = base
        v = color_value(t, alpha)
        if v:
            return ("arb", f"{{ color: {v}; }}")
        if t == "white":
            return ("arb", "{ color: #fff; }")

    # ---- font family / weight ---------------------------------------------
    m = re.fullmatch(r"font-(.+)", u)
    if m:
        t = m.group(1)
        if t in TYPO:
            fam, size, w, lh = TYPO[t]
            return ("arb", f"{{ font-family: '{fam}', sans-serif; font-size: {size}; font-weight: {w}; line-height: {lh}; }}")
        if t in FAMILY:
            return ("arb", f"{{ font-family: '{FAMILY[t]}', sans-serif; }}")
        if t in WEIGHT:
            return ("arb", f"{{ font-weight: {WEIGHT[t]}; }}")

    # ---- border -----------------------------------------------------------
    if u == "border":
        return ("arb", "{ border-width: 1px; border-style: solid; }")
    if u in ("border-t-0", "border-b-0", "border-l-0", "border-r-0"):
        return ("arb", f"{{ border-{u[7]}-width: 0; }}")
    if u == "hover:underline":
        return ("arb", "")
    if u == "underline":
        return ("arb", "{ text-decoration: underline; }")
    if u in ("border-b", "border-t", "border-l", "border-r"):
        side = u[-1]
        return ("arb", f"{{ border-{side}-width: 1px; border-{side}-style: solid; }}")
    if u == "border-collapse":
        return ("arb", "{ border-collapse: collapse; }")
    m = re.fullmatch(r"border-(.+)", u)
    if m:
        t = m.group(1)
        alpha = None
        if "/" in t:
            base, _, a = t.partition("/")
            a = a.strip("[]")
            alpha = alpha_value(a) if a.replace(".", "").isdigit() else None
            t = base
        v = color_value(t, alpha)
        if v:
            return ("arb", f"{{ border-color: {v}; }}")
        if t == "white":
            return ("arb", "{ border-color: #fff; }")

    # ---- rounded ----------------------------------------------------------
    m = re.fullmatch(r"rounded(?:-(.+))?", u)
    if m and (m.group(1) or "") in RADIUS:
        r = RADIUS[m.group(1) or ""]
        return ("arb", f"{{ border-radius: {r}; }}")

    # ---- spacing ----------------------------------------------------------
    m = re.fullmatch(r"(p|px|py|pt|pb|pl|pr|m|mx|my|mt|mb|ml|mr|gap-x|gap-y|gap)-(.+)", u)
    if m:
        kind, tok = m.group(1), m.group(2)
        val = size_value(tok)
        if val is None:
            return None
        prop = {"p": "padding", "px": "padding-inline", "py": "padding-block",
                "pt": "padding-top", "pb": "padding-bottom", "pl": "padding-left",
                "pr": "padding-right", "m": "margin", "mx": "margin-inline",
                "my": "margin-block", "mt": "margin-top", "mb": "margin-bottom",
                "ml": "margin-left", "mr": "margin-right",
                "gap": "gap", "gap-x": "column-gap", "gap-y": "row-gap"}[kind]
        return ("arb", f"{{ {prop}: {val}; }}")

    m = re.fullmatch(r"space-y-(.+)", u)
    if m:
        val = size_value(m.group(1))
        if val:
            return ("arb", f"{{ --tw-space-y: {val}; }}")
    if u == "space-sm":
        return ("arb", "{ --tw-space-sm: 0.5rem; }")

    # ---- size -------------------------------------------------------------
    m = re.fullmatch(r"(w|h|max-w|min-w|max-h|min-h)-(.+)", u)
    if m:
        kind, tok = m.group(1), m.group(2)
        named = {"xs": "20rem", "sm": "24rem", "md": "28rem", "lg": "32rem",
                 "xl": "36rem", "2xl": "42rem", "3xl": "48rem", "4xl": "56rem",
                 "5xl": "64rem", "6xl": "72rem", "7xl": "80rem"}
        val = size_value(tok)
        if val is None and kind.startswith("max") and tok in named:
            val = named[tok]
        if val is None:
            return None
        prop = {"w": "width", "h": "height", "max-w": "max-width", "min-w": "min-width",
                "max-h": "max-height", "min-h": "min-height"}[kind]
        return ("arb", f"{{ {prop}: {val}; }}")

    # ---- posicionamiento --------------------------------------------------
    m = re.fullmatch(r"(top|left|right|bottom|inset|z)-(.+)", u)
    if m:
        kind, tok = m.group(1), m.group(2)
        if kind == "z":
            return ("arb", f"{{ z-index: {tok}; }}")
        if u == "inset-0":
            return ("arb", "{ inset: 0; }")
        if u == "inset-y-0":
            return ("arb", "{ top: 0; bottom: 0; }")
        val = size_value(tok)
        if val is None and re.fullmatch(r"\d+/\d+", tok):
            a, b = tok.split("/")
            val = f"{int(a) / int(b) * 100:.4f}%"
        if val:
            return ("arb", f"{{ {kind}: {val}; }}")

    m = re.fullmatch(r"(-?)(translate-[xy])-(.+)", u)
    if m:
        sign, axis, tok = m.groups()
        if re.fullmatch(r"\d+/\d+", tok):
            a, b = tok.split("/")
            val = f"{int(a) / int(b) * 100:.4f}%"
        else:
            val = size_value(tok)
        if val:
            if axis == "translate-x":
                return ("arb", f"{{ translate: {sign}{val} 0; }}")
            return ("arb", f"{{ translate: 0 {sign}{val}; }}")

    m = re.fullmatch(r"(-?)rotate-(.+)", u)
    if m:
        sign, tok = m.groups()
        return ("arb", f"{{ rotate: {sign}{tok}deg; }}")

    m = re.fullmatch(r"scale-(.+)", u)
    if m:
        return ("arb", f"{{ scale: {m.group(1).strip('[]')}; }}")

    # ---- grid / flex ------------------------------------------------------
    m = re.fullmatch(r"grid-cols-(\d+)", u)
    if m:
        n = m.group(1)
        return ("arb", f"{{ grid-template-columns: repeat({n}, minmax(0, 1fr)); }}")
    m = re.fullmatch(r"col-span-(\d+)", u)
    if m:
        return ("arb", f"{{ grid-column: span {m.group(1)} / span {m.group(1)}; }}")
    if u in ("flex", "inline-flex", "grid", "block", "hidden", "inline", "table"):
        return ("arb", f"{{ display: {u}; }}")
    if u in ("flex-col", "flex-row", "flex-wrap", "flex-nowrap", "flex-initial"):
        prop = {"flex-col": "flex-direction: column;", "flex-row": "flex-direction: row;",
                "flex-wrap": "flex-wrap: wrap;", "flex-nowrap": "flex-wrap: nowrap;",
                "flex-initial": "flex: 0 1 auto;"}[u]
        return ("arb", "{ " + prop + " }")
    if u == "flex-1":
        return ("arb", "{ flex: 1 1 0%; }")
    if u == "shrink-0":
        return ("arb", "{ flex-shrink: 0; }")
    if u == "min-w-0":
        return ("arb", "{ min-width: 0; }")
    m = re.fullmatch(r"items-(.+)", u)
    if m:
        return ("arb", f"{{ align-items: {m.group(1)}; }}")
    m = re.fullmatch(r"justify-(.+)", u)
    if m:
        return ("arb", f"{{ justify-content: {m.group(1)}; }}")
    m = re.fullmatch(r"self-(.+)", u)
    if m:
        return ("arb", f"{{ align-self: {m.group(1)}; }}")
    if u == "mx-auto":
        return ("arb", "{ margin-inline: auto; }")

    # ---- posicion / display simple ---------------------------------------
    if u in ("relative", "absolute", "fixed", "sticky", "static"):
        return ("arb", f"{{ position: {u}; }}")
    if u in ("overflow-hidden", "overflow-x-auto", "overflow-y-auto", "overflow-auto"):
        prop = {"overflow-hidden": "overflow: hidden;", "overflow-x-auto": "overflow-x: auto;",
                "overflow-y-auto": "overflow-y: auto;", "overflow-auto": "overflow: auto;"}[u]
        return ("arb", "{ " + prop + " }")
    if u in ("pointer-events-none", "pointer-events-auto"):
        return ("arb", f"{{ pointer-events: {'none' if u.endswith('none') else 'auto'}; }}")
    if u == "cursor-pointer":
        return ("arb", "{ cursor: pointer; }")
    if u == "select-none":
        return ("arb", "{ user-select: none; }")
    if u == "truncate":
        return ("arb", "{ overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }")
    if u == "uppercase":
        return ("arb", "{ text-transform: uppercase; }")
    if u == "antialiased":
        return ("arb", "{ -webkit-font-smoothing: antialiased; }")
    if u == "appearance-none":
        return ("arb", "{ appearance: none; }")
    if u == "outline-none":
        return ("arb", "{ outline: none; }")
    if u == "select-none":
        return ("arb", "{ user-select: none; }")
    m = re.fullmatch(r"tracking-(.+)", u)
    if m:
        v = {"tighter": "-0.05em", "tight": "-0.025em", "normal": "0",
             "wide": "0.025em", "wider": "0.05em", "widest": "0.1em"}.get(m.group(1), m.group(1))
        return ("arb", f"{{ letter-spacing: {v}; }}")
    m = re.fullmatch(r"leading-(.+)", u)
    if m:
        v = {"none": "1", "tight": "1.25", "snug": "1.375", "normal": "1.5",
             "relaxed": "1.625", "loose": "2"}.get(m.group(1), m.group(1))
        return ("arb", f"{{ line-height: {v}; }}")
    m = re.fullmatch(r"opacity-(.+)", u)
    if m:
        return ("arb", f"{{ opacity: {int(m.group(1)) / 100}; }}")
    if u == "grayscale":
        return ("arb", "{ filter: grayscale(100%); }")
    m = re.fullmatch(r"contrast-(\d+)", u)
    if m:
        return ("arb", f"{{ filter: contrast({int(m.group(1)) / 100}); }}")
    if u == "mix-blend-luminosity":
        return ("arb", "{ mix-blend-mode: luminosity; }")
    m = re.fullmatch(r"object-(.+)", u)
    if m:
        return ("arb", f"{{ object-fit: {m.group(1)}; }}")
    m = re.fullmatch(r"bg-(cover|center)", u)
    if m:
        prop = "background-size" if m.group(1) == "cover" else "background-position"
        val = "cover" if m.group(1) == "cover" else "center"
        return ("arb", f"{{ {prop}: {val}; }}")

    # ---- sombras / blur / ring -------------------------------------------
    m = re.fullmatch(r"shadow-(.+)/([0-9.]+)", u)
    if m:
        v = color_value(m.group(1), alpha_value(m.group(2)))
        if v:
            return ("arb", f"{{ box-shadow: 0 12px 28px -10px {v}; }}")
    shadows = {"sm": "0 1px 2px 0 rgba(0,0,0,.35)",
               "md": "0 4px 6px -1px rgba(0,0,0,.5), 0 2px 4px -2px rgba(0,0,0,.4)",
               "lg": "0 10px 15px -3px rgba(0,0,0,.6), 0 4px 6px -4px rgba(0,0,0,.4)",
               "xl": "0 20px 25px -5px rgba(0,0,0,.65), 0 8px 10px -6px rgba(0,0,0,.4)",
               "2xl": "0 25px 50px -12px rgba(0,0,0,.8)",
               "inner": "inset 0 2px 4px 0 rgba(0,0,0,.45)",
               "": "0 1px 3px 0 rgba(0,0,0,.4)"}
    m = re.fullmatch(r"shadow(?:-(.+))?", u)
    if m and (m.group(1) or "") in shadows:
        return ("arb", f"{{ box-shadow: {shadows[m.group(1) or '']}; }}")
    m = re.fullmatch(r"blur-(.+)", u)
    if m:
        v = {"sm": "4px", "md": "12px", "lg": "16px", "xl": "24px",
             "2xl": "40px", "3xl": "64px"}.get(m.group(1), m.group(1))
        return ("arb", f"{{ filter: blur({v}); }}")
    m = re.fullmatch(r"backdrop-blur(?:-(.+))?", u)
    if m:
        v = {"": "8px", "sm": "4px", "md": "12px", "lg": "16px", "xl": "24px"}.get(m.group(1) or "", m.group(1))
        return ("arb", f"{{ backdrop-filter: blur({v}); }}")
    m = re.fullmatch(r"ring-(\d+)", u)
    if m:
        return ("arb", f"{{ box-shadow: 0 0 0 {int(m.group(1))}px var(--tw-ring-color, rgba(147,204,255,.35)); }}")
    m = re.fullmatch(r"ring-(.+)", u)
    if m:
        a = None
        t = m.group(1)
        if "/" in t:
            t, _, av = t.partition("/")
            a = alpha_value(av)
        v = color_value(t, a)
        if v:
            return ("arb", f"{{ --tw-ring-color: {v}; }}")

    # ---- animaciones / transiciones --------------------------------------
    m = re.fullmatch(r"animate-(.+)", u)
    if m:
        return ("anim", m.group(1))
    m = re.fullmatch(r"transition(?:-(.+))?", u)
    if m:
        v = {"": "all", "all": "all", "colors": "color, background-color, border-color, fill, stroke",
             "transform": "transform", "opacity": "opacity"}.get(m.group(1) or "", "all")
        return ("arb", f"{{ transition-property: {v}; transition-duration: 150ms; transition-timing-function: cubic-bezier(.4,0,.2,1); }}")
    m = re.fullmatch(r"duration-(\d+)", u)
    if m:
        return ("arb", f"{{ transition-duration: {m.group(1)}ms; }}")
    if u == "transform":
        return ("arb", "")

    return None


def esc(cls):
    return re.sub(r"([\[\]\(\)/#:.,%])", r"\\\1", cls)


def build():
    classes = collections.Counter()
    for d in BASE.iterdir():
        c = d / "code.html"
        if not c.exists():
            continue
        t = c.read_text(encoding="utf-8")
        for m in re.findall(r'class="([^"]*)"', t):
            for cl in m.split():
                classes[cl] += 1

    # clases que solo aparecen en JS (app.js / scripts de la maqueta) y que el
    # barrido de atributos class="" no puede ver
    for cl in ("bg-secondary-container/30", "border-primary/40", "hover:border-primary/60",
               "hover:border-accent/60", "hover:border-white/15", "opacity-70",
               "opacity-75", "opacity-100", "translate-y-0", "rotate-180"):
        classes[cl] += 1

    base_rules, hover_rules, focus_rules, group_rules, sel_rules, ph_rules = [], [], [], [], [], []
    media = collections.defaultdict(list)
    unknown = []
    anims = collections.Counter()

    for cls in sorted(classes):
        variants = []
        rest = cls
        while ":" in rest:
            v, _, rest = rest.partition(":")
            variants.append(v)

        res = cls_to_css(cls)
        if res is None:
            unknown.append(cls)
            continue
        kind, payload = res
        if kind == "noop":
            continue
        if kind == "anim":
            anims[payload] += 1
            continue

        rule = f".{esc(cls)}{payload}"
        vset = set(variants)
        if "sm" in vset:
            media["640px"].append(rule)
        elif "md" in vset:
            media["768px"].append(rule)
        elif "lg" in vset:
            media["1024px"].append(rule)
        elif "xl" in vset:
            media["1280px"].append(rule)
        elif "hover" in vset:
            hover_rules.append(f".{esc(cls)}:hover{payload}")
        elif "group-hover" in vset:
            group_rules.append(f".group:hover .{esc(cls)}{payload}")
        elif "focus" in vset:
            focus_rules.append(f".{esc(cls)}:focus{payload}")
        elif "selection" in vset:
            sel_rules.append(f".{esc(cls)}::selection{payload}")
        elif "placeholder" in vset:
            ph_rules.append(f".{esc(cls)}::placeholder{payload}")
        elif "active" in vset:
            hover_rules.append(f".{esc(cls)}:active{payload}")
        else:
            base_rules.append(rule)

    # utilidades compuestas que no son clases Tailwind puras
    extra = """
/* ---- estructura de spacing entre hijos (space-y-*) ------------------------ */
[class*="space-y-"] > * + * { margin-top: var(--tw-space-y, 0); }
[class*="space-y-0.5"] { --tw-space-y: 0.125rem; }
[class*="space-y-1"] { --tw-space-y: 0.25rem; }
[class*="space-y-2"] { --tw-space-y: 0.5rem; }
[class*="space-y-3"] { --tw-space-y: 0.75rem; }
[class*="space-y-4"] { --tw-space-y: 1rem; }
[class*="space-y-6"] { --tw-space-y: 1.5rem; }

/* ---- divide-y ------------------------------------------------------------ */
.divide-y > * + * { border-top-width: 1px; border-top-style: solid; border-color: var(--divide-color, #171f33); }
.divide-surface-container { --divide-color: #171f33; }

/* ---- gradientes from/via/to --------------------------------------------- */
.from-surface-container-lowest { --tw-from: #060e20; }
.to-transparent { --tw-to: transparent; }
.via-transparent { --tw-via: transparent; }
.bg-gradient-to-t { background-image: linear-gradient(to top, var(--tw-from, transparent), var(--tw-via, transparent), var(--tw-to, transparent)); }

/* ---- componentes propios de las maquetas -------------------------------- */
.glass-card { background: rgba(23,31,51,.72); border: 1px solid rgba(255,255,255,.08); backdrop-filter: blur(12px); }
.event-card { border-left: 2px solid transparent; }
.beacon-dot { animation: beacon 1.6s ease-in-out infinite; }
.plane-node { animation: planeFloat 3s ease-in-out infinite; }
.radar-sweep { transform-origin: 340px 175px; animation: sweep 4s linear infinite; }
.radar-pulse-ring { transform-origin: center; animation: radarPulse 2.4s ease-out infinite; }
.animate-route { stroke-dasharray: 900; stroke-dashoffset: 900; animation: routeDash 3.5s ease-out forwards; }
.filter-status-btn { transition: all .15s; }
.range-btn { transition: all .15s; }
.placeholder-muted::placeholder { color: #64748b; }
.accent-primary { accent-color: var(--color-primary); }
.material-symbols-outlined { font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24; line-height: 1; }
.active { }
.group { }

@keyframes beacon { 0%,100% { opacity: 1; } 50% { opacity: .35; } }
@keyframes planeFloat { 0%,100% { transform: translateY(0); } 50% { transform: translateY(-3px); } }
@keyframes sweep { to { transform: rotate(360deg); } }
@keyframes radarPulse { 0% { opacity: .8; transform: scale(.6); } 100% { opacity: 0; transform: scale(1.6); } }
@keyframes routeDash { to { stroke-dashoffset: 0; } }
@keyframes ping { 75%,100% { transform: scale(2); opacity: 0; } }
@keyframes spin { to { transform: rotate(360deg); } }
@keyframes pulse { 50% { opacity: .5; } }
.animate-ping { animation: ping 1s cubic-bezier(0,0,.2,1) infinite; }
.animate-spin { animation: spin 1s linear infinite; }
.animate-pulse { animation: pulse 2s cubic-bezier(.4,0,.6,1) infinite; }
"""

    out = []
    out.append("/* stitch.css — generado por tools/stitch_port/gen_css.py, NO editar a mano.")
    out.append("   Implementa el vocabulario Tailwind de las maquetas Stitch (sin CDN). */\n")
    out.append(":root {")
    for k, v in COLORS.items():
        out.append(f"  --color-{k}: {v};")
    for k, v in SPACE.items():
        out.append(f"  --{k}: {v};")
    out.append("  --radius: 0.125rem;")
    out.append("  --font-display: 'Chivo', sans-serif;")
    out.append("  --font-sans: 'Geist', sans-serif;")
    out.append("  --font-mono: 'JetBrains Mono', monospace;")
    out.append("}\n")
    out.append("*, *::before, *::after { box-sizing: border-box; }")
    out.append("html, body { margin: 0; padding: 0; }")
    out.append("body { background: var(--color-background); color: var(--color-on-surface); font-family: var(--font-sans); }")
    out.append("a { color: inherit; text-decoration: none; }")
    out.append("button { font: inherit; color: inherit; background: none; border: 0; cursor: pointer; }")
    out.append("input, select, textarea { font: inherit; color: inherit; }")
    out.append("::-webkit-scrollbar { width: 8px; height: 8px; }")
    out.append("::-webkit-scrollbar-thumb { background: #2d3449; border-radius: 4px; }")
    out.append("::-webkit-scrollbar-track { background: transparent; }")
    out.append("")
    out.extend(base_rules)
    out.extend(hover_rules)
    out.extend(focus_rules)
    out.extend(group_rules)
    out.extend(sel_rules)
    out.extend(ph_rules)
    out.append(extra)
    for bp in ("640px", "768px", "1024px", "1280px"):
        if media[bp]:
            out.append(f"@media (min-width: {bp}) {{")
            out.extend(media[bp])
            out.append("}")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(out), encoding="utf-8")
    print(f"OK -> {OUT} ({len(out)} lineas)")
    if unknown:
        print("SIN MAPEAR (%d):" % len(unknown))
        print(", ".join(unknown))


if __name__ == "__main__":
    build()
