# #27 — Taxis o rides: el problema

## Contexto
Servicios como Uber, DiDi o taxis de aplicacion emparejan en segundos a un pasajero con un conductor cercano. Tijuana, ciudad fronteriza con alta demanda de transporte, tiene miles de taxis y conductores de plataforma. Elegir mal el emparejamiento significa esperas largas y conductores vacios.

## Datos del mundo real
- Los conductores reportan su posicion cada ~4-5 s. Con miles de conductores esto son cientos o miles de actualizaciones por segundo.
- Para buscar "conductores cercanos" no se compara contra todos: se usan indices espaciales como geohash o H3 (hexagonos; los de resolucion 8 miden ≈ 0.74 km² de area).
- Los pasajeros esperan que se les asigne conductor en menos de ~10-30 s; un conductor tiene ~10-15 s para aceptar antes de pasar al siguiente.
- Tarifas dinamicas: cuando la demanda supera a la oferta en una zona, el precio sube para atraer conductores.
- Tasas de cancelacion de 5-15 % son comunes; el ETA mostrado no debe pasar de lo razonable.

## El problema
Mantener la posicion y estado (libre, asignado, en viaje) de miles de conductores, recibir solicitudes de viaje, emparejar cada una con un conductor adecuado evitando asignar el mismo conductor a dos pasajeros, y manejar rechazos, cancelaciones y desconexiones durante el proceso.

## Escenario a simular
- 2,000 conductores con GPS cada 5 s, 100 solicitudes por minuto concentradas en una zona.
- Conductores que rechazan o no responden; pasajero que cancela tras la asignacion.
- Evento masivo (concierto) que concentra demanda.

## Casos dificiles
- Dos solicitudes que competen por el mismo conductor cercano.
- Buscar candidatos sin recorrer toda la flota.
- Conductor que pierde conexion en pleno viaje.

## Preguntas guia
1. ¿Optimizas por el conductor mas cercano o por el menor tiempo total de espera de todos?
2. ¿Quien es el dueño del estado de un conductor?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
