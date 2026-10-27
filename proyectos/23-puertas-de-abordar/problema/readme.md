# #23 — Puertas de abordar: el problema

## Contexto
Un aeropuerto tiene pocas puertas (*gates*) y muchos vuelos. Asignar la puerta correcta a cada vuelo, y cambiarla a tiempo cuando algo falla, determina si los pasajeros abordan a tiempo o corren por la terminal.

## Datos del mundo real
- Un vuelo de fuselaje angosto (tipo Boeing 737 / Airbus A320, ~150-190 pasajeros) tarda tipicamente 40-60 min en rotacion (*turnaround*) y el abordaje dura unos 25-35 min. Una puerta debe estar libre al menos desde que llega la aeronave hasta que se va, mas un colchon de seguridad.
- Un cambio de puerta tardio afecta a cientos de personas que deben ser informadas por pantallas, altavoces y apps.
- Restricciones reales: tamaño de aeronave soportado por la posicion, puertas internacionales vs nacionales (por aduana), posiciones remotas con autobus, mantenimiento de la puerta, preferencia de aerolinea.
- Las demoras provocan traslapes: el vuelo previo aun ocupa la puerta cuando llega el siguiente.
- En TIJ la terminal es compacta con pocas puertas, por lo que cada conflicto es importante.

## El problema
Asignar puertas a vuelos sin traslapes de ocupacion y respetando restricciones, y reasignar dinamicamente cuando los horarios cambian, minimizando el numero de cambios que afectan a los pasajeros y notificando a quien corresponda.

## Escenario a simular
- 8 puertas, 60 vuelos en un dia, 3 tipos de aeronave.
- Una puerta fuera de servicio de repente a medio dia.
- Dos vuelos demorados que ahora compiten por la misma puerta.

## Casos dificiles
- Una reasignacion en cadena: mover un vuelo obliga a mover otros.
- Dos operadores reasignan la misma puerta al mismo tiempo.
- Cuando no hay solucion perfecta, ¿cual se elige?

## Preguntas guia
1. ¿Que significa "conflicto" en terminos de intervalos de tiempo?
2. ¿Cuanto cambio es aceptable para no confundir a los pasajeros?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
