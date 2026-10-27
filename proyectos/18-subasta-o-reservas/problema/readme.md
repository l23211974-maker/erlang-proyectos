# #18 — Subasta o reservas: el problema

## Contexto
Hay un recurso escaso (un articulo, un asiento, una mesa, una cabaña) y muchas personas lo quieren a la vez. Aerolineas y hoteles incluso sobrevenden a proposito sabiendo que un porcentaje no se presentara. Los sistemas de subasta en linea sufren los ultimos segundos antes del cierre.

## Datos del mundo real
- En subastas con cierre fijo domina el *sniping*: gran parte de las pujas llegan en los ultimos segundos. Muchas plataformas extienden el cierre unos minutos (2-5 min) si hay una puja tardia (*soft close*).
- En reservaciones, los usuarios abren la pagina, la dejan y no confirman: se usa un *hold* temporal (tipicamente 5-15 minutos) que libera el recurso si no se paga.
- Dos clientes pueden hacer clic al mismo milisegundo; la regla debe ser clara y verificable.
- Las pujas deben ser estrictamente mayores a la actual + un incremento minimo; se ofrece "puja automatica" hasta un maximo secreto.
- Cada operacion de dinero necesita bitacora de auditoria inalterable.

## El problema
Garantizar que un recurso nunca se asigne a dos personas, que el orden de llegada sea justo y explicable, que los plazos se respeten con precision aun con reinicios del sistema, y que los participantes vean el estado en tiempo real sin que el servidor se sature.

## Escenario a simular
- 200 subastas activas; una con 500 postores y 300 pujas en los ultimos 10 segundos.
- 50 personas intentando reservar los mismos 5 lugares.
- Reinicio del sistema 30 segundos antes de un cierre.

## Casos dificiles
- Dos pujas identicas en el mismo instante: ¿quien gana?
- Expiracion de holds sin consultar toda la base cada segundo.
- Cliente que reintenta una puja por mala red.

## Preguntas guia
1. ¿Quien serializa las operaciones sobre un mismo recurso?
2. ¿Como recuperas los temporizadores tras un reinicio?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
