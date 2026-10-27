# #72 — Torneo de esports: el problema

## Contexto
Torneos de videojuegos, desde ligas escolares hasta eventos regionales, reunen decenas o cientos de equipos con partidas simultaneas. Los organizadores batallan para saber en que ronda va cada quien, quien juega contra quien y cuales son los marcadores, y los espectadores quieren verlo en vivo.

## Datos del mundo real
- **Eliminacion simple:** con N equipos se juegan N−1 partidas; un cuadro de 16 tiene 4 rondas y 15 partidas; si N no es potencia de 2, algunos pasan directo (*byes*).
- **Doble eliminacion:** hay cuadro de ganadores y de perdedores; un equipo queda fuera tras dos derrotas; se juegan alrededor de 2N−2 partidas y una final que puede necesitar reinicio del cuadro.
- **Suizo y grupos:** formatos usados cuando se quiere que todos jueguen varias rondas.
- Una serie puede ser al mejor de 1, 3 o 5 mapas; el marcador de la serie se actualiza mapa a mapa.
- Las partidas se retrasan, los equipos no se presentan (*no-show*), se pelean los resultados y se reportan mal: es parte del dia.
- Los espectadores esperan ver cambios en menos de 1-2 segundos.

## El problema
Generar el cuadro del torneo, avanzar automaticamente a los ganadores a su siguiente partida, aceptar reportes de resultados desde varios clientes, resolver disputas, manejar descalificaciones y no-shows, y mostrar a cientos de espectadores el estado actualizado en vivo.

## Escenario a simular
- 64 equipos en doble eliminacion, 8 mesas de juego, 300 espectadores conectados.
- Ambos equipos de una partida reportan que ganaron.
- Un equipo es descalificado a media ronda y su rival avanza.

## Casos dificiles
- Corregir un resultado ya propagado a rondas posteriores.
- Cuadro con un numero de equipos que no es potencia de 2.
- Dos partidas que comparten una mesa o un arbitro.

## Preguntas guia
1. ¿Que estructura representa el cuadro y que pasa al corregir un resultado antiguo?
2. ¿Quien decide un resultado en disputa?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
