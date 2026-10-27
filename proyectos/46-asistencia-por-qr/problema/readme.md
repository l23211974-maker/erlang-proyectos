# #46 — Asistencia por QR: el problema

## Contexto
Pasar lista a mano en un grupo de 30-40 alumnos consume 5-10 minutos de cada clase, y las asistencias falsas ("pase de lista por un amigo") son comunes. En muchas instituciones, incluidos los tecnologicos, se exige un minimo de asistencia (a menudo 80 %) para tener derecho a evaluacion, asi que el registro importa.

## Datos del mundo real
- Una escuela de miles de alumnos tiene cientos de grupos por semestre; en cada cambio de hora, decenas de grupos inician a la vez, produciendo rafagas de registros de cientos de alumnos en pocos minutos.
- Un QR estatico se puede fotografiar y compartir por mensaje; los QR dinamicos se renuevan cada 10-30 s (como los codigos TOTP) para que solo sirva quien esta presente.
- Se puede ademas validar ubicacion o red WiFi del salon, aunque la geolocalizacion de interiores es imprecisa (decenas de metros).
- Las reglas de asistencia: tolerancia de entrada (ej. 10 min), retardo, falta, justificantes y sesiones que cruzan cambio de aula.
- Los telefonos de los alumnos tienen mala señal dentro de edificios; algunos registros llegan tarde o dos veces.

## El problema
Generar identificadores de sesion que expiren rapido, registrar en tiempo real quien esta presente en cada sesion, rechazar escaneos fuera de tiempo o repetidos, resistir intentos de fraude y mostrar al docente la lista que se llena en vivo.

## Escenario a simular
- 60 grupos de 35 alumnos que comienzan clase a la misma hora.
- Un alumno que comparte la foto del QR con un amigo ausente.
- Un docente que cierra la sesion con alumnos aun sin registrar por mala señal.

## Casos dificiles
- Reintento de escaneo por mala red: no debe duplicar.
- Reloj del telefono desajustado.
- Correccion manual de asistencia por el docente con bitacora.

## Preguntas guia
1. ¿Cual es el costo de un falso rechazo vs. el de un falso registro?
2. ¿Que datos necesita validar el servidor y cuales no puede confiar al telefono?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
