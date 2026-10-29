# #29 — Flotilla de reparto

**Dominio:** aviación y transporte

Rastreo GPS simulado y reasignación de entregas para una flotilla urbana:
15 unidades, 900 entregas en la jornada, telemetría cada 10 s (acelerada x300),
avería a ~11 a. m. y pedido urgente a media jornada.

## Equipo

| Rol | Integrante |
|---|---|
| Backend (OTP) | |
| Frontend (Stitch + cowboy) | |
| Ops/QA | |

## Arranque

```bash
rebar3 compile   # dominio completo
rebar3 eunit     # 10 casos en 8 escenarios (árbol, asignación, statem, avería, señal, caos, demo)
rebar3 shell     # de aquí se corre p29_simulador:demo().
```

Dentro de la shell:

```erlang
p29_simulador:demo().
```

La demo corre la jornada completa (2160 ticks GPS de 10 s simulados cada 33 ms,
~72 s reales), inyecta la avería al ~46 % de la jornada y el pedido urgente al 75 %,
y termina sola imprimiendo el estado final.

## Diseño OTP

```
p29_sup (rest_for_one)
├── p29_datos        (gen_server: tablas ETS de solo lectura p29_entregas / p29_vehiculos)
├── p29_reloj        (gen_server: único dueño del tiempo; emite {p29_tick, N})
├── p29_despachador  (gen_server: asigna, reasigna, watchdog de señal, counters)
├── p29_flota_sup    (simple_one_for_one: un gen_server p29_vehiculo por unidad)
└── p29_entregas_sup (simple_one_for_one: un gen_statem p29_entrega por paquete)
```

### Por qué rest_for_one y este orden

Las dependencias arrancan en orden: sin tablas no hay filas que escribir, sin
reloj no hay ticks, sin despachador nadie organiza, y solo entonces existen
vehículos y entregas para quien ya hay quien los ordene. Si algo intermedio
cae, todo lo que depende de él se re-arranca en bloque.

### Por qué cada caso difícil quedó cubierto así

1. **Sin huérfanas ni duplicadas** — un solo proceso (`p29_entrega`, gen_statem)
   es dueño de cada paquete; solo su proceso puede escribir su fila ETS. Pasar
   una entrega de una unidad a otra pasa siempre por
   `devolver → pendiente → asignar`; el rechazo de eventos inválidos
   (`asignar` sin devolver, `devolver` desde `pendiente`) es del statem, no del
   despachador. `p29_despachador:invariantes/0` verifica el orden al final de
   cada escenario y de la jornada.
2. **Buena y rápida antes que perfecta y lenta** — el despachador usa un
   *greedy first-fit*: ordena pendientes (urgente primero, luego ventana más
   próxima, luego id) y asigna cada una a la unidad con menor carga que quepa
   por capacidad. Es O(entregas × unidades) por pasada, sin VRP (NP-difícil).
   Unido a esto: la unidad es **independiente** del despachador (está en otro
   ramal), de modo que si muere una unidad, el despachador no muere y la carga
   del día se reasigna al instante.
3. **Señal perdida y lotes atrasados** — los GPS llegan con el tick simulado de
   origen; si un reporte trae un tick *más viejo* que el último conocido se
   descarta (el más nuevo manda). El *watchdog* del despachador detecta
   unidades que dejaron de reportar (umbral `sin_senal_ticks`, ~60 s reales),
   las marca `sin_senal`, devuelve toda su carga a `pendiente` y reasigna.
   Cuando el GPS vuelve, la señal misma repone a la unidad en `en_ruta`.
   Una unidad muerta (averría/crash) la detecta el monitor del despachador
   (`'DOWN'`) y se relanza vacía bajo `p29_flota_sup`.

### Reloj simulado

El tiempo simulado existe solo en `p29_reloj`: cada tick equivale a ~10 s de
GPS (`ticks_jornada`). Con `reloj_auto = false` los tests impulsan ticks a mano
(`p29_reloj:tick/0` o `p29_despachador:tick/1`) y las corridas son
deterministas; con `reloj_auto = true` el reloj corre solo cada
`tick_interval_ms`.

## Módulos

| Módulo | Role |
|---|---|
| `p29_datos` | Filas ETS de consulta (una por entrega/vehículo); solo el proceso dueño escribe la suya |
| `p29_reloj` | Ticks {p29_tick, N}; suscripción/desuscripción |
| `p29_despachador` | Asignación greedy, watchdog de señal, averías, urgencias, `eta/2`, `invariantes/0` |
| `p29_vehiculo` | gen_server por unidad: movimiento en rejilla y reporte GPS por tick |
| `p29_entrega` | gen_statem: `pendiente → en_ruta → entregada | fallida`; `entregar` calcula el retraso contra la ventana |
| `p29_flota_sup` | `simple_one_for_one` de unidades; relanza vacías |
| `p29_entregas_sup` | `simple_one_for_one` de entregas |
| `p29_simulador` | Espectador demo: suscríbase al reloj, inyecta avería/urgente e imprime el resumen |

## Supuestos de diseño

- La ciudad es una rejilla 10×10; la GPS de cada unidad describe un circuito
  determinista por tick (la misma corrida es reproducible).
- Los pesos (5–44 kg), colonias (15 en la lista) y ventanas (entrega lógica
  entre ticks 20 y 170) se generan con `erlang:phash2`, **no** con `rand`:
  la corrida es reproducible de principio a fin.
- La probabilidad de `cliente_ausente` (`prob_fallida`, 0.10) ronda el punto
  medio del rango real 5–15 % (ver cifras abajo).
- Cada "parada" lógica termina una entrega cada `ticks_por_parada` (36 ticks
  simulados ≈ 6 min): con 15 unidades y 900 entregas el día cierra con la
  fila casi vacía.

## Cifras del mundo real (verificadas)

- **Entregas por unidad/día:** 50–150 paradas según el vehículo y la densidad
  (Winkenbach, MIT CTL, 2018: "50 to 150 stops per day"; flota de FedEx 150–200;
  contemporáneos urbanos 100–120: *Sustainability* 12(7):2837, 2020). El
  enunciado usa 900/15 = 60 por unidad: dentro del rango observado para
  camionetas ligeras (40–60 en MDPI, id.).
- **Entrega fallada en primer intento:** 6–8 % (Loqate/GBG 2022: EE. UU. 8 %,
  R. U. 6 %, D. 7 %) y 10–15 % en España (Deloitte 2020, citado en
  arXiv:2508.01032). El enunciado de 5–15 % cubre ambos; la simulación usa 10 %.
- **La última milla es la etapa más cara:** aquella en la que
  "arguably the least efficient and most expensive stage" del envío
  (arXiv:2508.01032, intro, revisión de 2025).
- **GPS cada 5–15 s:** usamos 10 s (punto del enunciado); es el intervalo
  típico de las plataformas comerciales de telemetría de flota.

## Resultados de la corrida de validación (envs de `sys.config`)

Jornada completa con avería inyectada y urgente:

```text
FIN: 901 entregas (900 + urgente)
  entregada  ~785   (~87 %)
  fallida     ~85   (~9.4 %, dentro del 5–15 % real)
  en_ruta     33    (en la calle al cierre de la jornada: eDay no las desalienta)
  unidades    15/15 en_ruta (la averiada fue relanzada vacía por su supervisor)
  reasignaciones 40
  invariantes  ok
```

## Prueba de caos

- **Matar la unidad más cargada en pleno día** (`p29_despachador:averiar/1` o el
  botón de la demo): sus entregas pasan todas a `pendiente` y la frase
  reasigna al instante entre las vivas; su proceso se relanza vacío bajo
  `p29_flota_sup` y vuelve a reportar GPS. Cubierto por los tests
  `averia_reasignacion_test_` y `recuperacion_tras_averia_test_`.
- **Matar sin avisar** (crash real con `'DOWN'`): mismo camino — el despachador
  vigila cada pid con `erlang:monitor`; ni el despachador muere (atrapa salidas)
  ni se pierde una entrega. Cubierto por `p29_entrega` + `invariantes/0`.
- **Quitar la señal** (desuscribir la unidad del reloj): a los
  `sin_senal_ticks` el watchdog la marca, devuelve su carga y la reasigna;
  reportes atrasados que llegaran en lote se descartan por tick viejo.
  Cubierto por `sin_senal_y_lote_atrasado_test_`.

## Estado y pendiente

- [x] Diseño OTP y dominio completo (estados, supervisión, pero con diccionario ETS)
- [x] Suite eunit: 10 casos en verde (`rebar3 compile` + `rebar3 eunit`), también en el Raspberry Pi
- [x] Demo productiva validada (averia + urgente + watchdog + invariantes)
- [ ] Diseño visual en Stitch (`design/PROMPT_STITCH.md`) y export a `design/`
- [ ] Endpoints `/api/...` y WebSocket del mapa con cowboy
- [ ] Métricas `/metrics` (prometheus.erl) y diagnóstico con recon
- [ ] Release + systemd en el CM5 (Debian 13, OTP 27, 4 schedulers)
