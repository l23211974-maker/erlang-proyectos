# #50 — Examen en línea: el problema

## Contexto
Un examen en linea tiene reglas estrictas: tiempo limitado, preguntas que no se pueden perder, resultados que no se pueden alterar. Pero la conectividad de los alumnos es irregular: se cae el WiFi, se apaga el telefono, se cierra el navegador. Un examen mal manejado se convierte en inconformidades y revisiones.

## Datos del mundo real
- Una sesion de examen tipica: 30-90 min, 20-60 preguntas, grupos de 30-300 alumnos que inician casi al mismo tiempo.
- Las caidas de conexion de corta duracion (segundos a minutos) son comunes; un alumno debe poder reconectarse **sin que el tiempo se detenga ni se reinicie**, y sin perder respuestas.
- El reloj del navegador no es confiable; el tiempo restante debe ser decidido por el servidor.
- Para limitar copias se usan orden aleatorio de preguntas y respuestas, bancos de preguntas con variantes, y un registro de eventos (cambio de pestaña, reconexiones).
- Las respuestas se guardan de forma continua (autoguardado) para que una falla no pierda todo.
- Las inconformidades se resuelven con evidencia: hora de inicio, ultimo guardado, reconexiones.

## El problema
Administrar un temporizador independiente por alumno cuya autoridad es el servidor, guardar respuestas de forma incremental, soportar desconexiones y reconexiones sin perder tiempo ni datos, cerrar el examen exactamente cuando vence, y registrar una bitacora que sirva de evidencia.

## Escenario a simular
- 200 alumnos, examen de 60 min, 10 % se desconectan al menos una vez.
- Un alumno que se desconecta 4 min justo antes del final.
- Servidor que se reinicia a mitad del examen.

## Casos dificiles
- Respuesta enviada en el ultimo segundo: ¿cuenta?
- Mismo alumno abre dos sesiones.
- Extender tiempo a un alumno con una justificacion.

## Preguntas guia
1. ¿Que pasa con los temporizadores si el servidor se reinicia?
2. ¿Que evidencia puede dar el sistema de lo que paso?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
