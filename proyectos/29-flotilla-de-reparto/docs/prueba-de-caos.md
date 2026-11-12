# Prueba de caos — #29 Flotilla de reparto

La consigna pide tres cosas: **qué mataste, qué esperabas y qué ocurrió**. Este
documento registra las seis pruebas con evidencia de la corrida real en la
Raspberry Pi 4 (Debian 11, OTP 27.3.4.19, `config/sys.config` por defecto).

- Fecha: 2026-11-11 (escenarios 1–5) y 2026-11-12 (escenario 6)
- Máquina: `raspberrypi` (RPi 4 Model B, 4 cores, 3.8 GB, Corellium)
- Commits: `1bd4ed3` (1–5) y `f27e046` (6)
- Reloj automático, jornada de 2160 ticks (33 ms por tick)

## Cómo reproducir

```bash
cd ~/erlang-proyectos/proyectos/29-flotilla-de-reparto
export PATH=$HOME/otp/27.3.4.19/bin:$HOME/bin:$PATH
sudo systemctl stop p29-flotilla          # libera el :8080

# el runner vive fuera del repo (es evidencia, no producto)
scp p29_caos.erl pi@...:/tmp/
erlc -o /tmp -pa _build/default/lib/*/ebin /tmp/p29_caos.erl
erl -noshell -pa _build/default/lib/*/ebin -pa /tmp \
    -config config/sys.config -eval 'p29_caos:run().'
```

Cada escenario arranca la aplicación desde cero, deja generar la flota, corre
~3 s y recién entonces mata el proceso. Así una prueba no contamina la
siguiente.

---

## Escenario 1 — matar una aeronave (`exit(Pid, kill)` en `p29_aeronave` de la unidad 3)

**Qué se esperaba**: el `simple_one_for_one` bajo `p29_aeronaves_sup` relanza
una unidad vacía; el despachador detecta el `'DOWN'` (tiene `process_flag(trap_exit)`
y monitores) y devuelve sus envíos a `pendiente` para reasignarlos. Ningún envío
queda huérfano ni duplicado.

**Qué ocurrió**:

```
antes    #{tick => 974, entregada => 347, pendiente => 427, en_ruta => 94,
           fallida => 32, reasignaciones => 11, invariantes => ok}
matado   {aeronave_3, <0.150.0>}
resultado {recreada_vacia, <0.1063.0>} en 101 ms
despues  #{tick => 1036, entregada => 360, pendiente => 415, en_ruta => 93,
           fallida => 32, reasignaciones => 11, invariantes => ok}
```

- PID nuevo (`<0.150.0>` → `<0.1063.0>`) en 101 ms.
- `pendiente` bajó (427 → 415) y `entregada` subió (347 → 360): la flota siguió
  trabajando, no se detuvo a esperar.
- `invariantes => ok`: sin huérfanos.

---

## Escenario 2 — matar un envío (`exit(Pid, kill)` en un `gen_statem` de `p29_envios_sup`)

**Qué se esperaba**: el despachador recibe el `'DOWN'`, reasigna el envío y el
`simple_one_for_one` relanza el proceso.

**Qué ocurrió**:

```
antes    #{tick => 974, entregada => 350, pendiente => 421, en_ruta => 97,
           fallida => 32, reasignaciones => 9, invariantes => ok}
matado   {envio, <0.1284.0>}
resultado {supervisor_relanzo_procesos, 900} en 0 ms
despues  #{tick => 1032, entregada => 360, pendiente => 410, en_ruta => 97,
           fallida => 33, reasignaciones => 10, invariantes => ok}
```

- `reasignaciones` subió 9 → 10: el despachador procesó la muerte y reasignó.
- Los 900 hijos de `p29_envios_sup` siguen vivos.
- `invariantes => ok`.

**Lectura crítica**: el criterio de "recuperación en 0 ms" mide que el supervisor
ya reportaba hijos vivos, no que el envío muerto en particular se haya recreado
(eso lo confirma el +1 de reasignaciones y los invariantes).

---

## Escenario 3 — matar el despachador (`exit(Pid, kill)` en `p29_despachador`)

**Qué se esperaba**: por `rest_for_one`, caer el despachador reinicia todo lo que
depende de él: `p29_aeronaves_sup`, `p29_envios_sup`, `p29_transbordo_sup`,
`p29_broadcaster` y `p29_web`. `p29_datos` y `p29_reloj` sobreviven (están antes).

**Qué ocurrió**:

```
antes    #{tick => 974, entregada => 357, pendiente => 419, en_ruta => 97,
           fallida => 27, reasignaciones => 7, invariantes => ok}
matado   {despachador, <0.2017.0>}
resultado {reiniciado, <0.2951.0>} en 101 ms
despues  #{tick => 1035, entregada => 12, pendiente => 776, en_ruta => 110,
           fallida => 2, reasignaciones => 1, invariantes => ok}
```

- El despachador volvió en 101 ms y el árbol quedó consistente.
- **Pero la jornada se reinició**: `entregada` 357 → 12 y `pendiente` 419 → 776.
  Los envíos viven en procesos hijos del despachador; al reiniciarse, se
  regeneran desde cero.
- `invariantes => ok` gracias a `esperar_sup`: el despachador nuevo espera a que
  el supervisor dinámico esté arriba antes de asignar.

**Es el resultado esperado del diseño** (`rest_for_one` protege la consistencia
sobre la continuidad), y por eso se documenta: en una demo no se debe matar el
despachador esperando "seguir donde estaba".

---

## Escenario 4 — matar la web (`exit(Pid, kill)` en `p29_web`)

**Qué se esperaba**: la web es el último hijo y un observador. Debe caer sola,
reiniciarse, y el dominio (reloj, despachador, flota) seguir simulando sin pausa.

**Qué ocurrió**:

```
antes    #{tick => 974, entregada => 354, pendiente => 426, en_ruta => 95,
           fallida => 25, reasignaciones => 10, invariantes => ok}
matado   {web, <0.3899.0>}
resultado {http_200_otra_vez, ok} en 24 ms
despues  #{tick => 1033, entregada => 366, pendiente => 413, en_ruta => 95,
           fallida => 26, reasignaciones => 10, invariantes => ok}
```

- `GET /api/estado` volvió a 200 en **24 ms**.
- `entregada` 354 → 366 sin interrupción: el dominio nunca se enteró.
- `invariantes => ok`.

---

## Escenario 5 — matar las tablas ETS (`exit(Pid, kill)` en `p29_datos`)

**Qué se esperaba**: `p29_datos` es el dueño de las tablas ETS y el primer hijo.
Perderlo debe reiniciar **todo** el árbol (`rest_for_one`) y reconstruir el
estado desde `sys.config`.

**Qué ocurrió**:

```
antes    #{tick => 974, entregada => 344, pendiente => 421, en_ruta => 95,
           fallida => 40, reasignaciones => 7, invariantes => ok}
matado   {datos, <0.4859.0>}
resultado {reiniciado_todo, <0.5799.0>} en 101 ms
despues  #{tick => 61, entregada => 13, pendiente => 777, en_ruta => 108,
           fallida => 2, reasignaciones => 0, invariantes => ok}
```

- Árbol completo arriba en 101 ms.
- Tick 61 y 13 entregadas: la simulación arrancó de cero.
- `invariantes => ok`.

---

## Escenario 6 — unidad que deja de reportar (`sys:suspend` sobre `p29_aeronave` de la unidad 15, 2,5 s)

Reproduce el caso del enunciado **«conductor sin señal por una hora que luego
reporta todo junto»**: el proceso no muere, simplemente deja de mandar GPS.
Medido el 2026-11-12 sobre el release `f27e046` de la RPi, con el servicio
recién arrancado (tick 551, 117 envíos en ruta, 567 pendientes).

**Qué se esperaba**: el watchdog del despachador (`sin_senal_ticks = 6`, 6
ticks sin reporte = 60 s simulados) marca la unidad `sin_senal` y devuelve sus
envíos a la cola; al reanudar, la unidad vuelve a reportar, se recupera a
`en_ruta` y sigue operando. Nunca debe quedar un envío asignado a una unidad
muda.

**Qué ocurrió**:

```
antes de suspender:            estado=en_ruta  envios_en_ruta=13
                               pendientes=567  reasignaciones=9
tras 2,5 s suspendida:         estado=sin_senal
                               pendientes=551  reasignaciones=20
tras reanudar (2,5 s después):  estado=en_ruta
                               pendientes=517  reasignaciones=25
invariantes=ok
```

- La unidad pasó a `sin_senal` sola, sin matar el proceso: el watchdog detectó
  el hueco de telemetría.
- `reasignaciones` **9 → 20 → 25**: los 13 envíos que llevaba salieron de la
  unidad muda y se repartieron entre el resto de la flota.
- Al reanudar, la unidad volvió a `en_ruta` y el proceso siguió vivo
  (`is_process_alive = true`): no hizo falta relanzarla, el estado se recuperó.
- `invariantes = ok` en todo el episodio: ningún envío huérfano ni duplicado.

**Cómo reproducirlo** (contra el nodo vivo, sin parar el servicio):

```bash
cd ~/erlang-proyectos/proyectos/29-flotilla-de-reparto
export P29_COOKIE=$(sudo grep '^P29_COOKIE=' /etc/p29-flotilla.env | cut -d= -f2)
export RELX_REPLACE_OS_VARS=true
_build/default/rel/p29_flotilla_de_reparto/bin/p29_flotilla_de_reparto eval '
Id = 15,
Pid = whereis(list_to_atom("p29_aeronave_" ++ integer_to_list(Id))),
sys:suspend(Pid), timer:sleep(2500),
p29_datos:aeronave(Id),          %% estado => sin_senal
sys:resume(Pid), timer:sleep(2500),
p29_datos:aeronave(Id),          %% estado => en_ruta
p29_despachador:invariantes().'
```

(Las unidades se registran como `p29_aeronave_<Id>`; `p29_despachador:estado()`
devuelve conteos, no PIDs, así que el PID se resuelve con `whereis/1`.)

---

## Conclusión

| Capa | ¿Se recuperó? | ¿Se perdió la jornada? | Invariantes |
|---|---|---|---|
| Aeronave | Sí, 101 ms | No | ok |
| Envío | Sí | No | ok |
| Despachador | Sí, 101 ms | **Sí** | ok |
| Web | Sí, 24 ms | No | ok |
| Datos | Sí, 101 ms | **Sí** | ok |
| Unidad sin señal (`sys:suspend`) | Sí, vuelve a `en_ruta` | No | ok |

- La garantía que se cumple en los cinco casos es la de negocio: **nunca quedan
  envíos huérfanos, duplicados ni asignados a unidades muertas**.
- La debilidad es que el estado de la jornada es en memoria y el árbol no separa
  "estado" de "coordinación": perder `p29_datos` o `p29_despachador` reinicia la
  simulación. Es aceptable para una demo; en producción pediría persistencia
  (DETS/Mnesia) o un supervisor de estado separado.
- La web demuestra el principio de observador: puede caer sin afectar al dominio.
