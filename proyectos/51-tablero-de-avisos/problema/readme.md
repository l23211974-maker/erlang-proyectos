# #51 — Tablero de avisos: el problema

## Contexto
Los avisos de una escuela (suspension de clases, fechas de inscripcion, cambios de salon, becas) llegan por chats de WhatsApp, correos y carteles, y casi siempre se pierden o llegan a quien no los necesita. Un aviso importante tiene que llegar a los alumnos correctos en el momento correcto.

## Datos del mundo real
- Un campus como el TecNM Tijuana tiene varias carreras (por ejemplo sistemas, industrial, electronica, mecatronica, quimica, arquitectura, administracion) con decenas de grupos cada una; un alumno pertenece a una carrera, un semestre y uno o varios grupos.
- Un aviso general llega a miles; uno de un docente a un solo grupo (~35); uno de coordinacion, a una carrera completa.
- Un aviso urgente (suspension por clima o contingencia) necesita llegar en segundos a todos; uno informativo puede esperar o agruparse en un resumen.
- Entre mas notificaciones se envian, menos se leen; la gente silencia lo que le satura.
- Los alumnos no estan siempre conectados: al abrir la app deben ver lo que se perdieron.

## El problema
Publicar avisos dirigidos a una carrera, grupo, semestre o a todos; entregarlos en tiempo real a quienes estan conectados y dejarlos disponibles para quienes se conecten despues; distinguir prioridad; saber quien lo leyo; y permitir que los alumnos controlen que tipos de aviso reciben.

## Escenario a simular
- 3,000 alumnos, 12 carreras, 120 grupos, 40 avisos por dia.
- Aviso urgente enviado a 3,000 conectados al mismo tiempo.
- Un alumno que regresa tras una semana sin conectarse.

## Casos dificiles
- Un alumno de varios grupos recibe el mismo aviso dos veces.
- Aviso que se corrige o se retira despues de enviado.
- Programar un aviso para una fecha futura.

## Preguntas guia
1. ¿Como representas "a quien le corresponde este aviso"?
2. ¿Que garantizas sobre la entrega de un aviso urgente?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
