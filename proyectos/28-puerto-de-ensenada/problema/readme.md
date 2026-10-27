# #28 — Puerto de Ensenada: el problema

## Contexto
El Puerto de Ensenada es uno de los puertos del Pacifico mexicano con carga contenerizada, granel, pesca y cruceros turisticos (con cientos de miles de pasajeros al año antes de la pandemia). Su terminal de contenedores y su terminal de cruceros comparten canal, remolcadores y personal. Cada hora de un buque en el muelle cuesta miles de dolares.

## Datos del mundo real
- Un buque portacontenedores mediano puede tener cientos o miles de contenedores a mover; una grua de muelle mueve del orden de 25-35 contenedores por hora (movimientos/hora).
- Se asignan tipicamente 1-3 gruas por buque segun su tamaño y tiempos de salida.
- El patio tiene espacio finito y los contenedores deben apilarse (3-5 alturas) en orden compatible con su salida; sacar uno enterrado obliga a mover los de encima ("remociones").
- El atraque requiere practico, remolcadores, marea, viento y ventana de calado; un buque que llega tarde ocupa el muelle de otro.
- Los cruceros tienen horarios fijos de llegada de pasajeros que deben cumplir antes de zarpar.

## El problema
Programar turnos de atraque en un numero limitado de muelles, asignar gruas y cuadrillas a cada buque, y llevar el control de contenedores en patio, minimizando el tiempo que los buques esperan fondeados, sin chocar con restricciones de marea, personal y equipo, y replanificando cuando un buque llega adelantado o retrasado.

## Escenario a simular
- 3 muelles, 5 gruas, 12 buques en una semana, incluyendo 2 cruceros.
- Un buque que llega 8 horas tarde por mal clima.
- Una grua que se descompone a mitad de operacion.

## Casos dificiles
- Dos buques que quieren el mismo muelle en horarios traslapados.
- Rebalancear gruas entre buques sin perder avance.
- Contenedores perdidos o mal registrados en patio.

## Preguntas guia
1. ¿Como modelas un recurso (muelle, grua) que no se puede compartir en el mismo instante?
2. ¿Cual es la prioridad: el crucero o el carguero?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
