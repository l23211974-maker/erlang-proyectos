# #9 — Semáforos o cruceros: el problema

## Contexto
Una ciudad como Tijuana tiene cientos de cruceros semaforizados y vialidades saturadas (Blvd. Agua Caliente, Via Rapida, Blvd. Insurgentes). Un semaforo con tiempos fijos desperdicia verde cuando no hay autos y ocasiona filas cuando hay muchos. Pero un semaforo mal coordinado o con una secuencia insegura causa accidentes.

## Datos del mundo real
- **Ciclo tipico:** 60-120 s. Amarillo ~3-4 s; despeje "todo rojo" ~1-2 s entre fases conflictivas.
- **Flujo de saturacion:** ~1,800-1,900 veh/hora/carril durante el verde.
- **Peatones:** el tiempo de cruce se calcula con ~1.0-1.2 m/s; cruzar 20 m requiere ≥ 17-20 s de despeje peatonal.
- **Deteccion:** lazos inductivos, camaras, radar; los botones peatonales se presionan de forma aleatoria.
- **Ola verde:** semaforos consecutivos coordinados con un desfase igual al tiempo de viaje entre ellos (por ejemplo 400 m a 40 km/h ≈ 36 s).
- **Seguridad:** un *conflict monitor* de hardware obliga a falla segura (destellos rojos) si detecta verdes en direcciones conflictivas. El software jamas debe confiarse solo de si mismo.

## El problema
Controlar las fases de un crucero (y varios coordinados) con tiempos que se adapten a la demanda, sin violar nunca las reglas de seguridad (dos verdes conflictivos, minimos de amarillo y despeje), atendiendo peatones, vehiculos de emergencia y fallas de detectores.

## Escenario a simular
- Un crucero de 4 aproximaciones y 3 cruceros consecutivos en ola verde.
- Hora pico: 1,200 veh/hora por aproximacion; fin de semana de madrugada con casi cero demanda.
- Ambulancia que solicita preferencia; detector que queda "siempre ocupado".

## Casos dificiles
- Un cambio de plan de tiempos en pleno ciclo.
- Perdida de comunicacion entre cruceros coordinados: ¿que se mantiene?
- Reinicio del controlador: ¿en que fase arranca?

## Preguntas guia
1. ¿Que estados son *imposibles* y como haces que el sistema no pueda llegar a ellos?
2. ¿Que pasa si cae el proceso que maneja el crucero?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
