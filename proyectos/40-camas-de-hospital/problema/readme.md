# #40 — Camas de hospital: el problema

## Contexto
Mexico tiene una de las razones mas bajas de camas hospitalarias por habitante entre los paises de la OCDE (del orden de 1 por cada 1,000 habitantes, frente a ~4 de promedio). Cada cama cuenta, y una cama vacia por un alta mal coordinada o una limpieza tardia es una cama que otro paciente necesita. Proyecto educativo de simulacion.

## Datos del mundo real
- Ocupaciones superiores a ~85 % suelen provocar saturacion: urgencias se llena, se cancelan cirugias y hay pacientes en pasillos (teoria de colas: el tiempo de espera crece muy rapido cerca del 100 %).
- Ciclo de una cama: ocupada → alta indicada → paciente sale → limpieza/desinfeccion (tipicamente 30-60 min) → disponible. Hay camas de aislamiento, terapia intensiva, pediatria, maternidad, etc., con reglas distintas.
- El retraso en altas (esperando receta, transporte o familiares) es una causa conocida de bloqueo de camas.
- Hay una gestion de cama distinta por tipo: un paciente de terapia no se puede asignar a cama general.
- Las altas se concentran por la tarde, mientras que los ingresos de urgencias llegan por la noche.

## El problema
Mantener el estado de cada cama por servicio, asignar la cama adecuada al paciente que ingresa, coordinar el flujo de alta y limpieza, predecir cuantas camas quedaran libres en las proximas horas y avisar cuando la ocupacion cruza umbrales criticos.

## Escenario a simular
- 120 camas en 6 servicios, 40 ingresos y 40 altas al dia.
- Brote que llena el area de aislamiento.
- Alta que se indica, pero la limpieza tarda 2 horas.

## Casos dificiles
- Dos servicios piden la misma cama libre.
- Traslado interno de paciente: la cama de origen y destino a la vez.
- Prediccion de camas con altas inciertas.

## Preguntas guia
1. ¿Cuales son los estados legales de una cama y quien dispara cada cambio?
2. ¿Que decision tomas cuando no hay cama del tipo requerido?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
