# 29 — Flotilla de reparto · notas para agentes

Solo recoge lo que no se deduce leyendo el código (no hay un `AGENTS.md` de raíz
en este repo al que referirse; el de este proyecto es la fuente de reglas).

## Dónde se trabaja

- Es una app rebar3 **independiente**: todos los comandos se corren desde esta carpeta,
  no desde la raíz del repo (allí no hay `rebar.config`).
- El destino final es el **Raspberry Pi del estudiante**: Raspberry Pi 4 Model B, Debian 11
  (bullseye), 4 cores, 3.8 GB, OTP 27.3.4.19 vía asdf. No des por hechas
  rutas ni versiones de otras máquinas/docentes.
  Se entra con `ssh flotilla` (alias en `~/.ssh/config` que salta por el proxy de
  Corellium). El jump host, su token y la contraseña **no van al repo**; viven solo en la
  configuración SSH local.
- El escritorio del estudiante es Windows con PowerShell 5.1: los comandos de abajo son
  PowerShell, no bash.

## Comandos

```powershell
rebar3 compile      # warnings_as_errors: un solo warning rompe el build
rebar3 eunit        # 11 casos, 0 fallos = verde
rebar3 shell        # web en :8080 + dentro: p29_simulador:demo(). (jornada completa, ~72 s)
rebar3 release      # _build/default/rel/p29_flotilla_de_reparto (NO prod: ver deploy/)
```

- Un caso suelto: `rebar3 eunit --test=p29_flotilla_de_reparto_tests:arbol_despues_de_arrancar_test_`
- La suite tiene **11 casos**. Si un día `rebar3 eunit` dice 20, es que el módulo está
  duplicado en `_build/test/lib/p29_flotilla_de_reparto/ebin` y `.../test`: borra el beam
  de `ebin` y vuelve a correr; no son 20 casos distintos.
- La demo imprime el resumen al terminar; para mirar el estado en vivo:
  `p29_despachador:estado()`, `p29_datos:entregas_todas()`.
- **`rebar3 shell` no arranca en segunda sesión no interactiva de Windows** (crash de
  `prim_tty` dentro de la VM). Para una VM de prueba sin TTY (scripts, agentes):
  compila con `erlc` un módulo de arranque en Temp que haga
  `application:ensure_all_started(p29_flotilla_de_reparto), timer:sleep(infinity)` y
  corre `erl -pa ... -noshell -config config/sys.config -eval "modulo:main(0)."` con
  los `-pa` construidos en array de PowerShell.

## Arquitectura que no se ve en los nombres

- `rest_for_one`: datos → reloj → despachador → flota_sup → entregas_sup →
  broadcaster → web. El orden es la dependencia real; si cae un eslabón se reinicia
  todo lo que está después (la web cae con su dominio, nunca queda un dashboard
  verde sobre datos muertos).
- Las tablas ETS `p29_entregas` / `p29_vehiculos` son **caché de lectura**. El dueño de
  cada fila es el `gen_statem` de la entrega o el `gen_server` de la unidad: nunca
  escribas ETS desde otro proceso ni desde un handler HTTP, usa la API
  (`p29_entrega:*`, `p29_despachador:*`).
- `p29_reloj` es el único dueño del tiempo. Nada de `erlang:monotonic_time/0` ni
  `timer:sleep` en el dominio: rompe la reproducibilidad y los tests con reloj manual.
- El determinismo es deliberado: flota, pesos, colonias y ventanas salen de
  `erlang:phash2`, no de `rand`. Meter `rand` sin semilla hace fallar `simulador_test_`
  (comprueba cifras exactas).
- El simulador cuenta su jornada desde el tick en que arranca (`T0 = tick_actual()`), no
  desde el 0 absoluto, y la avería/el urgente se inyectan con `>=` una sola vez. No
  vuelvas a programarlos en ticks absolutos: en el Pi el arranque tarda más que la
  jornada de la mini-demo y se los saltaba (12 entregas en vez de 13).
- El despachador atrapa salidas (`trap_exit`) y detecta muertes por monitores `'DOWN'`;
  las unidades se relanzan bajo `p29_flota_sup`. Si tocas el arranque, respeta
  `esperar_sup`: sin el supervisor dinámico nadie relanza unidades muertas.
- La UI se implementa desde la maqueta de Stitch en `design/Plantilla Flotilla de
  Reparto/`. Los tokens están en
  `design/Plantilla Flotilla de Reparto/aeroterra_dispatch_telematics/DESIGN.md`; **no**
  en `design/DESIGN.md`, que no existe. Los `code.html` son Tailwind por CDN con
  `onclick` inline: se portan a estáticos de cowboy, no se sirven tal cual.

## UI bajo carga: botones que parecen muertos (diagnóstico verificado 2026-11-08)

Síntoma del cliente: con datos cargando, los botones tardan o no responden;
sin carga, funcionan. **No es un bug del dominio**: en el Pi, con el servicio
corriendo y sin navegador, el `load average` es ~0.00 y la CPU total del
release ~3 s. El atasco es la UI acoplada al tick de simulación:

- El reloj corre a **33 ms (~30 ticks/s)** y el broadcaster emite un evento SSE
  `estado` por tick (`priv/static/app.js`: `EventSource("/eventos")`).
  En `index` cada evento repinta KPIs, mapa (reconstruye 15 marcadores con
  `innerHTML`), panel, bitácora y banner. En `unidad` e `historial` cada evento
  dispara además **`pintarUnidad()/pintarHistorial()` = 3 `fetch` por tick**
  (`/api/estado` + `/api/vehiculos` + **`/api/entregas`, 206 KB / 901 filas**)
  y reconstruye tablas/timeline enteras con `innerHTML`. Eso es ~90 peticiones/s
  y repintados completos a 30 Hz por el proxy de Corellium → hilo principal
  saturado, clicks sin respuesta. Sin espectadores SSE no hay JSON (guardia en
  el broadcaster) y todo vuela: por eso "sin carga funciona".
- Medido en el Pi (localhost): `/api/entregas` tarda **12 ms / 206 KB** y
  `/api/estado` es instantáneo: el backend no es el cuello; lo es el bucle
  fetch+parse+DOM **en el navegador**, amplificado por cualquier proxy WAN.
- **La jornada no frena el reloj**: con `reloj_auto=true` el tick sigue para
  siempre tras el tick 2160 (observado: tick 13002) y el SSE sigue a 30 Hz
  con la flota ya en `en_ruta` idle. No des por hecho que al terminar la demo
  la UI se quieta.
- Ante selects/clicks erráticos, primero **hard reload (Ctrl+F5)**: hay
  middleware `no-cache` en cowboy (commit 73233d7/10790ab) y un JS viejo en
  caché producía exactamente "botones muertos". Verificación: las respuestas
  de estáticos llevan `cache-control: no-cache, must-revalidate`.
- No se arregla reduciendo la carga simulada (no tocar `tick_interval_ms`,
  `vehiculos`, `entregas`, `ticks_por_parada` de `sys.config` para "arreglar"
  la UI). La dirección verificada/sin tocar dominio:
  1. Desacoplar pintado del tick: acumular el último evento SSE y pintar a
     4–10 Hz con `requestAnimationFrame` + bandera de "ya programado"; no
     pintar si `document.hidden`.
  2. En `unidad`/`historial`, **no refetchear `/api/entregas` por tick**:
     entrar una vez, refrescar a 2–5 s o con botón manual; reusar lo que ya
     trae el SSE (`resumen` + `unidades`), y guardar banderas anti-solapado
     para que `pintarUnidad()` no se apile contra sí misma.
  3. Detener o estrangular el SSE tras `ticks_jornada` (o bajar la cadencia
     cuando no hay cambios) en vez de 30 Hz eternos.
  4. No borrar/reconstruir el mapa entero por tick: reusar divs de marcadores
     y moverlos con `transform` (posiciones X,Y ya vienen en el SSE).
  5. Si se mantiene el refetch, pedir la entrega por unidad/estado en vez del
     listado completo de 206 KB (pasando por `p29_api`/`p29_despachador:*`,
     nunca ETS desde el handler).
- **Implementado en `f1dd7b4`** (puntos 1, 2 y 4; falta el 3, SSE tras la
  jornada): `app.js` acumula el último evento SSE y pinta cada 160 ms con
  `requestAnimationFrame`, el mapa reusa divs por id, `unidad`/`historial`
  tienen guarda anti-solapado y el dashboard ya no pide `/api/entregas`.
  Desplegado y verificado en el Pi el 2026-11-08. Unidad/historial además
  refetchean cada 5 s con guarda (sin eso sus tablas/timeline quedaban
  congeladas en la foto inicial).
- Cobertura: `rebar3 ct` cubre estáticos, `/api/*`, caos por HTTP y regresión
  SSE (`sse_regresion_y_vivos`). No hay test de cadencia de pintado: si tocas
  `app.js`, pasa `node --check priv/static/app.js` y valida en navegador
  contra el Pi con SSE abierto antes de darlo por hecho.

## Trampas que ya costaron tiempo (fase web)

- **prometheus.erl es 6.1.3** (la 5.0.1 no existe en hex) y arrastra el dep
  `ddskerl`. Metricas: gauges `p29_flotilla_*` declarados con
  `prometheus_gauge:declare` (idempotente) y `set` en cada scrape; cuerpo por
  `prometheus_text_format:format()`.
- **El test web usa `web_port 0`** (puerto efímero; default en `arrancar/1`) y el
  teardown es una tupla `fun({SupPid, _Puerto}) -> cerrar(SupPid) end`; con el
  `fun cerrar/1` directo eunit cancela el caso por `badarg` en `unlink` del puerto.

- **`json` no siempre es una app**: en el Pi (OTP 27) existe `json.app`; en otras
  instalaciones OTP vive como módulo dentro de stdlib y `ensure_all_started(json)`
  muere con «no such file or directory json.app». Por eso `json` NO va en
  `applications` del `.app.src`; `p29_flotilla_de_reparto_app:iniciar_json/0` la
  arranca solo si `code:lib_dir(json)` responde.
- **`undefined` NO se codifica como null** en `json:encode/1` (sale como string):
  el atom `null` sí. `p29_json:num/1` convierte undefined → null a mano.
- **El router de cowboy exige formato host-wrapped**:
  `cowboy_router:compile([{'_', Rutas}])`. Una lista plana de rutas explota con
  `function_clause` en `compile_paths/2`.
- **El listener de la web sobrevive al árbol**: el ref vive en `ranch_sup`. `p29_web`
  hace `process_flag(trap_exit)` + `terminate/2` → `cowboy:stop_listener(...)` y, en
  `init`, un stop defensivo idempotente (intenta en `try ... catch`); sin esto los
  re-arranques y los escenarios de test mueren de `{error, already_started}`.
- **`ranch:listeners/0` no existe en ranch 2.x**, no lo uses; el stop defensivo con
  try/catch basta.
- **SSE**: el handler `-behaviour(cowboy_loop)` debe exportar `init/2, info/3,
  terminate/3` y devolver **`{cowboy_loop, Req, Estado, TimeoutMs}`** (el `Req`
  va en medio y el timeout hace que cowboy mande `info(timeout, ...)` cada
  15 s para los latidos). Devolver `{cowboy_loop, Estado, TimeoutMs}` sin el
  `Req` es una bomba: cowboy lo decodifica como `{Mod, Req, State}` (el
  timeout queda como estado y el `Req` vacío) y cada conexión a `/eventos`
  muere con `function_clause` en `cowboy_loop:loop` — bug real de producción
  que dejó de actualizar el mapa en vivo; lo cubre `sse_regresion_y_vivos`
  de la suite CT. En `terminate` desuscribirse del broadcaster. El
  broadcaster es el ÚNICO suscriptor del reloj y no fabrica JSON si no hay
  watchers (el reloj tira a 33 ms).
- **El caos por HTTP pasa por la API del despachador** (`p29_despachador:averiar/1`,
  `urgente/1`), jamás escribiendo ETS desde el handler. Un cuerpo JSON no parseable
  → 400 con `try`, nunca un crash del request process.
- **En la instantánea SSE** la lista de unidades va con la llave `"unidades"` para
  no chocar con los contadores `"vehiculos"` del resumen.

## Trampas previas (fase dominio)

- **BOM UTF-8**: `>` y `Out-File` de PowerShell 5.1 escriben BOM y `erlc` falla con
  «illegal character». Escribe los `.erl` con
  `[IO.File]::WriteAllText($ruta, $txt, (New-Object System.Text.UTF8Encoding($false)))`.
  Lo mismo para `.config`: un BOM en `sys.config` rompe el arranque.
- **EUnit se traga la salida**: el `io:format` de dentro de un test no se ve. Para
  depurar usa `logger:notice/3`, que va a stderr.
- **Timeout de 5 s por leaf**: envolver un `{setup, ...}` en `{timeout, 30, ...}` no lo
  cambia. Para esperar procesos, polling con `erlang:is_process_alive/1` y no
  `receive {'DOWN', ...}`, que el mailbox de eunit sesga.
- **Repro manual con `erl`**: hay que añadir `-pa` de *todas* las libs de
  `_build/test/lib/*/ebin` (cowlib incluida) y construir el array en PowerShell, que no
  expande globs:
  `erl -pa (Get-ChildItem _build/test/lib -Directory | % { Join-Path $_.FullName "ebin" })`
- `simple_one_for_one` exige el child spec en **lista** (`[#{...}]`), no un mapa suelto.

## Cómo saber que sigue bien

- `p29_despachador:invariantes/0` devuelve `ok` o `{error, Lista}`: pendientes con
  unidad asignada, `en_ruta` sin unidad, o `en_ruta` con una unidad muerta. Es la
  verificación de negocio, más útil que contar procesos.
- Corrida de referencia (`config/sys.config`): 901 entregas, ~785 entregadas, ~9–10 %
  fallidas, 15/15 unidades vivas, ~40 reasignaciones, `invariantes ok`.
- El `retraso_medio` de la corrida (~930–945 ticks) es un artefacto del modelo de paradas
  (`ticks_por_parada`), no un bug de la reasignación.
- Las cifras del README (paradas/día, entregas falladas, coste de la última milla) están
  verificadas con fuentes: no las cambies a ojo.

## En el Pi

- El repo vive en `~/erlang-proyectos` (clon de GitHub). Se edita y empuja desde
  Windows y allí se hace `git pull --ff-only`; no hay credenciales de git en el Pi.
- `ssh flotilla 'comando'` **no** carga asdf (bash no interactivo, no lee `.profile`):
  prefija `export PATH=$HOME/.asdf/shims:$HOME/bin:$PATH` o usa `bash -lc '...'`.
  erl, erlc y rebar3 están en `~/.asdf/shims` y `~/bin`.
- **Las comillas dobles y las contrabarras mueren en el tránsito PowerShell→ssh**: un
  `-d '{"unidad":7}'` llega roto al bash remoto (la API responde
  `{"error":"se_espera_unidad_entera"}`) y el canal además se come *una* contrabarra
  (probado con la UI 0.3.0). Para mandar JSON desde Windows, escríbelo en el Pi sin
  una sola comilla doble en la línea, con `printf` octal y contrabarras dobladas:
  `printf '\\173\\042unidad\\042\\0727\\175' > /tmp/u.json;`
  `curl -s -X POST -H 'Content-Type: application/json' --data @/tmp/u.json ...`
  (`\173`=`{`, `\042`=`"`, `\072`=`:`, `\175`=`}`).
- `sudo` no pide contraseña; hay 26 GB libres y las deps de `_build` ya están bajadas
  (si borras `_build`, rebar3 vuelve a hex.pm).
- Antes de dar algo por desplegado: `rebar3 compile` y `rebar3 eunit` **en el Pi**;
  OTP/aarch64 puede comportarse distinto que en Windows (pasó con la demo: ver abajo).
- `config/vm.args` fija `+S 4:4`: nunca pongas más schedulers que cores físicos.
- `config/sys.config` lleva los envs de la demo, no secretos; la cookie de `vm.args`
  (`cambiar_en_produccion`) es de ejemplo y se cambia al desplegar.
- El servicio corre el release de **`_build/default/rel/`** (ver
  `deploy/p29-flotilla.service`), no `_build/prod/rel/`: `rebar3 release` y
  comprobar que el binario de esa ruta es el que está en `systemctl status`.
  Reconstruir sin reiniciar el servicio deja en `:8080` el release viejo con
  estáticos viejos.
- Cotejo rápido Pi vs local (todo lectura, vía `ssh flotilla`):
  `md5sum priv/static/app.js src/p29_json.erl config/sys.config` en ambos
  lados; `git rev-parse HEAD` en ambos; en el Pi
  `curl -s -o /dev/null -w '%{time_total}' http://127.0.0.1:8080/api/entregas`
  para separar "lento en el navegador" (~12 ms en Pi) de "lento a través del
  proxy de Corellium". Antes de desplegar: `git fetch` en Windows, comparar
  HEAD local vs `origin/main`, editar y empujar desde Windows, y solo entonces
  `git pull --ff-only` en el Pi (un clon viejo desplegado sirvió estáticos
  con botones/hrefs rotos ya corregidos aguas arriba).
