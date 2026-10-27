# #1 — Viñedos: el problema

## Contexto
Baja California produce la gran mayoria del vino mexicano, y el Valle de Guadalupe (Ensenada) concentra cientos de hectareas de vid y mas de un centenar de bodegas. El clima es mediterraneo-semiarido: lluvia anual de ~250-300 mm, concentrada en invierno, y un acuifero sobreexplotado. Cada gota de riego cuenta y una helada tardia o un brote de mildiu puede arruinar una cosecha.

## Datos del mundo real
- **Helada de primavera:** tras la brotacion (marzo-abril), temperaturas de ~0 °C a -2 °C queman brotes y pueden destruir buena parte de la produccion del año. El aire frio se acumula en las partes bajas de la parcela: dos hileras a 200 m pueden diferir 2-3 °C.
- **Mildiu (Plasmopara viticola):** la regla agronomica de "los tres 10": ~10 mm de lluvia, ~10 °C de temperatura minima y brotes de ~10 cm. La infeccion se favorece con hoja mojada continua por 6-8 horas o mas con temperaturas de 18-25 °C.
- **Riego deficitario controlado:** en vid de vino se riega por debajo de la demanda a proposito para mejorar calidad; sobre-regar baja la calidad y desperdicia agua.
- **Sensores tipicos:** humedad de suelo capacitiva (0-100 % VWC, a 30/60 cm), temperatura de aire/suelo, hoja mojada (resistivo, valor 0-15 aprox.). Reportan cada 1-15 min; los nodos LoRa/celular fallan por bateria, polvo y roedores.
- Una parcela de 10 ha puede tener 20-40 hileras, cada una con 3-4 sensores: cientos de dispositivos por finca.

## El problema
Un viticultor necesita saber, hilera por hilera, cuando regar, cuando proteger contra helada y cuando aplicar fungicida, sin ir a caminar la finca. Los datos llegan incompletos, tarde o absurdos (un sensor de humedad que marca 400 %). El sistema debe seguir operando cuando partes de la finca dejan de reportar, y no puede regar ni alertar por una lectura corrupta.

## Escenario a simular
- 5 parcelas, ~100 hileras, ~350 sensores, lectura cada 60 s (≈6 lecturas/s agregadas).
- Una noche de helada: temperatura bajando 1.5 °C/hora, con 10 % de sensores sin reportar.
- Una semana humeda con hoja mojada acumulada de dia y noche.

## Casos dificiles
- Sensor silencioso: ¿esta muerto o simplemente no hay cambios?
- Lecturas fuera de rango o saltos fisicamente imposibles.
- El riego es una accion fisica (valvula) con consecuencias; ¿que pasa si se pide regar durante una alerta de helada?
- Reinicio del sistema a mitad de un riego.

## Preguntas guia
1. ¿Que significa "estado actual de una hilera" cuando solo tienes lecturas viejas?
2. ¿Que fallas son aceptables y cuales no (regar de mas vs. no regar)?
3. ¿Como se explica al viticultor por que el sistema tomo una decision?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
