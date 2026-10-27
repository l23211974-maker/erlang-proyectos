# #41 — Signos vitales: el problema

## Contexto
En hospitalizacion y terapia intensiva, monitores miden continuamente los signos de cada paciente. Una enfermera puede estar a cargo de varios; el sistema debe avisar con oportunidad cuando algo se deteriora. Proyecto educativo con datos simulados, no un dispositivo medico.

## Datos del mundo real
- Rangos aproximados en adultos en reposo: frecuencia cardiaca 60-100 lpm, respiratoria 12-20 rpm, SpO₂ ≥ 95 %, temperatura 36.1-37.2 °C, presion arterial sistolica 90-120 mmHg.
- El puntaje **NEWS2** (Royal College of Physicians, 2017) suma puntos por cada signo fuera de rango; un puntaje alto (≥5-7) exige respuesta urgente.
- Frecuencia de datos: ECG a 250+ Hz, SpO₂ y frecuencia cada segundo, presion y temperatura cada minutos.
- **Fatiga de alarmas:** estudios reportan que una gran proporcion de las alarmas clinicas (entre 72 % y 99 %) son falsas o no accionables, y el personal termina ignorandolas. Es un riesgo documentado para la seguridad del paciente.
- Un sensor desconectado (dedo sin pulsioximetro) produce valores 0 o vacios que no son una emergencia clinica sino tecnica.

## El problema
Recibir señales de multiples pacientes, evaluar cada una contra limites (que dependen del paciente), combinar varias señales en un nivel de gravedad, y generar alarmas que sean confiables: distinguir entre falla tecnica y deterioro clinico, evitar rebotes y repeticiones, y escalar si nadie acusa recibo.

## Escenario a simular
- 30 pacientes, 4 señales cada uno, actualizacion cada segundo.
- Deterioro progresivo de un paciente durante 20 minutos.
- 3 sensores desconectados y 1 paciente con ruido por movimiento.

## Casos dificiles
- Alarma que se activa y se limpia repetidamente en el limite.
- Limites distintos por paciente (EPOC, niño).
- Alarma sin acuse de recibo.

## Preguntas guia
1. ¿Cuando una alarma es tecnica y cuando clinica, y como se trata cada una?
2. ¿Como reduces falsas alarmas sin ocultar las reales?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
