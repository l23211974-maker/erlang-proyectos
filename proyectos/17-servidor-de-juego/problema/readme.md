# #17 — Servidor de juego: el problema

## Contexto
Los juegos multijugador son sistemas de tiempo real exigentes: cada jugador debe sentir que su accion es inmediata y que el mundo es el mismo para todos. Los servidores *autoritativos* deciden que paso realmente para evitar trampas.

## Datos del mundo real
- **Tick rate:** juegos competitivos corren la simulacion de 20 a 128 veces por segundo (por ejemplo ~30 Hz en battle royale, 64-128 Hz en shooters tacticos). A 60 Hz el servidor tiene ~16.7 ms por tick.
- **Latencia:** menos de 50 ms se siente excelente, 100 ms es jugable, arriba de 150-200 ms es frustrante. El *jitter* (variacion) molesta tanto como la latencia.
- Se usa UDP o WebSocket; se envian *snapshots* del estado a cada cliente, recortados al area visible de cada uno.
- Se pierden, duplican y reordenan paquetes: el cliente predice su movimiento y el servidor lo corrige.
- Una sala tiene de 2 a 100 jugadores; un servidor corre muchas salas en paralelo.
- Las trampas son comunes: hay que validar velocidad, cadencia de disparo, posicion.

## El problema
Alojar muchas partidas simultaneas, cada una con su ciclo de simulacion de ritmo fijo, procesar entradas de jugadores que llegan con retraso y desordenadas, enviar el estado a cada jugador con el ancho de banda justo, y tolerar jugadores que se desconectan o reconectan sin que se caiga la partida.

## Escenario a simular
- 100 salas de 8 jugadores a 30 ticks/s (≈ 24,000 entradas/s).
- Un jugador con 400 ms de lag y 10 % de perdida.
- Una sala que cae por un error sin afectar a las demas.

## Casos dificiles
- Un tick que tarda mas que su presupuesto.
- Resolver quien disparo primero con latencias distintas.
- Matchmaking: formar salas balanceadas sin esperar eternamente.

## Preguntas guia
1. ¿Que pasa si el procesamiento de una sala se atrasa?
2. ¿Que informacion no le puedes dar al cliente por seguridad?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
