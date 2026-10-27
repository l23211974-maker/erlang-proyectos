# #60 — Restaurante: el problema

## Contexto
Un restaurante coordina mesero, cocina, barra y caja con mucha comunicacion urgente: una comanda perdida o un plato que se enfria arruina la experiencia. En Tijuana, con su fuerte oferta gastronomica y clientela local y turistica, las horas pico saturan cocinas de pocas estaciones.

## Datos del mundo real
- Una mesa se ocupa en promedio de 45 a 90 min; el numero de rotaciones por servicio define los ingresos. Una cocina pequeña maneja 15-30 comandas simultaneas en pico.
- La cocina se divide en estaciones (parrilla, freidora, fria, postres, barra); un platillo puede requerir mas de una y debe salir sincronizado para la misma mesa.
- Los tiempos de preparacion varian: bebida (2 min), entrada fria (5), plato fuerte (12-20). Los *tickets* con mas de 20-25 min se consideran fuera de objetivo.
- Los sistemas de pantalla de cocina (KDS) reemplazan los tickets de papel y muestran prioridad, tiempo transcurrido y alertas por colores.
- Los productos se agotan ("86") y deben desaparecer del menu al instante. Hay modificadores ("sin cebolla") y alergias.
- Cuentas divididas, propinas (10-15 %), cortesias y cancelaciones son parte del dia normal.

## El problema
Tomar comandas de multiples meseros, enrutar cada partida a la estacion correcta, sincronizar la salida de platillos de una misma mesa, medir tiempos, avisar de retrasos y manejar cambios y cancelaciones a mitad de preparacion, hasta llegar a la cuenta de cada mesa.

## Escenario a simular
- 20 mesas, 5 estaciones, 6 meseros, servicio de 3 horas con pico a la mitad.
- Un platillo que se agota con 6 comandas pendientes.
- Mesa que cambia su pedido cuando ya se esta cocinando.

## Casos dificiles
- Comanda duplicada por doble toque del mesero.
- Dividir una cuenta con articulos compartidos.
- Cocina saturada: ¿que se prioriza?

## Preguntas guia
1. ¿Que es el estado de una mesa y quien tiene derecho a cambiarlo?
2. ¿Como coordinas varias estaciones para que los platos salgan juntos?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
