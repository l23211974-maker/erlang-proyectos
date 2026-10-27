# #36 — Mantenimiento predictivo: el problema

## Contexto
Una falla inesperada de una maquina critica puede detener toda una linea. Los estudios de la industria hablan de costos de paro no planeado de miles de dolares por minuto en automotriz y cientos de miles por hora en plantas grandes. El mantenimiento predictivo intenta anticipar la falla midiendo la salud del equipo: vibracion, temperatura, corriente, ruido.

## Datos del mundo real
- Los rodamientos son una de las causas mas comunes de falla en motores. Antes de fallar, aumenta la vibracion en frecuencias caracteristicas del defecto y luego la temperatura.
- Sensores de vibracion (acelerometros) muestrean a miles de Hz (5-50 kHz); no se envia todo: se calculan resumenes (RMS, pico, curtosis) y espectros (FFT).
- ISO 10816/20816 clasifica severidad de vibracion por velocidad RMS (mm/s) en zonas A (bueno) a D (peligro), segun el tipo de maquina; por ejemplo, valores de unos 4.5-7 mm/s en maquinas medianas ya son alerta.
- Regla de Montsinger: cada 10 °C por encima de la temperatura nominal reduce a la mitad la vida del aislamiento de un motor.
- Un buen sistema no solo alerta por umbral fijo; compara contra la linea base de esa maquina y observa la tendencia.

## El problema
Recibir señales de vibracion y temperatura de muchas maquinas, calcular indicadores de salud, definir niveles de alerta (normal, vigilancia, alarma, paro), detectar tendencias de degradacion y estimar cuanto tiempo queda antes de llegar al limite, evitando avisar por picos aislados.

## Escenario a simular
- 20 maquinas, vibracion y temperatura simuladas con ruido.
- Un rodamiento cuya vibracion crece 2 % por dia durante 3 semanas.
- Sensor que se desconecta o se pega en un valor fijo.

## Casos dificiles
- Distinguir un pico por golpe de una degradacion.
- Cambios de carga o velocidad que alteran la linea base.
- Alertar a tiempo para planear, no para correr.

## Preguntas guia
1. ¿Que tan grande debe ser un cambio para ser una señal y no ruido?
2. ¿Cuanto adelanto necesita el equipo de mantenimiento para actuar?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
