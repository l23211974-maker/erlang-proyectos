# #33 — OEE de máquinas: el problema

## Contexto
La Eficiencia General del Equipo (OEE) es el indicador estandar de manufactura para saber que tan bien se aprovecha una maquina. Se calcula como Disponibilidad × Rendimiento × Calidad y revela perdidas que ocultan los reportes de papel.

## Datos del mundo real
- **Disponibilidad** = tiempo produciendo / tiempo planeado. **Rendimiento** = produccion real / produccion ideal a velocidad nominal. **Calidad** = piezas buenas / piezas totales.
- Ejemplo: 90 % × 95 % × 99 % ≈ 84.6 %. Se considera de clase mundial un OEE de ~85 %; el promedio en muchas plantas anda cerca de 60 %.
- Las "seis grandes perdidas": fallas, cambios y ajustes, microparos, velocidad reducida, defectos de arranque y defectos en proceso.
- Los microparos (menores a ~5 min) no se anotan a mano y representan gran parte de la perdida real.
- Las maquinas reportan señales digitales (en marcha, paro, alarma), contador de piezas y de rechazos; los PLC se consultan con OPC UA o Modbus. Los contadores se reinician y la señal tiene ruido.

## El problema
A partir de señales crudas de varias maquinas, clasificar cada instante de tiempo (produciendo, paro planeado, paro no planeado, velocidad reducida), calcular el OEE por maquina, turno y dia en tiempo real, y mostrar donde se pierde mas tiempo para decidir que atacar primero.

## Escenario a simular
- 10 maquinas, 3 turnos, contador de piezas cada segundo.
- Rafaga de microparos de 30 s durante 2 horas en una sola maquina.
- Una maquina cuyo contador de piezas se reinicia a mitad del turno.

## Casos dificiles
- Un paro sin razon capturada: ¿quien lo clasifica y cuando?
- Cambio de turno a mitad de un paro.
- Calcular OEE mientras faltan datos de una maquina.

## Preguntas guia
1. ¿Cual es el tiempo planeado y quien lo define?
2. ¿Que cuentas como microparo y que como produccion a baja velocidad?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
