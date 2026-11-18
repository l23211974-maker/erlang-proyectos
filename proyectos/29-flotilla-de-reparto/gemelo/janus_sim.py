#!/usr/bin/env python3
# janus_sim.py - utilidades Python llamadas desde Prolog via Janus (py_call).
# Genera lecturas simuladas y graficas para el gemelo digital #29.
# Solo usa biblioteca estandar.

import json
import math
import os
import random
import sys
from datetime import datetime


def _ahora_info(ahora_min):
    # Jornada inicia 08:00 (minuto 0 del modelo)
    base = 8 * 60
    total = base + int(ahora_min)
    h = (total // 60) % 24
    m = total % 60
    return f"{h:02d}:{m:02d}"


def lecturas_simuladas(ahora=300, cantidad=8, semilla=29):
    """Genera lecturas GPS/sensor simuladas para las unidades de la flotilla.
    Devuelve una lista de dicts apta para mostrarse o incorporarse como hechos.
    """
    rng = random.Random(int(semilla) + int(ahora))
    unidades = ['u1', 'u2', 'u3', 'u4']
    puntos = ['a_almacen', 'b_norte', 'c_centro', 'd_sur', 'e_este', 'f_oeste', 'g_puente', 'h_cerro']
    lecturas = []
    for i in range(int(cantidad)):
        u = unidades[i % len(unidades)]
        p = rng.choice(puntos)
        minuto = max(0, int(ahora) - rng.randint(0, 40))
        vel = round(rng.uniform(15.0, 55.0), 1)
        motor = 'ok' if (u != 'u3' or minuto < 180) else 'calentado'
        lecturas.append({
            'unidad': u,
            'punto': p,
            'minuto': minuto,
            'hora': _ahora_info(minuto),
            'velocidad_kmh': vel,
            'motor': motor,
            'latencia_s': rng.randint(0, 15),
            'fuente': 'janus_python'
        })
    lecturas.sort(key=lambda x: (x['unidad'], x['minuto']))
    return lecturas


def resumen_flota(estado_json_str):
    """Recibe el JSON de /api/estado (como string o dict) y devuelve un resumen
    calculado en Python para demostrar py_call con datos del gemelo.
    """
    if isinstance(estado_json_str, str):
        estado = json.loads(estado_json_str)
    else:
        estado = estado_json_str
    unidades = estado.get('unidades', [])
    entregas = estado.get('entregas', [])
    por_estado = {}
    for e in entregas:
        est = e.get('estado', 'desconocido')
        por_estado[est] = por_estado.get(est, 0) + 1
    en_duda = [u.get('unidad') for u in unidades if u.get('estado_unidad') == 'en_duda' or u.get('en_duda')]
    averiadas = [u.get('unidad') for u in unidades if u.get('estado_unidad') == 'averiada' or u.get('averiada')]
    total_peso = sum(float(e.get('peso', 0) or 0) for e in entregas)
    total_vol = sum(float(e.get('volumen', 0) or 0) for e in entregas)
    return {
        'ahora': estado.get('ahora'),
        'total_unidades': len(unidades),
        'total_entregas': len(entregas),
        'entregas_por_estado': por_estado,
        'unidades_en_duda': en_duda,
        'unidades_averiadas': averiadas,
        'peso_total_entregas': total_peso,
        'volumen_total_entregas': total_vol,
        'generado_por': 'python_via_janus',
        'python_version': sys.version.split()[0],
    }


def _bar_svg(items, title, width=720, height=360):
    # items: list of (label, value)
    if not items:
        items = [('sin datos', 0)]
    pad_l, pad_r, pad_t, pad_b = 120, 30, 50, 60
    max_v = max(float(v) for _, v in items) or 1
    n = len(items)
    chart_w = width - pad_l - pad_r
    chart_h = height - pad_t - pad_b
    slot = chart_w / n
    bar_w = slot * 0.6
    colors = ['#4e79a7', '#f28e2b', '#e15759', '#76b7b2', '#59a14f', '#edc949', '#af7aa1', '#ff9da7']
    parts = []
    parts.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" width="{width}" height="{height}">')
    parts.append('<rect x="0" y="0" width="100%" height="100%" fill="#ffffff"/>')
    parts.append(f'<text x="{width/2}" y="28" text-anchor="middle" font-size="18" font-family="sans-serif" fill="#222">{title}</text>')
    # axes
    x0, y0 = pad_l, height - pad_b
    parts.append(f'<line x1="{x0}" y1="{pad_t}" x2="{x0}" y2="{y0}" stroke="#444"/>')
    parts.append(f'<line x1="{x0}" y1="{y0}" x2="{width-pad_r}" y2="{y0}" stroke="#444"/>')
    for i, (label, val) in enumerate(items):
        valf = float(val)
        x = x0 + i * slot + (slot - bar_w) / 2
        bh = (valf / max_v) * chart_h
        y = y0 - bh
        color = colors[i % len(colors)]
        parts.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{bar_w:.1f}" height="{bh:.1f}" fill="{color}"/>')
        parts.append(f'<text x="{x + bar_w/2:.1f}" y="{y-6:.1f}" text-anchor="middle" font-size="12" font-family="sans-serif" fill="#222">{val}</text>')
        # label
        lab = str(label)
        if len(lab) > 10:
            lab = lab[:9] + '…'
        parts.append(f'<text x="{x + bar_w/2:.1f}" y="{y0+18:.1f}" text-anchor="middle" font-size="11" font-family="sans-serif" fill="#333">{lab}</text>')
    parts.append('</svg>')
    return '\n'.join(parts)


def graficar_entregas(estado_json_str, salida='web/grafica_janus.svg'):
    """Genera una grafica SVG (barras por estado de entrega) a partir del estado.
    Escribe el archivo y devuelve metadatos. No requiere matplotlib.
    """
    if isinstance(estado_json_str, str):
        estado = json.loads(estado_json_str)
    else:
        estado = estado_json_str
    entregas = estado.get('entregas', [])
    por_estado = {}
    for e in entregas:
        est = str(e.get('estado', 'desconocido'))
        por_estado[est] = por_estado.get(est, 0) + 1
    # orden estable
    orden = ['entregada', 'en_ruta', 'pendiente', 'fallida', 'no_ubicable', 'desconocido']
    items = []
    for k in orden:
        if k in por_estado:
            items.append((k, por_estado[k]))
    for k, v in sorted(por_estado.items()):
        if k not in orden:
            items.append((k, v))
    ahora = estado.get('ahora', 300)
    svg = _bar_svg(items, f'Entregas por estado (ahora={ahora} min, 13:00)')
    # resolver ruta relativa al dir del script/gemelo
    out_path = salida
    if not os.path.isabs(out_path):
        base = os.path.dirname(os.path.abspath(__file__))
        out_path = os.path.join(base, out_path)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write(svg)
    return {
        'archivo': out_path,
        'archivo_relativo': salida,
        'items': [{'estado': k, 'cantidad': v} for k, v in items],
        'total': sum(v for _, v in items),
        'formato': 'svg',
        'generado_por': 'python_via_janus',
    }


def graficar_llegadas(llegadas_json_str, unidad='u1', salida='web/grafica_llegadas_janus.svg'):
    """Genera SVG con llegada maxima estimada por entrega para una unidad."""
    if isinstance(llegadas_json_str, str):
        datos = json.loads(llegadas_json_str)
    else:
        datos = llegadas_json_str
    llegadas = datos if isinstance(datos, list) else datos.get('llegadas', [])
    items = []
    for d in llegadas:
        e = d.get('entrega', '?')
        mx = d.get('maximo', d.get('minimo', 0))
        items.append((str(e), int(mx) if mx is not None else 0))
    if not items:
        items = [('sin datos', 0)]
    svg = _bar_svg(items, f'Llegada máxima estimada por entrega ({unidad})')
    out_path = salida
    if not os.path.isabs(out_path):
        base = os.path.dirname(os.path.abspath(__file__))
        out_path = os.path.join(base, out_path)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write(svg)
    return {
        'archivo': out_path,
        'archivo_relativo': salida,
        'unidad': unidad,
        'items': [{'entrega': k, 'maximo': v} for k, v in items],
        'formato': 'svg',
        'generado_por': 'python_via_janus',
    }


def ping():
    return {'ok': True, 'modulo': 'janus_sim', 'python': sys.version.split()[0]}


if __name__ == '__main__':
    # Uso CLI: python3 janus_sim.py <funcion> '<json_args>'
    func = sys.argv[1] if len(sys.argv) > 1 else 'ping'
    raw = sys.argv[2] if len(sys.argv) > 2 else '[]'
    try:
        args = json.loads(raw)
    except Exception:
        args = []
    if isinstance(args, dict):
        kwargs = args
        pos = []
    elif isinstance(args, list):
        pos = args
        kwargs = {}
    else:
        pos = [args]
        kwargs = {}
    fn = globals().get(func)
    if not fn or not callable(fn):
        print(json.dumps({'error': f'funcion no encontrada: {func}'}))
        sys.exit(1)
    try:
        res = fn(*pos, **kwargs)
        print(json.dumps(res, ensure_ascii=False))
    except Exception as e:
        print(json.dumps({'error': str(e), 'funcion': func}))
        sys.exit(1)
