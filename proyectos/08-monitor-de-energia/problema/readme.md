# #8 — Monitor de energía: el problema

## Contexto
La electricidad es de los mayores costos operativos de una planta, edificio o campus. En Mexico la CFE factura con tarifas escalonadas (residencial, con tarifa DAC de alto consumo) y, en industria, tarifas horarias con periodos base, intermedio y punta, ademas de cargos por demanda maxima y penalizacion por bajo factor de potencia.

## Datos del mundo real
- **Red en Mexico:** 127 V monofasico / 220 V trifasico, 60 Hz.
- **Demanda maxima:** se mide como promedio de potencia en ventanas de 15 min; un solo pico de unos minutos puede definir el cargo del mes.
- **Factor de potencia:** penalizacion cuando es menor a 0.90 y bonificacion cuando es mayor; se calcula como kW / kVA.
- **Medidores:** hablan Modbus RTU/TCP; un bus RS-485 a 9600 baud con 20 medidores se consulta uno por uno, con tiempos de respuesta de decenas de ms y timeouts frecuentes.
- **Variables tipicas:** V, A, kW, kVAr, kWh acumulado, Hz, THD. Los kWh son un contador acumulativo que puede reiniciarse o desbordarse.

## El problema
Consultar muchos medidores con un bus lento y poco confiable, calcular consumo y demanda por circuito y por edificio, anticipar si la demanda de la ventana actual rebasara un limite, y reportar anomalias (consumo nocturno inusual, caida de voltaje, factor de potencia bajo).

## Escenario a simular
- 30 medidores en 3 buses, consulta cada 5 s, horizonte de 24 h.
- Arranque simultaneo de 3 motores que dispara la demanda.
- Medidor que se reinicia y su contador kWh vuelve a 0.

## Casos dificiles
- Calcular consumo por diferencia de contadores con huecos y reinicios.
- Un medidor lento que retrasa la lectura de los demas en su bus.
- Prorratear consumo entre areas que comparten medidor.

## Preguntas guia
1. ¿Como aislas el mal comportamiento de un medidor del resto del bus?
2. ¿Que alertas puedes dar *antes* de que se pase del limite?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
