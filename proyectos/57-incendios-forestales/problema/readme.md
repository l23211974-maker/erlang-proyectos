# #57 — Incendios forestales: el problema

## Contexto
Los incendios en Baja California y el sur de California se alimentan de chaparral seco, laderas empinadas y vientos de Santa Ana. En octubre de 2007 el incendio Witch Creek, en el condado de San Diego, quemo del orden de 200,000 acres, y los cañones de Tijuana son zonas donde la ciudad y el monte se tocan. El tiempo de reaccion marca la diferencia entre una llama pequeña y un desastre.

## Datos del mundo real
- Las alertas meteorologicas de bandera roja usan combinaciones como humedad relativa ≤ 15 % con viento sostenido ≥ ~40 km/h, durante varias horas.
- Un fuego avanza mas rapido cuesta arriba: como regla practica, la velocidad se duplica aproximadamente cada 10° de pendiente.
- Un sensor de humo/temperatura en un cañon puede estar lejos de una fuente de energia y comunicarse por LoRa o celular; el fuego destruye los propios sensores.
- La humedad del combustible muerto (hojarasca, ramas) por debajo de ~8-10 % hace que el incendio se propague con mucha facilidad.
- Fuentes satelitales (NASA FIRMS) reportan puntos de calor cada pocas horas con retraso; los sensores en sitio dan tiempo real pero solo en donde existen.
- Existen fuentes de falsas alarmas: quemas agricolas autorizadas, fogatas, reflejos, polvo.

## El problema
Correlacionar lecturas de temperatura y humo de muchos sensores con condiciones del clima para detectar un posible incendio, calcular un nivel de riesgo por zona, confirmar con varias fuentes antes de alertar, estimar la direccion probable de avance y avisar a las autoridades con las coordenadas.

## Escenario a simular
- 40 sensores en 5 cañones, lectura cada minuto.
- Dia de Santa Ana: humedad 10 %, viento 60 km/h.
- Dos sensores que reportan alta temperatura y humo, y tres vecinos que no.

## Casos dificiles
- Sensor que muere (¿falla o quemado?).
- Alertar demasiado temprano o demasiado tarde.
- Estimar avance con datos de viento cambiante.

## Preguntas guia
1. ¿Cuantas fuentes deben coincidir para escalar una alerta?
2. ¿Que significa que un sensor "dejo de reportar" en medio de un incendio?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
