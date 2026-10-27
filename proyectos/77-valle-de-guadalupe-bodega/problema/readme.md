# #77 — Valle de Guadalupe, bodega: el problema

## Contexto
El Valle de Guadalupe, a ~90 minutos de Tijuana, produce la gran mayoria del vino de Mexico. La vendimia (agosto-septiembre) concentra en pocas semanas el trabajo de todo el año, y una bodega pequeña maneja decenas de tanques en distintas etapas. Un tanque que se sobrecalienta o se detiene puede echar a perder miles de litros.

## Datos del mundo real
- La fermentacion alcoholica convierte azucar en alcohol y calor: una referencia comun es que un mosto de ~24 °Brix produce ~13-14 % de alcohol. El **°Brix baja** ~1-2 grados por dia durante la fermentacion activa.
- Temperaturas objetivo: blancos y rosados 12-18 °C; tintos 24-30 °C. A mas de ~35 °C las levaduras sufren y pueden **detenerse** (fermentacion atorada) dejando azucar residual y riesgo de bacterias.
- La fermentacion es **exotermica**: un tanque grande puede subir varios grados en horas si no se enfria con camisas de glicol.
- Fases: recepcion y estrujado → maceracion en frio → fermentacion alcoholica (5-14 dias) → fermentacion malolactica (semanas) → crianza en barrica o acero (meses a años) → embotellado.
- En tintos se hacen "remontados" o "bazuqueos" varias veces al dia para mojar el sombrero; es trabajo manual con horario.
- Cada tanque tiene su lote de uva, variedad, fecha, registros de analisis y trazabilidad.

## El problema
Modelar cada tanque con su propia fase y objetivos, medir temperatura y densidad, controlar el enfriamiento, detectar desviaciones (calor excesivo, fermentacion lenta o detenida), programar tareas del enologo, y registrar toda la historia de un lote desde la uva hasta la botella.

## Escenario a simular
- 30 tanques, 6 variedades, temperatura y densidad cada 15 min, vendimia de 3 semanas.
- Tanque tinto que sube 1 °C por hora por falla del glicol.
- Fermentacion que deja de bajar su densidad 3 dias.

## Casos dificiles
- Trasiego de un tanque a otro: ¿el lote sigue siendo el mismo?
- Mezclas de lotes (coupage) y su trazabilidad.
- Alertas en la madrugada: ¿a quien y cuando?

## Preguntas guia
1. ¿Que transicion de fase es irreversible y quien la autoriza?
2. ¿Que diferencia una desviacion normal de una emergencia?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
