# #25 — Garitas San Ysidro y Otay: el problema

## Contexto
San Ysidro es considerado el cruce terrestre mas transitado del hemisferio occidental: en años normales pasan decenas de miles de vehiculos y decenas de miles de peatones diariamente hacia EE. UU. Otay Mesa es el segundo cruce vehicular de la zona y el principal para carga comercial. Los tiempos de espera hacia el norte pueden pasar de 3 horas en horas pico, y miles de personas cruzan a diario por trabajo, estudio y compras.

## Datos del mundo real
- Carriles: *General*, *Ready Lane* (documentos con RFID) y *SENTRI* (viajero confiable); en Otay tambien carriles comerciales FAST. Cada tipo tiene tiempos de espera tipicamente muy distintos (SENTRI suele ser una fraccion del General).
- La agencia CBP publica tiempos de espera por carril, actualizados cada 1-2 horas y accesibles como feed (por ejemplo, bwt.cbp.gov); las fuentes oficiales tienen retraso respecto a la realidad.
- Patrones fuertes por hora y dia: lunes por la mañana y viernes por la tarde, domingos por la tarde en regreso, dias festivos de ambos paises.
- Las esperas dependen de cuantas cabinas abren, la hora, incidentes y revisiones secundarias.

## El problema
Con datos historicos y mediciones recientes por carril, estimar la espera actual y proyectar las proximas horas con un metodo sencillo (promedios moviles), recomendar a la persona que va a cruzar el mejor momento y carril/garita, y avisar cuando algo cambia bruscamente, sin presentar un numero engañoso cuando los datos son malos o viejos.

## Escenario a simular
- 2 garitas, 3 tipos de carril, una lectura por carril cada 15 minutos.
- Un incidente que dispara la espera de 40 min a 150 min en 30 minutos.
- Un carril que deja de reportar por 2 horas.

## Casos dificiles
- Mezclar fuentes con distinta frecuencia y calidad.
- Estimar con promedios moviles cuando hay un cambio brusco.
- Presentar incertidumbre al usuario.

## Preguntas guia
1. ¿Cuanta historia pesa mas: la de hace 15 min o la del mismo dia y hora de hace 4 semanas?
2. ¿Cuando prefieres decir "no sé" a dar un numero?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
