# 29 — Flotilla de reparto (AeroCargo) · notas para agentes

Solo recoge lo que no se deduce leyendo el código. No hay `AGENTS.md` de raíz en este repo al que referirse; el de este proyecto es la fuente de reglas. Si algo aquí choca con `README.md` o `rebar.config`, gana el ejecutable.

## Dónde se trabaja

- Es una app rebar3 **independiente**: todos los comandos se corren desde esta carpeta (`proyectos/29-flotilla-de-reparto`), no desde la raíz del repo (allí no hay `rebar.config`).
- **Destino final:** Raspberry Pi 4 Model B, Debian 11 (bullseye), 4 cores, 3.8 GB, OTP 27.3.4.19 vía asdf. No des por hechas rutas ni versiones de otras máquinas. Se entra con `ssh flotilla` (alias en `~/.ssh/config` que salta por el proxy de Corellium). El jump host, su token y la contraseña **no van al repo**; viven solo en la configuración SSH local.
- **Segunda máquina de pruebas:** `curso-plf` (AWS, Erlang/OTP **25**, rebar3 3.19, alias `~/.ssh/config`; credenciales efímeras ~4 h). El código debe compilar y pasar `rebar3 eunit` en **ambas** OTP.
- El escritorio es Windows con PowerShell 5.1: los comandos de abajo son PowerShell, no bash.

## Comandos (desde la raíz del proyecto)

```powershell
rebar3 compile      # warnings_as_errors: un solo warning rompe el build
rebar3 eunit        # 29 casos en 9 escenarios (árbol, asignación, statem, avería, señal, caos, demo, web, adsb)
rebar3 ct           # 8 casos de integración (app completa: estáticos, /api/*, caos por HTTP, regresión SSE)
rebar3 shell        # web en :8080 + desde acá: p29_simulador:demo(). (jornada completa, ~72 s)
rebar3 release      # _build/default/rel/p29_flotilla_de_reparto (NO prod: ver deploy/)
```

Un caso suelto: `rebar3 eunit --test=p29_flotilla_de_reparto_tests:arbol_despues_de_arrancar_test_`

La suite tiene **29 casos eunit + 8 ct**. Si `rebar3 eunit` dice más de 29, es que un beam quedó duplicado en `_build/test/lib/p29_flotilla_de_reparto/ebin`: borra el beam de `ebin` y vuelve a correr.

La demo imprime el resumen al terminar; para mirar el estado en vivo: `p29_despachador:estado()`, `p29_datos:entregas_todas()` (nombres actuales: `p29_aeronaves`, `p29_envios`; los legacy `vehiculos`/`entregas` son alias de backward compat).

## Gemelo digital (Prolog) — `gemelo/`

El gemelo es un **servidor SWI-Prolog independiente**, separado de la app Erlang/OTP. No toca código Erlang ni `../problema/readme.md`.

- Ubicación: `gemelo/` (`hechos.pl`, `reglas.pl`, `servidor.pl`, `web/`, `tests/reglas_tests.pl`)
- Stack: SWI-Prolog 10 (probado 10.0.2 en Windows), bibliotecas estándar solo (`plunit`, `lists`, `heaps`, `library(http/…)`). **Sin Janus, sin Python, sin dependencias externas.**
- El "ahora" es un hecho (`ahora(300)` = 13:00, minutos desde las 08:00). Ninguna regla usa `get_time/1`, `random/1` ni fecha del sistema.
- Toda la lógica de dominio vive en `reglas.pl`; la interfaz de `web/` solo consulta `/api/*` y pinta. Nada de capacidad, ventanas, prioridades ni veredictos en JavaScript.

### Comandos del gemelo

```powershell
# pruebas del modelo (28 casos plunit; verde = exit 0)
swipl -q -g run_tests -t halt tests/reglas_tests.pl

# servidor + interfaz en http://127.0.0.1:8089/
swipl servidor.pl

# otro puerto (variable de entorno o argumento posicional)
$env:GEMELO_PORT = 8090; swipl servidor.pl
swipl servidor.pl 8091
```

### Endpoints de la API del gemelo (`/api/`)

| Endpoint | Qué devuelve |
|---|---|
| `GET /api/estado` | ahora, jornada, unidades (posición, capacidad, carga, libre, ruta, silencio, horas), puntos, tramos (base y observado), entregas, situaciones deducidas |
| `GET /api/plan?entregas=e4,e7` | planes válidos con explicación, `no_cambia` y `sin_plan` (diagnóstico). Sin parámetro usa las pendientes de la unidad averiada |
| `GET /api/urgente` | pedido, candidatas con evaluación, elegida, prioridad declarada y `que_falta` |
| `GET /api/silencio?unidad=u2` | `en_duda`, reporte, veredicto y evidencia por entrega, reasignadas y huérfanas |
| `GET /api/llegadas?unidad=u1` | llegada mínima/máxima y veredicto por parada, horas del conductor, tramos lentos |
| `GET /api/fallidas` | por fallida: motivo, destino (`no_ubicable`, `reintento_hoy(u)`, almacén), evidencia e impacto en capacidad |
| `GET /api/que_falta?objetivo=urgente_sin_romper\|plan_averia` | la pregunta al revés: qué unidades o cambios harían falta |
| `GET /api/prioridad` | la prioridad declarada del urgente, en un solo lugar |

### Problemas conocidos del gemelo (ver antes de tocar)

- **Encoding roto en comentarios de `.pl`:** `servidor.pl` (línea 1) y `hechos.pl` (línea 1) tienen comentarios con mojibake UTF-8 (caracteres tipo `ÃƒÆ’`). Los archivos declaran `:- encoding(utf8).` pero los comentarios están corruptos. Escribe siempre **UTF-8 sin BOM**; no reescribas comentarios si no es necesario.
- **Servidores separados:** la IU principal (Erlang/Cowboy) corre en `:8080`; el gemelo (Prolog) corre en `:8089`. No comparten sesión ni cookies. Un botón de navegación entre ellos abre el gemelo en otra pestaña/puerto.

### Pendiente de entrega: botón al gemelo + pulido de IU del gemelo

1. **Botón en la IU principal (`priv/static/index.html`):** añadir un botón "Gemelo digital" en el `<nav>` de la cabecera o en la barra de herramientas inferior que abra `http://127.0.0.1:8089/` (o el puerto del gemelo). Como son servidores distintos, usar `target="_blank"` o redirección a `:8089`. Usar los tokens de diseño de `design/Plantilla Flotilla de Reparto/aeroterra_dispatch_telematics/DESIGN.md` (colores, tipografía Chivo/Geist/JetBrains Mono, componentes tácticos) para que coincida visualmente con el resto de la app.
2. **Desfases de alineación en la IU del gemelo (`gemelo/web/`):** revisar a detalle y corregir:
   - `.punto` del mapa tiene `white-space:nowrap`: nombres largos de puntos pueden salirse del contenedor del mapa SVG.
   - Tablas con `.tabla-scroll` y `min-width:520px` pueden desbordarse en pantallas estrechas/móvil.
   - Insignias (`.insignia`) con texto largo se ensanchan y rompen la alineación de filas.
   - Verificar alineación en tabla de entregas, plan, urgente, silencio, llegadas y fallidas: que ningún texto se salga de su celda ni de su panel.
   - En móvil: la rejilla pasa a una columna y el mapa a `aspect-ratio:1/1`; que nada quede recortado ni solapado.
   - Los tokens de color/espaciado deben heredar de AeroCargo (Stitch), no inventar valores.

## Arquitectura que no se ve en los nombres

- `rest_for_one`: datos → reloj → rutas → meteo → ADS-B → despachador → aeronaves_sup → envios_sup → transbordo_sup → broadcaster → web. El orden es la dependencia real; si cae un eslabón se reinicia todo lo que está después.
- Las tablas ETS `p29_envios` / `p29_aeronaves` son **caché de lectura**. El dueño de cada fila es el `gen_statem` del envío o el `gen_server` de la aeronave: nunca escribas ETS desde otro proceso ni desde un handler HTTP, usa la API (`p29_envio:*`, `p29_despachador:*`).
- `p29_reloj` es el único dueño del tiempo. Nada de `erlang:monotonic_time/0` ni `timer:sleep` en el dominio: rompe la reproducibilidad y los tests con reloj manual.
- Determinismo deliberado: flota, pesos, rutas y ventanas salen de `erlang:phash2`, no de `rand`. Meter `rand` sin semilla hace fallar `simulador_test_`.
- La jornada cuenta desde el tick en que arranca (`T0 = tick_actual()`), no desde 0 absoluto. La avería/el urgente se inyectan con `>=` una sola vez.
- El despachador atrapa salidas (`trap_exit`) y detecta muertes por monitores `'DOWN'`; las unidades se relanzan bajo `p29_aeronaves_sup`. Si tocas el arranque, respeta `esperar_sup`.
- La UI se implementa desde la maqueta de Stitch en `design/Plantilla Flotilla de Reparto/`. Los `code.html` son Tailwind por CDN con `onclick` inline: se portan a estáticos de cowboy, no se sirven tal cual.
- Las 5 pantallas viven en `priv/static/` (`index`, `unidad`, `unidad-enfocada`, `historial`, `configuracion`) y las genera/actualiza `tools/stitch_port/port.py`; el CSS sale de `tools/stitch_port/gen_css.py` → `priv/static/stitch.css` (no editar a mano). `app.js` es la única hoja de hidratación y decide por `body[data-page]`.

## UI bajo carga: botones que parecen muertos (diagnóstico verificado 2026-11-08)

- El reloj corre a 33 ms (~30 ticks/s) y el broadcaster emite un evento SSE `estado` por tick.
- Sin espectadores SSE no hay JSON y todo vuela. La solución implementada: `app.js` acumula el último evento SSE y pinta cada 160 ms con `requestAnimationFrame`, el mapa reusa divs por id, `unidad`/`historial` tienen guarda anti-solapado y el dashboard ya no pide `/api/aeronaves` por tick. Refetchean cada 5 s con guarda.
- No reintroduzcas fetches por tick en ninguna página, incluida la del gemelo si se acopla.

## OTP 25 (curso-plf): qué no se puede usar

El código es retrocompatible OTP 25↔27. Rompe el build en OTP 25 si reintroduces:

- **Módulo `json`** (llegó en OTP 27): árbol de salida SIEMPRE via `p29_json:json/1`; decodificación via `p29_api:json_decodificar/1`.
- **Map comprehensions** (`#{K => V || ...}`, OTP 26+): usa `maps:from_list([{...} || K <- maps:keys(M)])`.
- **`erlang:floor/1`** como import automático choca con `math:floor/1` en OTP 25: requiere `-compile({no_auto_import,[floor/1]}).`.
- **`rebar.lock` NO existe en este proyecto**: si tu `_build` local (OTP 29+) lo regenera y lo commiteas, fija `prometheus 6.1.3` (requiere OTP 26+) y el build en curso-plf muere. `prometheus` está pinneado a **4.11.0** en `rebar.config`.
- Verificación SIEMPRE en curso-plf (OTP 25).

## Trampas de desarrollo y despliegue (Pi)

- **BOM UTF-8:** Escribe los `.erl` y `sys.config` con `[IO.File]::WriteAllText($ruta, $txt, (New-Object System.Text.UTF8Encoding($false)))`.
- **`ssh flotilla 'comando'` no carga asdf:** prefija `export PATH=$HOME/.asdf/shims:$HOME/bin:$PATH` o usa `bash -lc '...'`.
- **Comillas y contrabarras en SSH desde PowerShell:** para mandar JSON, usa `printf` octal:
  `printf '\\173\\042aeronave\\042\\0727\\175' > /tmp/u.json; curl -s -X POST -H 'Content-Type: application/json' --data @/tmp/u.json ...`
- **Release en la RPi:** systemd debe usar `bash -c` y `rebar.config` debe llevar `{include_erts, true}, {system_libs, true}`.
- Antes de dar por desplegado: `rebar3 compile` y `rebar3 eunit` **en el Pi**; OTP/aarch64 puede comportarse distinto que Windows.
- `config/vm.args` fija `+S 4:4`: nunca más schedulers que cores físicos.
- `config/sys.config` lleva envs de demo, no secretos; la cookie vive en `/etc/p29-flotilla.env` (chmod 600, `EnvironmentFile` de la unidad, `RELX_REPLACE_OS_VARS=true`).
- Servicio corre release de `_build/default/rel/` (ver `deploy/p29-flotilla.service`). Reconstruir sin reiniciar servicio deja en `:8080` release viejo con estáticos viejos.
- Cotejo rápido Pi vs local (lectura vía `ssh flotilla`): `md5sum priv/static/app.js src/p29_json.erl config/sys.config` en ambos lados; `git rev-parse HEAD`; `curl -s -o /dev/null -w '%{time_total}' http://127.0.0.1:8080/api/aeronaves`.

## Código legacy

`p29_vehiculo`, `p29_entrega`, `p29_flota_sup` y `p29_entregas_sup` ya no están en el árbol de supervisión (quedaron del pivot tierra→aire); `p29_entregas_sup` arranca un `p29_entrega` que llama a `p29_despachador:reportar_gps/4`, función que no existe. Decidir si se borran o se marcan `deprecated`.

## Segundo Cerebro (obligatorio al cerrar)

Bóveda: `C:\Users\Max\Desktop\obsidian\Maximiliano`. Al cerrar la sesión, crea/actualiza la nota en `Sesiones/` (`AAAA-MM-DD - Título.md`, frontmatter + 5 secciones) y enlaza con `[[ ]]` desde `MOC_SegundoCerebro.md`. Responde y escribe notas en **español**.
