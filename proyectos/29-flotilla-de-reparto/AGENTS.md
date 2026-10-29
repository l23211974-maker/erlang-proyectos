# 29 — Flotilla de reparto · notas para agentes

Las reglas del curso (stack obligatorio, estilo, flujo de Stitch) están en el
[`AGENTS.md` de la raíz](../../AGENTS.md). Este archivo solo recoge lo que se aprende
trabajando aquí y que no se deduce leyendo el código.

## Dónde se trabaja

- Es una app rebar3 **independiente**: todos los comandos se corren desde esta carpeta,
  no desde la raíz del repo (allí no hay `rebar.config`).
- El destino final es el **Raspberry Pi del estudiante** (aarch64, Debian 13, OTP 27,
  4 cores), no la máquina de desarrollo: `ssh flotilla` (alias en `~/.ssh/config` que
  salta por el proxy de Corellium). El jump host, su token y la contraseña **no van al
  repo**; viven solo en la configuración SSH local.
- El escritorio del estudiante es Windows con PowerShell 5.1: los comandos de abajo son
  PowerShell, no bash.

## Comandos

```powershell
rebar3 compile      # warnings_as_errors: un solo warning rompe el build
rebar3 eunit        # 20 tests, 0 fallos = verde
rebar3 shell        # dentro: p29_simulador:demo().  (jornada completa, ~72 s)
rebar3 release      # _build/prod/rel/p29_flotilla_de_reparto
```

- Un caso suelto: `rebar3 eunit --test=p29_flotilla_de_reparto_tests:arbol_despues_de_arrancar_test_`
- `--module=p29_flotilla_de_reparto_tests` corre **10 de los 20** casos: no sirve como
  verificación final, solo para iterar.
- La demo imprime el resumen al terminar; para mirar el estado en vivo:
  `p29_despachador:estado()`, `p29_datos:entregas_todas()`.

## Arquitectura que no se ve en los nombres

- `rest_for_one`: datos → reloj → despachador → flota_sup → entregas_sup. El orden es la
  dependencia real; si cae un eslabón se reinicia todo lo que está después.
- Las tablas ETS `p29_entregas` / `p29_vehiculos` son **caché de lectura**. El dueño de
  cada fila es el `gen_statem` de la entrega o el `gen_server` de la unidad: nunca
  escribas ETS desde otro proceso ni desde un handler HTTP, usa la API
  (`p29_entrega:*`, `p29_despachador:*`).
- `p29_reloj` es el único dueño del tiempo. Nada de `erlang:monotonic_time/0` ni
  `timer:sleep` en el dominio: rompe la reproducibilidad y los tests con reloj manual.
- El determinismo es deliberado: flota, pesos, colonias y ventanas salen de
  `erlang:phash2`, no de `rand`. Meter `rand` sin semilla hace fallar `simulador_test_`
  (comprueba cifras exactas).
- El despachador atrapa salidas (`trap_exit`) y detecta muertes por monitores `'DOWN'`;
  las unidades se relanzan bajo `p29_flota_sup`. Si tocas el arranque, respeta
  `esperar_sup`: sin el supervisor dinámico nadie relanza unidades muertas.
- La UI se implementa desde la maqueta de Stitch en `design/Plantilla Flotilla de
  Reparto/`. Los tokens están en
  `design/Plantilla Flotilla de Reparto/aeroterra_dispatch_telematics/DESIGN.md`; **no**
  en `design/DESIGN.md`, que no existe. Los `code.html` son Tailwind por CDN con
  `onclick` inline: se portan a estáticos de cowboy, no se sirven tal cual.

## Trampas que ya costaron tiempo

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
- El `retraso_medio` de la corrida (~944 ticks) es un artefacto del modelo de paradas
  (`ticks_por_parada`), no un bug de la reasignación.
- Las cifras del README (paradas/día, entregas falladas, coste de la última milla) están
  verificadas con fuentes: no las cambies a ojo.

## En el Pi

- Antes de dar algo por desplegado: `rebar3 compile` y `rebar3 eunit` **en el Pi**;
  OTP/aarch64 puede comportarse distinto que en Windows.
- `config/vm.args` fija `+S 4:4`: nunca pongas más schedulers que cores físicos.
- `config/sys.config` lleva los envs de la demo, no secretos; la cookie de `vm.args`
  (`cambiar_en_produccion`) es de ejemplo y se cambia al desplegar.
