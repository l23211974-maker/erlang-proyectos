# #64 — Taquilla de eventos: el problema

## Contexto
Cuando salen a la venta boletos de un concierto grande, miles de personas piden lo mismo en el mismo segundo y la oferta es finita. En noviembre de 2022 la preventa del tour de Taylor Swift en Ticketmaster recibio del orden de 14 millones de solicitudes en un dia, con millones de fans en fila virtual y el sistema colapso. En Mexico, la venta de Bad Bunny en el Estadio Azteca ese mismo año termino en boletos falsos y duplicados.

## Datos del mundo real
- Un estadio como el de Tijuana tiene capacidad de ~25-30 mil personas; un foro, de 1-5 mil. Los mejores asientos se agotan en segundos.
- La demanda en el minuto 0 puede ser de 100-1000 veces la capacidad del sistema en operacion normal. El trafico viene de personas y tambien de bots.
- Se usa **fila virtual**: los usuarios esperan su turno y pasan por tandas controladas, para no tumbar la base de datos.
- Mientras un usuario elige y paga (3-10 min), sus asientos estan **retenidos**; si no paga, vuelven al inventario.
- Un asiento unico solo puede venderse una vez; un boleto digital debe poder validarse en la puerta y no puede funcionar duplicado (QR clonado).
- Los limites por persona (4-6 boletos) intentan frenar la reventa.

## El problema
Sostener un pico enorme y breve de solicitudes de compra, asegurar que cada asiento se venda a una sola persona, manejar retenciones y expiraciones, limitar bots y compras excesivas, emitir boletos validables y mantener informados a los usuarios en fila.

## Escenario a simular
- 20,000 asientos, 100,000 usuarios intentando comprar en el primer minuto.
- 30 % de las retenciones nunca se pagan.
- Un QR copiado y presentado en dos puertas distintas.

## Casos dificiles
- Dos personas piden el mismo asiento en el mismo milisegundo.
- Pago exitoso pero la confirmacion se pierde.
- Caida del sistema con retenciones activas.

## Preguntas guia
1. ¿Como proteges la parte que no se puede escalar mientras llegan 100 mil usuarios?
2. ¿Que garantiza que un boleto se use una sola vez?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
