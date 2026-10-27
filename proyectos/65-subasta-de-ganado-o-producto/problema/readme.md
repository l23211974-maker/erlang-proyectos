# #65 — Subasta de ganado o productos: el problema

## Contexto
En las subastas ganaderas del noroeste de Mexico los lotes de becerros o vacas se venden en minutos, a viva voz, con compradores presentes en el corral y, cada vez mas, conectados desde su rancho. A diferencia del proyecto #18, aqui la subasta es en vivo, con ritmo de martillero, y mezcla participantes presenciales y remotos con latencias distintas.

## Datos del mundo real
- El ganado se vende por **kilo en pie**, con precios del orden de decenas de pesos por kilo que cambian con la temporada, la sequia y el mercado de exportacion; un becerro de ~200 kg puede valer miles de pesos.
- Una subasta puede tener 100-300 lotes y vender cada uno en 1-3 minutos; el martillero sube el precio por escalones y adjudica con el "a la una, a las dos, a las tres".
- Los lotes se pesan en bascula en el momento: peso y precio por kilo definen el total.
- Un postor presencial levanta la mano; uno remoto depende de su internet y puede ver el precio con 1-3 segundos de retraso. Hay que decidir de manera clara quien gano si la puja llega "al mismo tiempo".
- Cada lote requiere identificacion (arete SINIIGA), certificados sanitarios y guia de transito para mover animales.
- La aceptacion de una puja es un compromiso de compra.

## El problema
Conducir una subasta en vivo por lotes, con un precio actual que sube, un reloj de adjudicacion que se reinicia con cada puja, pujas simultaneas de postores locales y remotos, y un registro irrefutable de quien ofrecio que, a que hora y quien gano cada lote.

## Escenario a simular
- 150 lotes, 80 postores (60 en sala, 20 remotos), 1 martillero.
- Puja remota que llega 2 segundos despues de la adjudicacion.
- Un postor remoto que pierde conexion en plena puja ganadora.

## Casos dificiles
- Puja justo en el instante del martillazo.
- Retirar un lote a media subasta.
- Reinicio del sistema durante un lote activo.

## Preguntas guia
1. ¿Quien tiene la autoridad del orden de las pujas y como se explica el desempate?
2. ¿Que se hace con una puja recibida por un postor desconectado?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
