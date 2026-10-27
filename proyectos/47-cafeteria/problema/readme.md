# #47 — Cafetería: el problema

## Contexto
En una cafeteria escolar el descanso dura ~30-45 minutos y cientos de alumnos llegan a la vez. Las filas largas hacen que muchos desistan de comer o lleguen tarde a clase. Un sistema de pedidos anticipados reparte la carga en el tiempo.

## Datos del mundo real
- Un mostrador sencillo atiende ~1-2 clientes por minuto; con 400 personas en una ventana de 40 min se necesitan ~10 clientes/min, mas de lo que un solo punto de entrega puede atender.
- **Ley de Little:** personas en el sistema = tasa de llegada × tiempo en el sistema; si llegan 10/min y el tiempo es 6 min, hay ~60 personas dentro; si el tiempo se duplica, tambien la fila.
- Platillos distintos tienen tiempos de preparacion distintos (un cafe, 1 min; una torta, 4-5 min; comida caliente, 6-10 min) y la cocina tiene estaciones limitadas.
- Para el cliente lo importante es el tiempo prometido; si dices 5 min y tardas 12, pierdes confianza.
- Los productos se agotan a mitad del dia ("86").
- Los pagos son en efectivo, tarjeta o saldo/monedero de la escuela.

## El problema
Recibir pedidos concurrentes, repartirlos entre las estaciones de cocina segun su carga, estimar un tiempo de entrega honesto basado en la cola real, avisar al cliente cuando esta listo, y mantener la disponibilidad de productos actualizada para no aceptar pedidos que no se pueden surtir.

## Escenario a simular
- 400 pedidos en 40 minutos, 3 estaciones, 30 productos.
- El platillo mas popular se agota a los 15 minutos.
- Cocina que se retrasa y vence los tiempos prometidos.

## Casos dificiles
- Pedido pagado de un producto que se agoto.
- Cliente que no recoge su pedido.
- Recalcular los tiempos prometidos en vivo.

## Preguntas guia
1. ¿Cual es la mejor estimacion del tiempo de un pedido que recien entra?
2. ¿Que haces con un pedido cuando se acaba un ingrediente?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
