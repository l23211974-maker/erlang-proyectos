# #54 — Gestión de agua: el problema

## Contexto
Tijuana recibe la mayor parte de su agua del Rio Colorado a traves de un acueducto de unos 130 km y la distribuye en una ciudad de colinas, con colonias en partes altas y bajas, y suministro que en algunas zonas es por tandeo. En Mexico se pierde en fugas y tomas clandestinas alrededor del 40 % del agua que se distribuye (agua no contabilizada).

## Datos del mundo real
- La red opera tipicamente con presiones de 10 a 50 metros de columna de agua (≈ 1 a 5 kg/cm²). Presion muy baja = no llega a pisos altos; muy alta = revienta tuberias y aumenta fugas.
- **Metodo de flujo minimo nocturno:** entre las 2 y las 4 a. m. casi nadie consume; si el caudal que entra a una zona sigue alto, hay fuga.
- Balance hidrico por zona: agua que entra (macromedidor) − suma de lo que se mide en tomas = perdidas.
- Un golpe de ariete o una caida repentina de presion puede indicar una ruptura mayor; el tiempo de reaccion se mide en minutos.
- Medidores domiciliarios tradicionales se leen una vez al mes; los inteligentes reportan cada hora.
- El consumo medio domestico en Mexico ronda 150-250 litros por persona al dia segun la zona.

## El problema
Recibir mediciones de presion y caudal por colonia y de consumo en tomas, hacer balances por zona, detectar fugas probables (por patrones nocturnos y caidas de presion) y priorizar a donde mandar una cuadrilla, ademas de proyectar el consumo para planear el suministro.

## Escenario a simular
- 12 colonias, un macromedidor y 5 sensores de presion por colonia, lecturas cada 5 min.
- Fuga que incrementa 15 % el caudal nocturno de una colonia.
- Un sensor de presion descalibrado.

## Casos dificiles
- Distinguir fuga de aumento real de consumo (evento, calor).
- Medidores que reportan con retraso o fuera de orden.
- Balance hidrico con datos incompletos.

## Preguntas guia
1. ¿Que patron diferencia una fuga de un consumo legitimo?
2. ¿Como priorizas entre cinco posibles fugas con una sola cuadrilla?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
