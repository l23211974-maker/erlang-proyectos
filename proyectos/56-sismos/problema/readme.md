# #56 — Sismos: el problema

## Contexto
Baja California esta cruzada por el sistema de fallas San Andres-Golfo de California (fallas Agua Blanca, Rose Canyon, Cerro Prieto, San Miguel, entre otras). El 4 de abril de 2010 el terremoto El Mayor-Cucapah (Mw 7.2) sacudio Mexicali y la region. Detectar y reportar sismos con rapidez salva vidas y orienta la respuesta.

## Datos del mundo real
- Las ondas **P** viajan a ~6 km/s y las **S** (las destructivas) a ~3.5 km/s. A 100 km del epicentro, las S llegan ~13 s despues de las P (que es la ventana de alerta temprana).
- Servicios publicos como el USGS publican feeds de sismos en formato GeoJSON, actualizados cada minuto, con magnitud, profundidad, coordenadas y hora.
- La **magnitud** (escala logaritmica) mide la energia: cada punto es ~32 veces mas energia. La **intensidad** (Mercalli) depende de la distancia y el suelo.
- La informacion inicial se corrige: la magnitud reportada a los primeros minutos puede cambiar en 0.3 o mas; un mismo evento llega varias veces con revisiones y de varias redes.
- Lo que se avisa depende del lugar: un M4 a 20 km se siente; uno a 800 km no.

## El problema
Ingerir eventos sismicos de distintas fuentes, eliminar duplicados, tratar las revisiones de un mismo evento, calcular el efecto probable en ubicaciones de interes (segun magnitud y distancia), emitir alertas escalonadas por severidad y evitar tanto el silencio como las falsas alarmas.

## Escenario a simular
- Flujo de 50 eventos por hora de varias fuentes, con duplicados y revisiones.
- Un M6.5 cercano con 3 revisiones en 10 minutos y replicas.
- Una fuente que se cae o manda eventos atrasados.

## Casos dificiles
- Identificar que dos reportes son el mismo sismo.
- Una alerta ya enviada cuya magnitud se corrige a la baja (o a la alta).
- Enjambres sismicos con decenas de eventos pequeños.

## Preguntas guia
1. ¿Cual es la identidad de un sismo si las fuentes discrepan?
2. ¿Cuando una revision amerita volver a avisar?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
