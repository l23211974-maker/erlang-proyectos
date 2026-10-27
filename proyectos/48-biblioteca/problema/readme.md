# #48 — Biblioteca: el problema

## Contexto
Una biblioteca universitaria presta miles de libros a miles de alumnos, con pocos ejemplares de los textos mas pedidos. Los prestamos vencidos, las multas, las reservas y los libros perdidos son el dia a dia del bibliotecario.

## Datos del mundo real
- Reglas tipicas: prestamo de 3 a 15 dias segun el tipo de material (reserva de sala 2-3 dias, general 7-15 dias), hasta 3-5 libros a la vez por alumno, renovacion permitida si nadie lo ha apartado.
- Las multas son por dia de retraso (por ejemplo, $5-$10 MXN/dia); algunas bibliotecas bloquean el servicio al acumular adeudo.
- Los libros se identifican por ISBN (titulo) y numero de adjudicacion o codigo de barras (cada ejemplar fisico). Una obra puede tener 1 a 20 ejemplares.
- En examenes finales, un puñado de titulos concentra una demanda enorme y las listas de espera pasan de 10 personas por ejemplar.
- Un libro se devuelve tarde, dañado o no se devuelve (perdida): cada caso requiere un proceso.

## El problema
Administrar catalogo, ejemplares, prestamos, renovaciones, reservas con cola de espera, multas y bloqueos de usuarios, asegurando que un ejemplar solo este prestado a una persona, que las reservas respeten el orden de solicitud, y que se notifique al siguiente cuando un libro regrese.

## Escenario a simular
- 10,000 ejemplares, 3,000 usuarios, 300 prestamos al dia.
- Un titulo con 1 ejemplar y 25 reservas.
- Un alumno con multa pendiente intenta pedir un libro.

## Casos dificiles
- Dos bibliotecarios prestan el mismo ejemplar a la vez.
- Reserva atendida que nadie recoge en 48 horas.
- Calcular multas con dias inhabiles.

## Preguntas guia
1. ¿Quien es el dueño del estado de un ejemplar?
2. ¿Que pasa con la cola de reservas cuando se pierde el libro?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
