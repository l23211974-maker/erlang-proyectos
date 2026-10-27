# #43 — Citas médicas: el problema

## Contexto
Una clinica o consultorio tiene medicos con agendas limitadas y pacientes que quieren horarios. Las citas perdidas y los traslapes son costo directo: un medico sin paciente es capacidad desperdiciada y un paciente esperando es insatisfaccion.

## Datos del mundo real
- Las tasas de inasistencia (*no-show*) en consulta externa se reportan entre 15 % y 30 % en muchos sistemas; los recordatorios por mensaje la reducen de manera apreciable.
- Una consulta general dura ~15-30 min; una primera vez o procedimiento, 45-60 min; hay ademas tiempos de preparacion y limpieza.
- La sobre-agenda controlada (*overbooking*) compensa los no-shows, pero si todos llegan se forman esperas largas.
- Un medico puede atender en varios consultorios o clinicas, con bloques de guardia, vacaciones y cirugias que bloquean su agenda.
- Los recordatorios tipicos: 48 h y 2 h antes, con opcion de confirmar o cancelar; una cancelacion libera un hueco que podria ofrecerse a lista de espera.

## El problema
Administrar agendas de medicos y recursos (consultorios, equipos) sin traslapes, aceptar solicitudes de cita concurrentes de muchos pacientes, enviar recordatorios en el momento correcto, procesar confirmaciones y cancelaciones, y reutilizar los huecos que se liberan.

## Escenario a simular
- 10 medicos, 4 consultorios, 200 citas al dia, 20 % de no-show.
- Dos pacientes eligen el mismo horario en el mismo segundo.
- Un medico que se enferma y deja 15 citas sin atender.

## Casos dificiles
- Reagendar masivamente respetando preferencias.
- Recordatorios que deben dispararse aunque el sistema se reinicie.
- Zonas horarias y cambio de horario de verano.

## Preguntas guia
1. ¿Como representas el tiempo ocupado para que un traslape sea imposible?
2. ¿Cuando sale un recordatorio y que pasa si no se pudo entregar?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
