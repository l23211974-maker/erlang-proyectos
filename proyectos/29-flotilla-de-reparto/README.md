# AeroCargo — Flotilla Multimodal de Transporte Aéreo

> **Proyecto #29** — Simulación de despacho multimodal de carga aérea y terrestre con telemetría en tiempo real, reasignación automática y panel de operaciones táctico.

**Dominio:** aviación y transporte multimodal (aéreo internacional + troncal terrestre + última milla)  
**Stack:** Erlang/OTP 25+ (retrocompatible), rebar3, Cowboy 2.12, Prometheus 4.11, Thoas/JSON, HTML/CSS/JS plano (sin frameworks) servido por Cowboy  
**Diseño visual:** Export de Google Stitch "AeroCargo Telematics & Dispatch Operations" — dark slate, tipografía Chivo/Geist/JetBrains Mono, semántica táctica tricolor (Esmeralda/Ámbar/Carmesí)

---

## Tabla de contenidos

- [Arquitectura OTP](#arquitectura-otp)
- [Comandos de desarrollo](#comandos-de-desarrollo)
- [API y Endpoints web](#api-y-endpoints-web)
- [Diseño visual (Stitch)](#diseño-visual-stitch)
- [Pantallas implementadas](#pantallas-implementadas)
- [Despliegue en Raspberry Pi](#despliegue-en-raspberry-pi)
- [Referencias](#referencias)

---

## Arquitectura OTP

```
p29_sup (rest_for_one)
├── p29_datos           (gen_server: tablas ETS de solo lectura p29_envios / p29_aeronaves)
├── p29_reloj           (gen_server: único dueño del tiempo; emite {p29_tick, N})
├── p29_ruta_vectorial  (gen_server: rutas vectoriales waypoint-a-waypoint, Great Circle)
├── p29_meteo           (gen_server: frentes tormentosos, CBs, turbulencia, viento en altura)
├── p29_adsb            (gen_server: simulación ADS-B OUT 1090 MHz cada 10s)
├── p29_adsb_receptor   (gen_server: receptor ADS-B, correlación con flota)
├── p29_despachador     (gen_server: asigna, reasigna, watchdog de señal, averías, urgencias)
├── p29_aeronaves_sup   (simple_one_for_one: un gen_server p29_aeronave por unidad)
├── p29_envios_sup      (simple_one_for_one: un gen_statem p29_envio por envío)
├── p29_transbordo_sup  (simple_one_for_one: transbordos en hubs)
├── p29_broadcaster     (gen_server: único suscriptor del reloj; difunde instantáneas a SSE)
└── p29_web             (gen_server: listener cowboy — estáticos, /api/*, /eventos, /metrics)
```

### Por qué `rest_for_one` y este orden

Las dependencias arrancan en orden: sin tablas no hay filas que escribir, sin reloj no hay ticks, sin rutas no hay plan de vuelo, sin meteo no hay alertas, sin ADS-B no hay telemetría, sin despachador nadie organiza, y solo entonces existen aeronaves y envíos para quien ya hay quien los ordene. Si algo intermedio cae, todo lo que depende de él se re-arranca en bloque.

### Reglas de dominio inmutables

- **ETS es caché de lectura**: el dueño de cada fila es el `gen_statem` del envío o el `gen_server` de la aeronave. Nunca escribas ETS desde otro proceso ni desde handler HTTP; usa la API (`p29_envio:*`, `p29_despachador:*`).
- **Reloj único**: `p29_reloj` es el único dueño del tiempo. Nada de `erlang:monotonic_time/0` ni `timer:sleep` en el dominio: rompe reproducibilidad y tests con reloj manual.
- **Determinismo**: flota, pesos, rutas y ventanas salen de `erlang:phash2`, no de `rand`. Meter `rand` sin semilla hace fallar `simulador_test_`.
- **Jornada desde T0**: el simulador cuenta desde el tick en que arranca (`T0 = tick_actual()`), no desde 0 absoluto. La avería/urgente se inyectan con `>=` una sola vez.
- **Despachador atrapa salidas** (`trap_exit`) y detecta muertes por monitores `'DOWN'`; las unidades se relanzan bajo `p29_aeronaves_sup`. Si tocas el arranque, respeta `esperar_sup`.

---

## Comandos de desarrollo

Todos los comandos se ejecutan **desde la raíz del proyecto** (`C:\Users\Max\dev\erlang-proyectos\proyectos\29-flotilla-de-reparto`):

```powershell
rebar3 compile      # warnings_as_errors: un solo warning rompe el build
rebar3 eunit        # 11 casos en 9 escenarios (árbol, asignación, statem, avería, señal, caos, demo, web)
rebar3 ct           # 3 casos de integración (app completa: estáticos, /api/*, regresión SSE)
rebar3 shell        # web en :8080 + de aquí: p29_simulador:demo().
```

Un caso suelto:
```powershell
rebar3 eunit --test=p29_flotilla_de_reparto_tests:arbol_despues_de_arrancar_test_
```

La demo corre la jornada completa (2160 ticks GPS de 10 s simulados cada 33 ms, ~72 s reales), inyecta avería al ~46% y pedido urgente al 75%, termina imprimiendo estado final.

---

## API y Endpoints web

| Ruta | Qué sirve |
|---|---|
| `/` | Dashboard: KPIs tácticos, mapa vectorial GPS en vivo, flota activa con filtros, feed de alertas |
| `/unidad.html?id=N` | Ficha de aeronave + botón de caos *inyectar avería* + panel de reasignación + radar + ACARS |
| `/historial.html` | Bitácora de telemetría y alertas con filtros tácticos, exportación IFR |
| `/api/aeronaves` | JSON de la flota con terminología AeroCargo |
| `/api/envios` | JSON de envíos con terminología AeroCargo |
| `/api/vehiculos` | **Backward compat** - alias de `/api/aeronaves` |
| `/api/entregas` | **Backward compat** - alias de `/api/envios` |
| `/api/estado` | Resumen + invariantes (`aeronaves`, `envios`, `reasignaciones`, `transbordos`, `retraso_medio`) |
| `/api/averiar` | **POST** `{"aeronave": N}` o `{"unidad": N}` — inyecta avería/desvío |
| `/api/urgente` | **POST** — alta de envío urgente AOG (nueva + legacy terminology) |
| `/eventos` | SSE: un evento `estado` por tick con resumen + instantánea de unidades |
| `/metrics` | Prometheus (gauges `p29_flotilla_*` + métricas de VM) |

### Métricas Prometheus (nuevas familias AeroCargo)

```prometheus
# Nuevas familias AeroCargo
p29_flotilla_aeronaves{estado="en_ruta|en_tierra|critico|alerta"}
p29_flotilla_envios{estado="pendiente|en_ruta|entregada|fallida|desviada"}
p29_flotilla_transbordos_total

# Backward compat (se mantienen para dashboards existentes)
p29_flotilla_vehiculos{estado="en_ruta|en_tierra"}
p29_flotilla_entregas{estado="pendiente|en_ruta|entregada|fallida"}
p29_flotilla_retraso_medio
p29_flotilla_reasignaciones_total
```

---

## Diseño visual (Stitch)

### Paleta táctica (source of truth: `design/stitch_aerocargo/aerocargo_telematics_dispatch_operations/DESIGN.md`)

```css
/* Superficies */
--canvas-default:     #0B1120;  /* Negro Espacial Profundo */
--surface-base:       #0F172A;  /* Azul Pizarra Base */
--surface-elevated:   #1E293B;  /* Pizarra Elevada / Contenedores */
--surface-overlay:    #334155;  /* Bordes activos, divisores */

/* Marca y acción */
--primary:            #0284C7;  /* Azul Vector */
--primary-active:     #38BDF8;  /* Luz de radar / Foco */

/* Semántica táctica (estricta) */
--status-ok:          #10B981;  /* Esmeralda Operativa: nominal, a tiempo, GPS estable */
--status-warning:     #F59E0B;  /* Ámbar Radar: meteo moderada, retraso, recalibración */
--status-critical:    #EF4444;  /* Carmesí Alerta: desvío, falla crítica, emergencia */
--status-info:        #38BDF8;  /* Cian Aviónica: balizas, aproximación, telemetría pasiva */

/* Texto */
--text-primary:       #F8FAFC;
--text-secondary:     #94A3B8;
--text-muted:         #64748B;
```

### Tipografía

- **Chivo** (600/700): Headers, títulos de sección, alertas
- **Geist** (400/500/600): UI, datos de manifiesto, cuerpo
- **JetBrains Mono** (500/700): Coordenadas, telemetría, contadores, códigos

### Componentes clave

1. **Botones Tácticos**: Primario (Azul Vector), Crítico (Carmesí), Secundario (Filtro)
2. **Badges/Chips de estado**: NOMINAL (verde + punto), ALERTA (ámbar + pulso lento), CRÍTICO (carmesi + pulso 1Hz)
3. **Tarjeta de Aeronave**: Chasis `#1E293B`, cabecera ID + ruta + badge, cuadrícula 3x1 telemetría (FL, GS, Payload), mini-barra de progreso de ruta
4. **Inputs/Selects**: Fondo `#0B1120`, foco con glow `#0284C7`, selectores de flota agrupados por sector
5. **Lista de Eventos de Despacho**: Filas alternadas, timestamp monoespaciado UTC/Local, código evento, mensaje, acción rápida
6. **Mapa Vectorial (Canvas)**: Grid táctico, anillos concéntricos, rutas con gradientes semánticos, pins interactivos con ficha telemetría

---

## Pantallas implementadas

| Archivo | Pantalla | Descripción |
|---|---|---|
| `priv/static/index.html` | Dashboard | Consola de mando, 4 KPIs tácticos, mapa vectorial multimodal, tabla de flota activa con filtros, terminal de alertas |
| `priv/static/unidad.html` | Detalle Aeronave | Cabecera aeronave, 6 gauges telemetría (Altitud, Vel. Tierra, Heading, V/S, Combustible, Carga Útil), manifiesto crítico, panel decisión reasignación (radio options + calculador impacto), mapa radar con fixes de decisión, intercom ACARS |
| `priv/static/historial.html` | Bitácora/Alertas | Filtros tácticos (búsqueda, severidad, ventana temporal, segmento), 3 KPIs (MTTR, OTP, Safety), stream cronológico de eventos con modales GPS/Reasignación, export IFR |

### Optimizaciones de rendimiento (app.js)

- **requestAnimationFrame** para todas las actualizaciones visuales (batched rendering at max 2Hz)
- **Dirty flag system** - solo re-renderiza lo que cambió realmente
- **SSE throttled** (500ms mínimo entre lotes de procesamiento)
- **Canvas-based radar** (60fps capable vs SVG DOM thrashing)
- **Virtualized fleet list** - solo renderiza items visibles + buffer
- **Event delegation** - single listener vs per-element listeners
- **DOM reuse / element pooling** - no innerHTML replacement en cada tick
- **Projection cache** - transformadas de coordenadas memoizadas
- **Formatter caches** - formateo de números/fechas memoizado
- **Proper cleanup** - animation frames, event listeners, caches on unload
- **Visibility change handling** - pausa rendering cuando tab hidden

**Resultado:** Elimina congelación de botones, asegura respuesta inmediata de UI bajo carga pesada de datos SSE.

---

## Despliegue en Raspberry Pi (producción)

- Repo en `~/erlang-proyectos` (clon GitHub). Se edita/empuja desde Windows y allí `git pull --ff-only`; no hay credenciales git en el Pi.
- `ssh flotilla 'comando'` **no** carga asdf (bash no interactivo): prefija `export PATH=$HOME/.asdf/shims:$HOME/bin:$PATH` o usa `bash -lc '...'`.
- **Comillas dobles y contrabarras mueren en PowerShell→ssh**: para mandar JSON desde Windows, escríbelo en el Pi sin comillas dobles en la línea, con `printf` octal y contrabarras dobladas:
  `printf '\\173\\042aeronave\\042\\0727\\175' > /tmp/u.json; curl -s -X POST -H 'Content-Type: application/json' --data @/tmp/u.json ...`
- `sudo` sin contraseña; 26 GB libres; deps en `_build` ya bajadas.
- Antes de dar por desplegado: `rebar3 compile` y `rebar3 eunit` **en el Pi**; OTP/aarch64 puede comportarse distinto que Windows.
- `config/vm.args` fija `+S 4:4`: nunca más schedulers que cores físicos.
- `config/sys.config` lleva envs de demo (waypoints, FL, kts, payload tons, SLA ventanas, meteo), no secretos; cookie de `vm.args` (`cambiar_en_produccion`) se cambia al desplegar.
- Servicio corre release de **`_build/default/rel/`** (ver `deploy/p29-flotilla.service`), NO `_build/prod/rel/`: `rebar3 release` y comprobar binario en `systemctl status`. Reconstruir sin reiniciar servicio deja en `:8080` release viejo con estáticos viejos.
- Cotejo rápido Pi vs local (lectura vía `ssh flotilla`):
  `md5sum priv/static/app.js src/p29_json.erl config/sys.config` en ambos lados
  `git rev-parse HEAD` en ambos
  En Pi: `curl -s -o /dev/null -w '%{time_total}' http://127.0.0.1:8080/api/aeronaves` para separar "lento en navegador" (~12ms en Pi) de "lento por proxy Corellium".

---

## Referencias

- **Repo original (especificación base)**: https://github.com/tectijuana/erlang-proyectos/tree/main/proyectos/29-flotilla-de-reparto
- **Fork con trabajo actual (AeroCargo)**: https://github.com/l23211974-maker/erlang-proyectos/tree/main/proyectos/29-flotilla-de-reparto
- **Manual Pi + métricas (gist)**: https://gist.github.com/l23211974-maker/f754a5fa477b148f2cdc2f36a10a76a8
- **Documento "Importancia de Erlang"**: https://gist.github.com/l23211974-maker/7aa4a94d57b4eb7b17b89f21d18928cb
- **Diseño Stitch AeroCargo**: `C:\Users\Max\Downloads\stitch_gestor_de_flotilla_a_rea.zip` (descomprimido en `design/stitch_aerocargo/`)

---

## Próximos pasos

1. **Actualizar sys.config** con parámetros de aviación reales (waypoints AIP, FL máximos por tipo, kts por régimen, payload tons, SLA ventanas, meteo SIGMET)
2. **Tests de caos extendidos**: pérdida de señal ADS-B por sector, meteo severa generalizada, fallo de hub principal
3. **Verificar OTP 25**: `rebar3 compile` + `rebar3 eunit` en curso-plf antes de merge
4. **Desplegar en Pi**: validar release, systemd, métricas, SSE en vivo

---

## Notas para el agente

- **No dupliques lógica**: usa los módulos existentes como base; el pivot es semántico (tierra→aire), la arquitectura OTP se mantiene.
- **Respeta OTP 25**: cualquier cambio debe compilar y pasar tests en OTP 25 (curso-plf) y OTP 27+ (local/Pi).
- **Tokens de diseño**: toma colores, tipografía, espaciado, componentes del `DESIGN.md` de Stitch; no inventes valores.
- **SSE bajo carga**: el diagnóstico 2026-11-08 sigue válido — desacopla pintado del tick (rAF + bandera), no refetchees `/api/aeronaves` por tick, reusa mapa, estrangula SSE tras jornada.
- **PowerShell 5.1 en Windows**: escribe archivos UTF-8 sin BOM; usa `bash -s` con heredoc para comandos remotos ssh.
- **Segundo Cerebro**: al cerrar sesión, crea/actualiza nota en `C:\Users\Max\Desktop\obsidian\Maximiliano\Sesiones/` y enlaza desde `MOC_SegundoCerebro.md`.