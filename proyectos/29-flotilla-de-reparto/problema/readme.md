# #29 — Flotilla de reparto: el problema

## Contexto
La "ultima milla" (llevar el paquete al cliente) suele ser la etapa mas cara de la logistica: estudios muy citados la situan en mas de la mitad del costo total del envio. Con el auge del comercio electronico en la region fronteriza, las empresas locales de reparto manejan decenas de unidades que recorren una ciudad con trafico, lluvias y cruces.

## Datos del mundo real
- Una unidad de reparto urbano hace entre 60 y 150 entregas al dia segun la densidad; cada parada toma de 2 a 5 minutos.
- La entrega fallida (cliente ausente, direccion mala) ronda 5-15 % y obliga a reprogramar, lo que aumenta el costo.
- Telemetria: GPS cada 5-15 s, velocidad, consumo, estado de motor via OBD-II; conectividad celular con huecos.
- El problema clasico de ruteo de vehiculos (VRP) es NP-dificil: no se busca el optimo perfecto sino una solucion razonable rapida.
- Ventanas de entrega ("entre 2 y 4 pm"), capacidad (peso/volumen) y horas maximas de manejo del conductor limitan la planeacion.

## El problema
Seguir en tiempo real la flotilla, mantener el estado de cada entrega, y *reasignar* paquetes entre unidades cuando una se descompone, se retrasa o aparece un pedido urgente, respetando capacidad y ventanas de entrega, sin recalcular todo el dia cada vez.

## Escenario a simular
- 15 unidades, 900 entregas en el dia, GPS simulado cada 10 s.
- Una unidad averiada a las 11 a. m. con 40 entregas pendientes.
- Un pedido urgente que se inserta a media jornada.

## Casos dificiles
- Reasignar sin dejar entregas huerfanas ni duplicadas.
- Estimar la hora de llegada con trafico variable.
- Conductor sin señal por una hora que luego reporta todo junto.

## Preguntas guia
1. ¿Que significa "entrega asignada" a una unidad y como pasa a otra de forma segura?
2. ¿Cuando conviene una solucion buena y rapida sobre una perfecta y lenta?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
