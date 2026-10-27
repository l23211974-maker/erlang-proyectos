# #49 — Estacionamiento del campus: el problema

## Contexto
Es la variante del problema #6 aplicada a un campus con varios edificios y estacionamientos, donde la demanda sigue el horario de clases: miles de autos llegan en pocos minutos antes de las 7:00, 13:00 y 16:00, y muchas veces el cajon libre esta lejos del edificio al que se va.

## Datos del mundo real
- La ocupacion de un estacionamiento escolar es muy predecible: casi vacio de noche, pico entre 8:00 y 14:00, y hasta 100 % en semanas de examen.
- Un auto pasa de 4 a 8 horas estacionado; la rotacion es baja, asi que un cajon mal asignado por 5 horas afecta a muchos.
- Los campus suelen tener zonas diferenciadas: alumnos, docentes, personal, visitantes, motos, personas con discapacidad (en Mexico, normas exigen un porcentaje de cajones accesibles).
- Los estudiantes eligen estacionarse segun cercania a su edificio; si no hay lugar cerca, dan vueltas.
- Entrada por pocos accesos con lector o talon causa colas en horas pico.

## El problema
Conocer la ocupacion por estacionamiento y zona en tiempo real, recomendar a cada usuario donde estacionarse segun el edificio al que va, respetar reglas por tipo de usuario, evitar mandar a dos usuarios al ultimo cajon, y gestionar permisos y accesos.

## Escenario a simular
- 6 edificios, 4 estacionamientos, 1,500 cajones, 1,200 autos entre 6:45 y 7:15.
- Un estacionamiento cerrado por obra.
- Vehiculo sin permiso en cajon de discapacidad.

## Casos dificiles
- Recomendar a mil usuarios simultaneamente sin que todos vayan al mismo lugar.
- Un cajon ocupado que el sensor reporta libre.
- Cambios de horario en dias de eventos.

## Preguntas guia
1. ¿Como evitas que tu recomendacion cree el atasco que quiere evitar?
2. ¿Que garantiza la exactitud del conteo cuando fallan sensores?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
