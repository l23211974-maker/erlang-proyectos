# #5 — Estación meteorológica: el problema

## Contexto
Tijuana y Baja California tienen microclimas marcados: neblina costera, vientos de Santa Ana en otoño-invierno (rafagas de 60-100 km/h y humedad relativa muy baja que disparan incendios) y lluvias escasas pero torrenciales que provocan deslaves. El Servicio Meteorologico Nacional opera cientos de estaciones, pero la red es escasa para microclimas; estaciones aficionadas y escolares llenan huecos.

## Datos del mundo real
- **Normas OMM:** viento se reporta como promedio de 10 min; la rafaga es el maximo en ~3 s. Temperatura y humedad a 1.25-2 m, protegidas de radiacion solar directa.
- **Pluviometro de cangilon:** cada vuelco ≈ 0.2 mm (o 0.254 mm); la intensidad se obtiene contando vuelcos por tiempo.
- **Presion:** la lectura de estacion debe reducirse a nivel del mar usando la altitud para compararse con otras.
- **Frecuencias de muestreo tipicas:** viento cada 2-3 s, temperatura y humedad cada 10-60 s, pluviometro por evento.
- **Fallas comunes:** anemometro atascado por sal o aves, sensor de humedad que deriva, radiacion que sobrecalienta el sensor, perdidas de energia y de red.

## El problema
Recibir un flujo continuo de muestras crudas de varios sensores, calcular los valores derivados que usa la meteorologia (promedios moviles, rafagas, acumulados de lluvia, maximos y minimos del dia, sensacion termica, punto de rocio) y detectar condiciones que ameritan aviso (viento fuerte, helada, lluvia intensa), conservando historia.

## Escenario a simular
- 5 estaciones, 8 sensores cada una, muestras entre 1 y 60 s.
- Un episodio de Santa Ana: viento ×3 y humedad cayendo a <15 %.
- Una estacion que se apaga 40 minutos y regresa mandando datos viejos.

## Casos dificiles
- Ventanas deslizantes con datos faltantes.
- Un sensor en cero fijo: ¿calma o roto?
- Cambio de hora (verano/invierno) y marcas de tiempo.

## Preguntas guia
1. ¿Que significa "promedio de 10 minutos" si solo llegaron 3 muestras?
2. ¿Cuanta historia guardas y a que resolucion?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
