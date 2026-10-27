# #76 — Mesa de dominó o lotería en línea: el problema

## Contexto
El domino y la loteria mexicana son juegos de mesa cotidianos en Mexico. Pasarlos a linea implica que un grupo de personas, con redes distintas, comparta una mesa virtual con reglas estrictas, turnos, informacion oculta y quien llega y se va a media partida.

## Datos del mundo real
- **Domino doble seis:** 28 fichas, 4 jugadores con 7 cada uno, juego por turnos; se gana quedandose sin fichas o por puntos si se tranca. Cada jugador ve solo sus propias fichas.
- **Loteria mexicana:** 54 cartas y tablas de 4×4 (16 figuras); el "gritón" canta las cartas una a una; gana quien completa primero (fila, columna, esquinas, tabla llena segun la variante). Reclamos simultaneos son posibles.
- Una mesa puede tener 2-10 jugadores (loteria hasta decenas); un servidor aloja cientos de mesas.
- En juegos con tiempo por turno (por ejemplo 20-30 s), el jugador desconectado no puede detener la partida: el sistema juega por el o lo sustituye con un bot.
- Hay que impedir trampas: el servidor decide el reparto y nunca envia las fichas de los demas.
- Un jugador puede reconectar desde otro dispositivo y debe recuperar su mano exacta.

## El problema
Alojar mesas independientes con una maquina de estados por partida (esperando jugadores, repartiendo, en turno, terminada), validar cada jugada contra las reglas, ocultar la informacion privada, resolver reclamos simultaneos de victoria, tolerar desconexiones y reconexiones, y limpiar mesas abandonadas.

## Escenario a simular
- 200 mesas (150 de domino, 50 de loteria), 700 jugadores.
- Jugador que se desconecta en su turno y regresa 40 s despues.
- Dos jugadores de loteria que gritan "¡loteria!" con 50 ms de diferencia.

## Casos dificiles
- Jugada ilegal enviada por un cliente modificado.
- Mesa a la que todos abandonan.
- Reconexion en otro dispositivo mientras el anterior sigue abierto.

## Preguntas guia
1. ¿Que informacion jamas debe salir del servidor?
2. ¿Quien arbitra dos reclamos casi simultaneos y con que criterio?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
