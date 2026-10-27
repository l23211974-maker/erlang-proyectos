# #45 — Control de laboratorios: el problema

## Contexto
Los laboratorios del TecNM Tijuana (computo, electronica, quimica, redes, talleres) y su equipo compartido son usados por cientos de estudiantes de decenas de grupos y carreras. Hoy las reservas suelen hacerse por mensaje, papel u hojas de calculo, con empalmes y equipo no devuelto.

## Datos del mundo real
- Un campus de este tamaño tiene del orden de miles de estudiantes y cientos de grupos por semestre, con horarios por bloque de 1 a 2 h.
- Un laboratorio tiene aforo fijo (por ejemplo, 20-30 estaciones) y equipo costoso con mantenimiento, calibracion y vida limitada (osciloscopios, fuentes, kits, equipos de computo, reactivos).
- Los periodos de mayor demanda son semanas de proyectos y examenes; en esos periodos, los bloques libres se agotan en horas.
- Reglas habituales: prioridad de clases sobre practicas libres, tiempo maximo por reserva, prestamo de equipo con responsable y devolucion, bloqueo por adeudo, mantenimiento programado.
- No presentarse deja un laboratorio vacio mientras otros grupos quedaron sin lugar.

## El problema
Reservar espacios y equipos con horarios, evitando traslapes y respetando reglas de prioridad y de aforo; llevar el prestamo y devolucion del equipo; liberar reservas no usadas; bloquear recursos en mantenimiento; y mostrar disponibilidad real en vivo a estudiantes y docentes.

## Escenario a simular
- 12 laboratorios, 150 equipos prestables, 1,000 reservas por semana.
- Semana de proyectos con 5 veces la demanda normal.
- Equipo prestado que no se devuelve y lab reservado al que nadie llega.

## Casos dificiles
- Una clase fija entra en conflicto con reservas ya hechas.
- Reserva recurrente que cruza dias de mantenimiento.
- Un equipo reservado para dos practicas con horarios que se tocan por un minuto.

## Preguntas guia
1. ¿Que pasa con reservas existentes cuando aparece una reserva de mayor prioridad?
2. ¿Como detectas y liberas una reserva fantasma?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
