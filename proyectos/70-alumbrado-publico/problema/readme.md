# #70 — Alumbrado público: el problema

## Contexto
Una ciudad como Tijuana tiene decenas de miles de luminarias. Las lamparas fallan, los postes se golpean, los cables se roban; la ciudadania reporta fallas y el municipio tarda dias en atender. Una calle oscura es una calle insegura. Muchas ciudades cambian sodio por LED, que consume entre 50 y 60 % menos energia.

## Datos del mundo real
- Una lampara de vapor de sodio consume 100-250 W; una LED equivalente, 40-100 W. Una luminaria LED dura 50,000 horas o mas (≈ 12 años a 12 h diarias).
- El encendido se hace por fotocelda o por horario astronomico (ocaso/amanecer, que cambia unos minutos cada dia segun la fecha y la latitud).
- El alumbrado publico es uno de los mayores gastos de electricidad de un municipio y su pago a la CFE depende de lo que se mide o estima.
- Las fallas se detectan por **reportes ciudadanos** (lentos, repetidos, imprecisos) o por **telemetria** (luminarias inteligentes que reportan corriente y estado).
- Una cuadrilla repara entre 8 y 15 luminarias al dia segun la distancia entre ellas y la altura; hay metas de atencion (por ejemplo 72 h) y prioridades (cruces peligrosos, escuelas, hospitales).
- Un mismo poste suele reportarse muchas veces, con direcciones escritas de maneras distintas.

## El problema
Consolidar reportes de ciudadanos y señales de telemetria en una lista de fallas unica por luminaria, priorizar segun criticidad y antigüedad, agrupar geograficamente para armar rutas de cuadrilla eficientes, llevar el estado de cada falla hasta su cierre, y mostrar un mapa de reparaciones.

## Escenario a simular
- 5,000 luminarias, 80 reportes nuevos al dia, 4 cuadrillas.
- Falla de un circuito completo (40 lamparas apagadas a la vez).
- 15 reportes ciudadanos distintos sobre el mismo poste.

## Casos dificiles
- Duplicados con direcciones escritas diferente.
- Reparar y que la lampara falle de nuevo en una semana (reincidencia).
- Falla de un circuito vs. 40 fallas independientes.

## Preguntas guia
1. ¿Cuando dos reportes son "la misma falla"?
2. ¿Como equilibras antigüedad de la falla con criticidad del lugar?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
