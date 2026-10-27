# #66 — Mercado de abastos / tianguis: el problema

## Contexto
Los mercados y tianguis son el corazon del abasto de alimentos frescos: cientos de locatarios, miles de compradores, productos que se echan a perder y precios que cambian cada dia. La Central de Abasto de la CDMX, de las mas grandes del mundo, recibe cientos de miles de visitantes diarios; en Tijuana, mercados como Hidalgo y los tianguis semanales cumplen un papel parecido a menor escala.

## Datos del mundo real
- Los precios de frutas y verduras varian por dia segun oferta (cosecha, clima, bloqueos) y se cotizan por kilo, caja o manojo; un locatario puede ajustarlos varias veces en la mañana.
- Producto perecedero: algunas hojas verdes duran 2-3 dias, la fresa 3-5; lo que no se vende se pierde. Los locatarios rebajan precio hacia la tarde para vaciar existencias.
- Muchos comerciantes ya no se limitan a vender en puesto: reciben pedidos por mensajeria y los mandan con **repartidores** (moto o bicicleta), o los clientes recogen.
- Un repartidor recoge pedidos con varios locatarios para un mismo cliente; la coordinacion y la espera en el mercado son el cuello de botella.
- Las transacciones son chicas (decenas de pesos), numerosas y con pago mixto efectivo/transferencia.
- La conectividad dentro de un mercado techado es mala y los comerciantes no son usuarios tecnicos.

## El problema
Conectar a locatarios con compradores y repartidores: publicar disponibilidad y precio, tomar pedidos que involucran a varios locatarios, asignar un repartidor, coordinar la recogida y la entrega, y manejar productos que se agotan o cambian de precio mientras el cliente arma su pedido.

## Escenario a simular
- 100 locatarios, 20 repartidores, 300 pedidos entre 7 y 11 a. m.
- Un locatario se queda sin tomate con 12 pedidos que lo incluyen.
- Un repartidor que se retrasa con un pedido de 4 locatarios.

## Casos dificiles
- Pedido parcial: ¿se entrega incompleto o se cancela?
- Cambio de precio entre que el cliente ve y que paga.
- Asignar repartidores con rutas solapadas.

## Preguntas guia
1. ¿Quien responde si un producto del pedido ya no esta?
2. ¿Como evitas que un repartidor espere 30 minutos en un puesto?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
