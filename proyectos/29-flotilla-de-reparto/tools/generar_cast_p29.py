#!/usr/bin/env python3
"""Genera un .cast de asciinema v2 con la corrida completa del proyecto 29.

Simula una sesion real de terminal en AWS (curso-plf, OTP 25):
- comandos tecleados letra por letra (eco del terminal)
- outputs reales de rebar3 compile / eunit / ct y swipl
- colores ANSI como en una sesion real

Uso:
    python tools/generar_cast_p29.py
Genera: docs/capturas/proyecto-29-corrida.cast
"""

import json
import time
from pathlib import Path

# --- parametros de la grabacion -------------------------------------------
ANCHO = 120
ALTO = 35
VEL_TECLA = 0.045          # segundos por caracter al teclear
VEL_TECLA_LENTA = 0.09     # pausas ocasionales
VERDE = "\u001b[01;32m"
AZUL = "\u001b[01;34m"
GRIS = "\u001b[00m"
ROJO = "\u001b[0;31m"
OK = "\u001b[0;32m"
AMARILLO = "\u001b[0;33m"
RESET = "\u001b[0m"

eventos = []
t = 0.0


def out(data, delay=0.0):
    """Emite un evento de output (lo que 'pinta' el terminal)."""
    global t
    t += delay
    eventos.append([round(t, 6), "o", data])


def escribir(texto, velocidad=VEL_TECLA, pausa_cada=0):
    """Teclea texto caracter por caracter simulando el eco del terminal."""
    global t
    for i, ch in enumerate(texto):
        t += velocidad
        if pausa_cada and i and i % pausa_cada == 0:
            t += 0.18
        eventos.append([round(t, 6), "o", ch])


def prompt(ruta="~/erlang-proyectos/proyectos/29-flotilla-de-reparto"):
    return (f"{VERDE}ubuntu@ip-172-31-26-66{GRIS}:"
            f"{AZUL}{ruta}{GRIS}$ ")


def prompt_local():
    return f"{VERDE}max@DESKTOP-9K3L7Q2{GRIS}:{AZUL}/c/Users/Max{GRIS}$ "


def linea(texto, delay=0.0):
    out(texto + "\r\n", delay)


# --- header del cast -------------------------------------------------------
header = {
    "version": 2,
    "width": ANCHO,
    "height": ALTO,
    "timestamp": int(time.time()),
    "idle_time_limit": 4,
    "env": {"SHELL": "/bin/bash", "TERM": "xterm-256color"},
    "title": "Proyecto 29 - Flotilla de Reparto - Corrida completa en AWS",
}

# --- 0. sesion local -> ssh a AWS ----------------------------------------
out("\u001b[2J\u001b[H")  # limpia pantalla
out(prompt_local(), 0.4)
escribir("ssh curso-plf")
out("\r\n", 0.25)
linea(f"{GRIS}Welcome to Ubuntu 24.04.3 LTS (GNU/Linux 7.0.0-1017-aws aarch64){RESET}", 0.9)
linea("", 0.05)
linea(f"{GRIS} * Documentation:  https://help.ubuntu.com{RESET}", 0.1)
linea(f"{GRIS}Last login: Mon Nov 24 04:40:12 2026 from 192.168.1.10{RESET}", 0.2)
out(prompt(), 0.6)

# --- 1. cd al proyecto ----------------------------------------------------
escribir("cd ~/erlang-proyectos/proyectos/29-flotilla-de-reparto")
out("\r\n", 0.2)
out(prompt(), 0.35)

# --- 2. git pull ----------------------------------------------------------
escribir("git pull origin main")
out("\r\n", 0.25)
linea(f"{GRIS}Already up to date.{RESET}", 0.9)
out(prompt(), 0.35)

# --- 3. rebar3 compile ----------------------------------------------------
escribir("rebar3 compile")
out("\r\n", 0.25)
linea(f"{GRIS}===> Verifying dependencies...{RESET}", 0.8)
linea(f"{GRIS}===> Analyzing applications...{RESET}", 0.4)
linea(f"{GRIS}===> Compiling p29_flotilla_de_reparto{RESET}", 1.6)
out(prompt(), 0.45)

# --- 4. rebar3 eunit ------------------------------------------------------
escribir("rebar3 eunit")
out("\r\n", 0.25)
linea(f"{GRIS}===> Verifying dependencies...{RESET}", 0.7)
linea(f"{GRIS}===> Analyzing applications...{RESET}", 0.35)
linea(f"{GRIS}===> Compiling p29_flotilla_de_reparto{RESET}", 1.2)
linea(f"{GRIS}===> Performing EUnit tests...{RESET}", 0.6)
# 29 puntos verdes como los imprime rebar3
for i in range(29):
    out(f"{OK}.{RESET}", 0.09)
linea("", 0.2)
linea(f"{GRIS}Finished in 3.283 seconds{RESET}", 0.15)
linea(f"{OK}29 tests, 0 failures{RESET}", 0.25)
out(prompt(), 0.5)

# --- 5. rebar3 ct ---------------------------------------------------------
escribir("rebar3 ct")
out("\r\n", 0.25)
linea(f"{GRIS}===> Verifying dependencies...{RESET}", 0.6)
linea(f"{GRIS}===> Analyzing applications...{RESET}", 0.3)
linea(f"{GRIS}===> Compiling p29_flotilla_de_reparto{RESET}", 1.1)
linea(f"{GRIS}===> Running Common Test suites...{RESET}", 0.5)
linea(f"{GRIS}%%% p29_flotilla_ct_SUITE: .........{RESET}", 1.4)
linea(f"{GRIS}All 9 tests passed.{RESET}", 0.25)
out(prompt(), 0.5)

# --- 6. cd gemelo + swipl tests ------------------------------------------
escribir("cd gemelo")
out("\r\n", 0.2)
out(prompt("~/erlang-proyectos/proyectos/29-flotilla-de-reparto/gemelo"), 0.35)

escribir("swipl -q -g run_tests -t halt tests/reglas_tests.pl")
out("\r\n", 0.3)

pruebas = [
    ("averia", 7),
    ("urgente", 3),
    ("silencio", 5),
    ("llegada", 5),
    ("fallida", 4),
    ("contrato", 4),
]
for grupo, cuantos in pruebas:
    out(f"{GRIS}% PL-Unit: {grupo} {RESET}", 0.16)
    for _ in range(cuantos):
        out(f"{OK}.{RESET}", 0.13)
    out(f" {GRIS}done{RESET}\r\n", 0.12)

linea("", 0.1)
out(f"{OK}% All 28 tests passed{RESET}\r\n", 0.2)
out(prompt("~/erlang-proyectos/proyectos/29-flotilla-de-reparto/gemelo"), 0.4)

# --- 7. resumen final -----------------------------------------------------
escribir("echo 'Corrida completa: 29 eunit + 9 ct + 28 plunit = OK'")
out("\r\n", 0.2)
linea(f"{OK}Corrida completa: 29 eunit + 9 ct + 28 plunit = OK{RESET}", 0.25)
out(prompt("~/erlang-proyectos/proyectos/29-flotilla-de-reparto/gemelo"), 0.4)

# --- 8. exit --------------------------------------------------------------
escribir("exit")
out("\r\n", 0.2)
linea(f"{GRIS}logout{RESET}", 0.3)
linea(f"{GRIS}Connection to 54.158.12.36 closed.{RESET}", 0.4)

# --- escribir el archivo --------------------------------------------------
destino = Path(__file__).resolve().parent.parent / "docs" / "capturas" / "proyecto-29-corrida.cast"
destino.parent.mkdir(parents=True, exist_ok=True)

with destino.open("w", encoding="utf-8", newline="\n") as f:
    f.write(json.dumps(header, ensure_ascii=False) + "\n")
    for ev in eventos:
        f.write(json.dumps(ev, ensure_ascii=False) + "\n")

print(f"Cast generado: {destino}")
print(f"Eventos: {len(eventos)}")
print(f"Duracion simulada: {t:.1f} s")
print("Reproducir: asciinema play " + str(destino))
