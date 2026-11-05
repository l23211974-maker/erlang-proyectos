# Guion de demo y argumentación — #29 Flotilla de reparto

Guía de la presentación en clase (~10 min de demo) alineada con la rúbrica.
Todo lo aquí descrito está verificado en la Raspberry Pi 4 del curso
(Debian 11, OTP 27.3.4.19). Verificar cada paso ANTES de la exposición: la
clave es que el release esté corriendo como servicio y el túnel del
dashboard abierto de antemano.

## Antes de la clase (checklist de preparación)

```bash
ssh flotilla                      # o el -J directo al proxy de Corellium
# 1. el servicio vivo (si lo detuviste en pruebas, retomarlo):
sudo systemctl start p29-flotilla
systemctl is-active p29-flotilla
# 2. el release verde en la API:
curl -s http://127.0.0.1:8080/api/estado | head -c 200
# 3. túnel a tu computadora para mostrar el dashboard:
ssh -J <token>@proxy.app.avh.corellium.com -L 8080:127.0.0.1:8080 pi@10.11.0.3
#    y abrir http://localhost:8080 en el navegador
# 4. regla de seguridad: NINGÚN rebar3 shell ocupando el 8080 antes de la
#    demo (el servicio y la shell se pelean por el puerto: eaddrinuse).
```

## Estructura de la demo (argumentación y tiempos)

1. **El problema (1 min).** La última milla es la etapa más cara y con más
   fallas del reparto (~10 % de entregas fallan al primer intento, 50-150
   paradas por unidad/día — cifras verificadas con fuentes en el README).
   #29 simula eso: 15 unidades, 900 entregas, GPS cada 10 s, avería a media
   tarde y un pedido urgente a media jornada.

2. **La arquitectura OTP (2 min).** Abrir el README y caminar el árbol
   `p29_sup (rest_for_one)`:
   - datos → reloj → despachador → flota_sup → entregas_sup → broadcaster
     → web: el ORDEN es la dependencia real; si cae un eslabón, todo lo
     posterior se re-arranca en bloque (el dashboard nunca queda "verde"
     sobre datos muertos).
   - un `gen_statem` (p29_entrega) dueño de cada paquete; solo su proceso
     escribe su fila ETS → ni huérfanas ni duplicadas; se comprueba con
     `p29_despachador:invariantes().` devolviendo `ok`.
   - un `gen_server` por unidad con movimiento en la rejilla y reporte GPS
     por tick: concurrencia real, un proceso por dominio de datos.

3. **La demo en vivo (4 min).** En el dashboard (túnel):
   - mapa GPS moviéndose por SSE (`/eventos`): las unidades avanzan por la
     rejilla y las cifras del manifiesto cambian con cada tick;
   - caos desde la UI: botón *inyectar avería* en `/unidad.html?id=N` → la
     carga reaparece repartida entre las unidades vivas en el próximo tick
     y `reasignaciones` sube;
   - pedido urgente por `/api/urgente` (curl) y cómo el despachador lo
     atiende antes que los demás (urgente primero en el greedy);
   - si piden la jornada COMPLETA en vivo: `rebar3 shell` +
     `p29_simulador:demo().` (~72 s), o mostrar el resumen del log del
     servicio con `demo fin de jornada:` (entregada 810, fallida 91, 31
     reasignaciones, retraso medio 983, invariantes ok).

4. **La calidad técnica (2 min).** En terminal:
   - `rebar3 eunit` — 11 casos, 0 fallos, en 9 escenarios del dominio;
   - `rebar3 ct` — 3 casos de integración contra la app completa
     (estáticos, `/api/*`, caos por HTTP y la regresión del crash del SSE);
   - `/metrics` en el dashboard (Prometheus) y `recon` para diagnóstico;
   - `systemctl status p29-flotilla` — release corriendo como servicio:
     arranca sin teclado tras reiniciar la VM (montaje repetible, pasos en
     el gist y unidad versionada en `deploy/p29-flotilla.service`).

5. **Argumentación técnica de respaldo** (por si caen preguntas):
   - **Determinismo**: pesos, colonias y ventanas salen de `erlang:phash2`,
     no de `rand`; la misma corrida es reproducible de principio a fin.
   - **Reasignar sin huérfanas**: pasar una entrega de unidad a otra pasa
     SIEMPRE por el statem (`devolver → pendiente → asignar`); el GPS
     atrasado se descarta (el más nuevo manda).
   - **Greedy first-fit en vez de VRP**: O(entregas × unidades) por pasada;
     buena y rápida antes que perfecta y lenta.
   - **Los ETS son caché de lectura**: el dueño de cada fila es el
     gen_server/gen_statem; los handlers HTTP jamás escriben ETS directo.
   - **La web es un observador**: el listener cowboy está en su propio
     ramal; si cae la web, la flota sigue simulando, y si cae el dominio,
     la web cae con él (rest_for_one).

## Problemas comunes DURANTE la demo (y salida rápida)

| Síntoma | Causa | Cómo resolver en vivo |
|---|---|---|
| `rebar3 shell` muere con `eaddrinuse` | el release del systemd ya ocupa el 8080 | `sudo systemctl stop p29-flotilla`; para la demo usa el release o la shell, ambos servidores no caben |
| el mapa no se actualiza | nadie suscrito de `/eventos` (o un proxy corta SSE) | recargar el dashboard; el handler manda latido `:` cada 15 s |
| curl responde JSON con error de cuerpo | las comillas dobles mueren en el tránsito PowerShell→ssh | escribir el JSON en el Pi con `printf '\173\042...'` (ver gist) |
| botón de avería no refleja | caché del navegador | Ctrl+F5 recarga los estáticos |

## Evidencias y respaldo

- Manual de uso del cliente (gist): <https://gist.github.com/l23211974-maker/f754a5fa477b148f2cdc2f36a10a76a8>
- Asciinema de validación: <https://asciinema.org/a/dUhp72CUtCpz5APp>
- Código: <https://github.com/l23211974-maker/erlang-proyectos/tree/main/proyectos/29-flotilla-de-reparto>
