# #30 — Bicicletas o scooters compartidos: el problema

## Contexto
Sistemas como Citi Bike (Nueva York, mas de mil estaciones y decenas de miles de bicicletas) o EcoBici (CDMX) y flotas de scooters sin base (*dockless*) viven del equilibrio: si no hay bicicletas en una estacion, el usuario se va; si esta llena, no puede devolver la suya. Y el equilibrio se rompe solo, porque la gente viaja en una direccion (a la universidad en la mañana, a casa en la tarde).

## Datos del mundo real
- Las estaciones con anclajes (*docks*) reportan bicicletas disponibles y anclajes libres; el estandar abierto GBFS publica este estado como feed.
- Los flujos son asimetricos y predecibles: zonas de oficinas y escuelas se vacian por la tarde y se llenan por la mañana.
- Un camion de rebalanceo transporta 20-40 bicicletas y su ruta consume tiempo y dinero; las flotas gastan una parte importante de sus costos en esto.
- Un scooter electrico tiene bateria limitada (unas 3-6 h de uso); hay que recogerlo y cargarlo, y se roba o se abandona fuera de la zona permitida.
- Un viaje tiene precio por desbloqueo y por minuto; hay que evitar viajes "fantasma" o cobros dobles si se pierde conexion.

## El problema
Mantener el estado de estaciones y vehiculos, procesar el desbloqueo y cierre de viajes de forma segura, detectar estaciones por vaciarse o llenarse antes de que ocurra, y sugerir movimientos de rebalanceo a los camiones.

## Escenario a simular
- 40 estaciones, 400 bicicletas, 1,000 viajes al dia con marea de mañana y tarde.
- Un usuario que desbloquea dos veces por un reintento de red.
- Una estacion sin comunicacion durante una hora.

## Casos dificiles
- Dos usuarios toman la ultima bicicleta a la vez.
- Viaje abierto por perdida de señal al cerrar.
- Rebalanceo que llega demasiado tarde.

## Preguntas guia
1. ¿Que informacion necesitas para predecir que una estacion se quedara vacia en 30 minutos?
2. ¿Cual es la fuente de verdad de si una bicicleta esta en uso?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
