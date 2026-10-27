# #6 — Estacionamiento inteligente: el problema

## Contexto
Estudios compilados por Donald Shoup estiman que cerca del 30 % del trafico en zonas centricas es gente buscando donde estacionarse (con promedios de varios minutos por viaje). Centros comerciales, hospitales, aeropuertos y universidades tienen cientos o miles de cajones y sus usuarios pierden tiempo y combustible dando vueltas.

## Datos del mundo real
- Un cajon mide ~2.5 × 5 m; un estacionamiento de centro comercial grande puede superar los 2,000 cajones.
- Sensores: magneticos en piso, ultrasonicos en techo, camaras con vision, laser en entradas/salidas. Tienen falsos positivos (motos, carritos, cambios de temperatura) y falsos negativos.
- Contar entradas y salidas en rampas acumula error con el tiempo (deriva): si falla 1 de cada 200 eventos, tras un dia el conteo ya no es real.
- Picos: horas de entrada de oficinas, fines de semana y temporada navideña pueden llenar un estacionamiento en 30-40 min.
- Tarifas dinamicas: aumentar el precio cuando la ocupacion pasa de ~85 % busca dejar 1 de cada 7 cajones libre.

## El problema
Mantener un tablero confiable de ocupacion por nivel y zona a partir de sensores ruidosos, guiar al conductor al cajon libre mas conveniente sin mandar a dos autos al mismo cajon, y manejar reservaciones temporales.

## Escenario a simular
- 3 niveles, 600 cajones, 6 rampas con barrera.
- Llegada de 300 autos en 20 minutos; 5 % de sensores con falla.
- Reserva de cajon con expiracion a 10 minutos.

## Casos dificiles
- Dos usuarios piden "el mejor cajon" al mismo tiempo.
- Reconciliar el conteo de rampas con el conteo por cajon.
- Un sensor reporta "ocupado" por 3 dias seguidos.

## Preguntas guia
1. ¿Quien es la fuente de verdad: el conteo de rampas o el de cajones?
2. ¿Como evitas la doble asignacion sin bloquear todo el sistema?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
