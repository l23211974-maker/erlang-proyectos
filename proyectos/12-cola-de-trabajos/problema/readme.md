# #12 — Cola de trabajos: el problema

## Contexto
Casi toda aplicacion tiene tareas que no deben bloquear al usuario: enviar correos, generar reportes, redimensionar imagenes, llamar a APIs externas. Herramientas como Sidekiq, Oban o SQS existen porque hacerlo bien es dificil.

## Datos del mundo real
- Servicios como Amazon SQS estandar ofrecen entrega *al menos una vez*: un trabajo puede ejecutarse dos veces. SQS usa un tiempo de visibilidad por omision de 30 s: si el trabajador no termina, otro lo toma.
- Las APIs externas fallan: un 1-5 % de errores transitorios es normal; con reintentos inmediatos se agrava la caida del servicio destino. El *backoff* exponencial (1 s, 2 s, 4 s, 8 s... con jitter) es la practica estandar.
- Un trabajo "envenenado" (siempre falla) debe terminar en una cola de muertos tras N intentos para no ciclar eternamente.
- Algunos trabajos son largos (un reporte de 10 minutos) y otros cortos (50 ms): sin prioridades, los largos bloquean a los cortos.
- El CM5 tiene 4 nucleos: la concurrencia de trabajadores tiene un tope util.

## El problema
Aceptar trabajos de distintos tipos y prioridades, ejecutarlos con concurrencia limitada, reintentar los fallidos sin saturar al servicio externo, no perder trabajos si el sistema se reinicia, y poder ver que esta pendiente, en ejecucion, fallido o muerto.

## Escenario a simular
- 10,000 trabajos encolados de golpe, 3 tipos con tiempos de 50 ms, 2 s y 60 s.
- Un servicio externo que falla durante 5 minutos.
- Un reinicio del sistema con 200 trabajos en ejecucion.

## Casos dificiles
- Trabajo ejecutado dos veces: ¿cuando es peligroso?
- Trabajos que dependen de otros.
- Programar un trabajo "dentro de 3 horas".

## Preguntas guia
1. ¿Que garantia ofreces: a lo mas una, al menos una o exactamente una vez?
2. ¿Como evitas que los trabajos lentos dejen sin recursos a los rapidos?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
