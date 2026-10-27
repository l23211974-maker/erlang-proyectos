# #61 — Cotizador de divisas: el problema

## Contexto
En Tijuana el dolar circula casi como moneda local: se paga en pesos o dolares, se compra en casas de cambio por la calle y se cruza la frontera todos los dias. Una diferencia de 10 centavos en el tipo de cambio, multiplicada por miles de operaciones, es mucho dinero. Los precios cambian segundo a segundo en el mercado, pero lo que el usuario ve puede estar atrasado.

## Datos del mundo real
- El Banco de Mexico publica el **tipo de cambio FIX** cada dia habil (alrededor de las 12:00) y lo usa el DOF para solventar obligaciones en dolares; tambien ofrece una API (SIE) con token gratuito.
- El peso/dolar se ha movido en los ultimos años entre ~16 y ~21 pesos por dolar; en un dia normal varia 0.5-1 %, y en eventos (elecciones, decisiones de la Fed) 2 % o mas en horas.
- Las casas de cambio publican precio de **compra** y de **venta** separados; el diferencial (*spread*) tipico es de 0.10-0.40 pesos.
- Las APIs publicas de divisas limitan peticiones (decenas a miles al mes en planes gratuitos) y a veces tienen minutos u horas de retraso.
- Los mercados cierran fines de semana; el ultimo valor del viernes sigue vigente hasta el lunes.

## El problema
Obtener cotizaciones de una o varias fuentes con limites de uso, guardar el historico (minuto, hora, dia), calcular maximos, minimos y variaciones, permitir que muchos usuarios consulten sin golpear la fuente, y disparar alertas personalizadas ("avisame cuando baje de 17.50") sin enviar avisos duplicados ni perdidos.

## Escenario a simular
- 2 fuentes, consulta cada 30 s, 5,000 alertas de usuarios, 300 consultas/s en pico.
- Salto de 2 % en 10 minutos que dispara miles de alertas a la vez.
- Una fuente que se cae o devuelve un valor absurdo (un cero o un 1700).

## Casos dificiles
- Dos fuentes que discrepan.
- Alerta que cruza el umbral y vuelve varias veces (rebote).
- Dato atrasado presentado como actual.

## Preguntas guia
1. ¿Que significa "cotizacion actual" cuando la fuente esta caida?
2. ¿Como evitas que una alerta se dispare cien veces por un valor que oscila?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
