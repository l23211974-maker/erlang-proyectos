# #37 — Cadena de frío: el problema

## Contexto
Vacunas, sangre, medicinas, mariscos y alimentos frescos deben mantenerse dentro de un rango de temperatura desde el productor hasta el consumidor. Una sola excursion fuera de rango puede arruinar un lote entero. Baja California exporta producto agricola y pesquero, y distribuye medicinas, por lo que depende de camiones y bodegas refrigeradas.

## Datos del mundo real
- Vacunas tipicas: 2-8 °C. Algunas vacunas de ARNm de COVID-19 requirieron -70 °C. Congelados: -18 °C o menos.
- Zona de peligro de los alimentos: entre 4 °C y 60 °C las bacterias se multiplican con rapidez; la regla general es no pasar mas de 2 horas acumuladas en esa zona.
- Los *data loggers* registran temperatura cada 1-15 min; los modernos transmiten por celular, pero un camion cruzando la frontera o una zona rural pierde señal.
- Abrir las puertas del camion o la bodega en una descarga sube la temperatura temporalmente: hay que distinguir apertura de falla del equipo.
- Normas aplicables incluyen HACCP, FSMA (EE. UU.) y la normatividad sanitaria mexicana (COFEPRIS, NOM); el registro de temperaturas es evidencia legal.

## El problema
Monitorear la temperatura de muchas unidades de transporte y camaras, detectar *excursiones* con su duracion y magnitud acumulada, avisar antes de que se pierda el producto, mantener un registro continuo y a prueba de huecos, y decidir si un lote sigue siendo utilizable.

## Escenario a simular
- 12 camiones y 4 camaras de bodega, lectura cada 2 min.
- Falla del compresor: la temperatura sube 1 °C cada 10 min.
- Un camion que pierde conexion 3 horas y reporta todo al volver.

## Casos dificiles
- Reconstruir el historial con lecturas atrasadas.
- Sensor descalibrado con 2 °C de error.
- Calcular tiempo fuera de rango acumulado entre varias excursiones.

## Preguntas guia
1. ¿Que es una excursion y cuando se vuelve un lote perdido?
2. ¿Como demuestras que no hubo excursion durante el hueco de datos?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
