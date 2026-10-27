# #58 — Playa y oleaje: el problema

## Contexto
Playas de Tijuana, Rosarito y Ensenada reciben miles de bañistas y surfistas los fines de semana. El oleaje, las corrientes de resaca, la marea y la calidad del agua cambian durante el dia. La contaminacion por aguas residuales del rio Tijuana ha cerrado playas vecinas por largos periodos.

## Datos del mundo real
- Segun la Asociacion de Salvavidas de EE. UU. (USLA), aproximadamente el 80 % de los rescates que hacen los salvavidas en playas son por **corrientes de resaca** (rip currents).
- Sistema de banderas internacional/USLA: verde (condiciones bajas), amarilla (peligro moderado), roja (alto peligro), doble roja (cerrado al agua), morada (fauna marina peligrosa).
- Parametros de oleaje: altura significativa (Hs), periodo (Tp) y direccion; boyas de la red NDBC/CDIP los publican. Oleaje de 2 m con periodo largo (> 14 s) puede ser peligroso aun con cielo despejado.
- La marea cambia el peligro: con marea baja se exponen bancos de arena que forman resacas.
- Calidad del agua: en Mexico, el programa Playas Limpias usa el indicador de enterococos fecales, con limite de ~200 NMP/100 ml; los resultados de laboratorio tardan 24-48 h, y la lluvia fuerte eleva la contaminacion.
- En verano el agua puede estar a 18-21 °C y en invierno bajo 15 °C.

## El problema
Integrar datos de oleaje, viento, marea, lluvias recientes y calidad del agua para decidir, por playa, que bandera corresponde, justificar la decision de manera transparente, avisar cuando las condiciones cambian y llevar un historial de cada decision.

## Escenario a simular
- 6 playas, boya de oleaje cada 30 min, marea por tabla, viento cada 10 min.
- Una marejada que sube Hs de 1 m a 3 m en 4 horas.
- Un resultado de laboratorio atrasado que contradice la bandera vigente.

## Casos dificiles
- Reglas que cambian de nivel al cruzar un umbral y regresan (rebote).
- Datos de una boya que se pierden.
- Un nivel de seguridad que depende del peor de varios factores.

## Preguntas guia
1. ¿Como evitas que la bandera cambie cada 5 minutos?
2. ¿Quien tiene la ultima palabra: el sistema o el salvavidas?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
