# #26 — Central camionera / rutas urbanas: el problema

## Contexto
En Tijuana el transporte publico urbano y foraneo depende de cientos de unidades (camiones, calafias, taxis de ruta, autobuses a Mexicali, Ensenada y mas lejos) con poca informacion en tiempo real para el usuario. La Central Camionera mueve salidas y llegadas con andenes limitados. Para el pasajero la pregunta es siempre: "¿a que hora llega mi camion?".

## Datos del mundo real
- Distancias de referencia: Tijuana–Ensenada ≈ 100 km (≈ 1.5-2 h), Tijuana–Mexicali ≈ 180 km (≈ 2.5-3 h por La Rumorosa).
- Estandar de datos de transporte: GTFS (horarios estaticos) y GTFS-Realtime (posiciones y retrasos), usado por Google Maps y miles de ciudades.
- Un GPS de unidad reporta cada 5-30 s con error de 5-15 m; en zonas urbanas densas o tuneles se pierde señal.
- *Bunching*: en rutas urbanas varias unidades se juntan en grupo y dejan huecos largos despues; es un problema clasico de transito.
- La velocidad promedio urbana en hora pico puede bajar a 15-20 km/h.

## El problema
Seguir la posicion de cada unidad en su ruta, estimar su hora de llegada a cada parada considerando trafico y paradas, detectar desvios, unidades detenidas y bunching, y asignar andenes a salidas y llegadas de la central sin traslapes.

## Escenario a simular
- 30 unidades en 6 rutas, reporte GPS cada 10 s, 12 andenes.
- Una unidad detenida 15 min por averia; un accidente que bloquea una avenida.
- Dos autobuses foraneos que piden el mismo anden.

## Casos dificiles
- Posiciones GPS ruidosas o que saltan.
- ETA cuando faltan datos de la unidad.
- Unidad que cambia de ruta a mitad del viaje.

## Preguntas guia
1. ¿Como representas el "progreso" de una unidad sobre una ruta?
2. ¿Que tan vieja puede ser una posicion para seguir mostrandola?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
