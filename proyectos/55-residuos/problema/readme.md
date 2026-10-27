# #55 — Residuos: el problema

## Contexto
En Mexico se genera alrededor de 0.9-1.0 kg de residuos por persona al dia; una ciudad del tamaño de Tijuana produce del orden de mil o mas toneladas diarias. La recoleccion es la parte mas cara del manejo de residuos (a menudo la mitad o mas del presupuesto), y las rutas fijas pasan por contenedores medio vacios o ya desbordados.

## Datos del mundo real
- Contenedores con sensor ultrasonico miden el nivel de llenado y lo reportan cada hora o menos. El sensor puede dar lecturas falsas por basura inclinada, humedad o lluvia.
- Un camion compactador recolector lleva de 8 a 12 toneladas; hace entre 1 y 3 viajes al relleno sanitario por turno; el trayecto al sitio de disposicion puede ser de 30-60 minutos.
- La velocidad de llenado cambia con el sitio: un contenedor junto a un restaurante o un mercado se llena en un dia, uno en una zona residencial tarda una semana. Los lunes y despues de festivos hay mas basura.
- El problema de ruteo con capacidad limitada y ventanas de tiempo (trafico, horario de operadores) se resuelve con heuristicas; no con la solucion perfecta.
- Un contenedor desbordado genera quejas, plagas y tiraderos clandestinos.

## El problema
Monitorear el nivel de miles de contenedores, estimar cuando se llenara cada uno, y generar cada dia las rutas de recoleccion priorizando los contenedores que lo necesitan, dentro de la capacidad del camion y la jornada, replanificando cuando surgen urgencias.

## Escenario a simular
- 300 contenedores, 5 camiones de 10 t, jornada de 8 h.
- Evento masivo que satura 20 contenedores en una zona.
- Un camion que se descompone con carga a la mitad.

## Casos dificiles
- Filtrar sensores con lecturas erraticas.
- Decidir recoger un contenedor al 60 % porque esta de paso.
- Camion lleno antes de terminar la ruta.

## Preguntas guia
1. ¿Como predices que un contenedor se llenara antes de la siguiente visita?
2. ¿Que equilibra el sistema entre costo de ruta y riesgo de desborde?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
