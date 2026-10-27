# #63 — Reservas de hotel: el problema

## Contexto
Tijuana, Rosarito y Ensenada reciben turismo medico, de negocios y de fin de semana. Un hotel vende noches, no habitaciones: cada reserva ocupa un tipo de cuarto durante un rango de fechas. Un error de disponibilidad significa un huesped en el lobby sin cuarto.

## Datos del mundo real
- Un hotel mediano tiene 80-200 habitaciones en 3-5 tipos (sencilla, doble, suite). Se reserva por **tipo** y la habitacion fisica se asigna despues, normalmente al check-in (15:00; check-out 12:00).
- Las ocupaciones tipicas son 55-75 % anual, con picos de 95-100 % en fines de semana largos y eventos.
- **Sobreventa (overbooking):** los hoteles venden 3-10 % por encima de capacidad porque algunos huespedes cancelan o no llegan; debe haber una politica de reubicacion cuando todos llegan.
- Una busqueda de "del 10 al 14" debe revisar que cada una de las 4 noches tenga disponibilidad; basta una noche llena para no poder vender.
- Los clientes dejan reservas "en proceso" mientras pagan (retencion de 10-15 min). Las agencias en linea consultan disponibilidad cientos de veces por cada reserva real.
- Cancelaciones con politicas por fecha: gratuita hasta 48 h antes, penalizacion despues.

## El problema
Llevar el inventario noche a noche por tipo de habitacion, responder consultas de disponibilidad de rangos de fechas de forma rapida, permitir reservas, modificaciones y cancelaciones concurrentes sin sobreventa accidental, retener reservas en proceso, y asignar habitaciones fisicas al llegar.

## Escenario a simular
- 120 habitaciones, 4 tipos, 90 dias de calendario, 2,000 consultas por reserva.
- Fin de semana con una convencion: 90 % de las noches ya vendidas.
- Dos reservas que compiten por el ultimo cuarto de una noche del rango.

## Casos dificiles
- Reserva de 5 noches donde falla la tercera noche.
- Cambiar fechas manteniendo el precio original.
- Cuarto dañado: reasignar sin afectar al huesped.

## Preguntas guia
1. ¿Que se bloquea al reservar un rango de fechas y por cuanto tiempo?
2. ¿Como decides cuando la sobreventa es intencional y cuando es un error?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
