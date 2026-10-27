# #39 — Sala de urgencias: el problema

## Contexto
Una sala de urgencias recibe personas sin cita y con gravedades muy distintas. El *triage* es la clasificacion rapida para decidir quien se atiende primero. Un error ahi tiene consecuencias graves. Este proyecto es una simulacion educativa de gestion de colas, no un dispositivo medico.

## Datos del mundo real
- Escalas internacionales: **ESI** (Emergency Severity Index, 5 niveles, 1 = reanimacion inmediata, 5 = no urgente) y **Manchester** (colores: rojo inmediato, naranja ≤10 min, amarillo ≤60 min, verde ≤120 min, azul ≤240 min). En Mexico es comun usar rojo, amarillo y verde.
- Medir el "puerta-a-medico" (*door-to-doctor*) y la espera por nivel; en muchos hospitales publicos la espera de casos no urgentes supera varias horas.
- La saturacion de urgencias se agrava por camas hospitalarias ocupadas: pacientes ya atendidos esperan cama y bloquean espacio.
- Un paciente en espera puede **empeorar**: el triage se repite periodicamente y puede subir su prioridad.
- Los recursos son finitos: medicos, enfermeras, camillas, quirofano, laboratorio y rayos X.

## El problema
Mantener una cola priorizada donde la gravedad manda pero nadie espera indefinidamente, reclasificar pacientes cuando cambian sus signos, asignar medicos y espacios disponibles, y medir tiempos de espera y atencion por nivel para detectar saturacion.

## Escenario a simular
- 100 llegadas en 12 horas, 5 medicos, 12 camillas, mezcla de 5 niveles.
- Accidente con 8 heridos que llegan al mismo tiempo.
- Un paciente verde que empeora a rojo tras 90 minutos.

## Casos dificiles
- Inanicion: un paciente de baja prioridad que nunca pasa.
- Prioridad por gravedad vs. por tiempo de espera.
- Desbordamiento: no hay camillas libres.

## Preguntas guia
1. ¿Como evitas que un nivel bajo espere para siempre sin comprometer a los graves?
2. ¿Que metrica te avisa primero de que la sala se saturo?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
