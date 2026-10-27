# #73 — Quiniela del Mundial: el problema

## Contexto
El Mundial 2026 (Mexico, EE. UU. y Canada; 11 de junio al 19 de julio) fue el primero con 48 selecciones y 104 partidos. Las quinielas entre amigos, escuelas y oficinas movilizan a millones de personas en Mexico. El sistema debe poder reproducir ese torneo o uno anterior (por ejemplo Qatar 2022: 32 selecciones, 64 partidos) usando datos historicos.

## Datos del mundo real
- Cada participante pronostica el resultado de cada partido (marcador o ganador) **antes de que inicie**; despues no se permite cambiarlo. Reglas comunes: 3 puntos por marcador exacto, 1 por acertar ganador/empate, bonos por fases (campeon, goleador).
- Los picos son extremos: miles de pronosticos entran en los ultimos minutos antes del silbatazo y miles de consultas del ranking llegan en cada gol.
- Un partido tiene eventos en vivo (goles, tarjetas, entretiempo, tiempo extra, penales) que modifican el resultado; hay correcciones por VAR (un gol anulado minutos despues).
- Los datos de resultados vienen de APIs externas (con limites de uso y retrasos) y pueden ser inconsistentes.
- Varias quinielas privadas con reglas propias coexisten.
- Los empates en el ranking deben resolverse con criterios claros.

## El problema
Recibir pronosticos y bloquearlos exactamente al inicio de cada partido, ingerir resultados en vivo (y sus correcciones), recalcular puntos y rankings de muchas quinielas con reglas distintas, y distribuir el ranking actualizado a miles de usuarios conectados sin saturar el sistema.

## Escenario a simular
- 5,000 participantes, 50 quinielas, 4 partidos en simultaneo, 64 partidos totales.
- 2,000 pronosticos en los 60 segundos antes del inicio de un partido.
- Gol anulado por VAR despues de haberse contado.

## Casos dificiles
- Pronostico que llega justo en el limite de bloqueo.
- Reglas de puntos que cambian entre quinielas.
- Recalcular un ranking completo tras una correccion.

## Preguntas guia
1. ¿Quien decide la hora oficial de bloqueo y con que reloj?
2. ¿Que recalculas completo y que de forma incremental?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
