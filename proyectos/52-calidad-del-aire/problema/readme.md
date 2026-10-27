# #52 — Calidad del aire: el problema

## Contexto
Tijuana y la region fronteriza sufren contaminacion por trafico de vehiculos viejos, polvo, quemas y episodios de Santa Ana que arrastran humo y particulas. La red oficial de monitoreo es escasa, asi que se complementa con sensores de bajo costo. Las particulas PM2.5 (menores a 2.5 µm) entran al torrente sanguineo y se asocian con asma, enfermedades del corazon y muerte prematura.

## Datos del mundo real
- **Referencias de PM2.5:** la OMS (2021) recomienda no pasar de 15 µg/m³ en promedio de 24 h y 5 µg/m³ anual. La norma mexicana NOM-025-SSA1-2021 fija limites de 33 µg/m³ (24 h) y 10 µg/m³ (anual).
- **AQI de la EPA** (categorias revisadas en 2024) para PM2.5: Bueno 0-9.0, Moderado 9.1-35.4, Dañino para grupos sensibles 35.5-55.4, Dañino 55.5-125.4, Muy dañino 125.5-225.4 µg/m³.
- Sensores laser baratos (clase Plantower PMS5003, usados en PurpleAir) cuestan unos cientos de pesos, pero **se sobrestiman con alta humedad** y se degradan con el tiempo; requieren correccion y comparacion con estaciones de referencia.
- El AQI se calcula con promedios (24 h; promedio movil de ~1-12 h para avisos rapidos), no con una sola lectura instantanea.
- Los sensores envian cada 1-2 min; un humo puede subir la concentracion 10 veces en 20 minutos.

## El problema
Recibir lecturas de una red de sensores dispersos, limpiar valores erroneos, calcular promedios moviles y el indice por zona, interpolar la condicion entre sensores, y emitir avisos por nivel de contaminacion sin falsas alarmas por un solo sensor defectuoso.

## Escenario a simular
- 25 sensores en la ciudad, lectura cada 2 min.
- Un incendio cercano que dispara PM2.5 de 10 a 150 µg/m³ en una hora.
- Un sensor que se queda pegado en 999 µg/m³.

## Casos dificiles
- Corregir por humedad sin ocultar episodios reales.
- Concordancia entre sensores vecinos para validar una alerta.
- Datos faltantes en el promedio de 24 h.

## Preguntas guia
1. ¿Cuantos sensores deben coincidir para considerar real un episodio?
2. ¿Cuanto tiempo de datos requiere cada promedio para ser valido?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
