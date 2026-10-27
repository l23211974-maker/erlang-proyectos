# #44 — Banco de sangre: el problema

## Contexto
La sangre no se puede fabricar: depende de donantes y caduca. Un banco de sangre debe tener la cantidad adecuada de cada tipo en cada momento y entregarla rapido en una emergencia. Proyecto educativo de simulacion.

## Datos del mundo real
- **Vida util:** globulos rojos hasta 35-42 dias refrigerados (1-6 °C); plaquetas solo 5-7 dias (a ~22 °C con agitacion); plasma congelado hasta 1 año.
- Una unidad de sangre total es ~450 ml. Entre una donacion de sangre total y la siguiente debe pasar un intervalo de varios meses que fija la norma (verificalo en la NOM vigente).
- **Compatibilidad ABO/Rh:** O negativo puede darse a casi todos (donante universal de globulos rojos); AB positivo puede recibir de todos. Los tipos mas comunes en Mexico son O positivo y A positivo; O negativo es raro.
- En emergencia sin tipificar se usa O negativo, por eso su inventario es critico y se agota rapido.
- En Mexico la NOM-253-SSA1-2012 regula la disposicion de sangre humana; cada unidad se rastrea desde el donante hasta el receptor, y se prueba contra infecciones antes de liberarla.
- Los inventarios se consumen con picos irregulares: accidentes, cirugias, eventos masivos.

## El problema
Controlar el inventario de unidades por tipo, componente, lote y caducidad, asignar la mas conveniente respetando compatibilidad y FEFO, reservar para cirugias programadas, activar un protocolo de emergencia, alertar niveles criticos por tipo, y mantener la trazabilidad donante-unidad-receptor.

## Escenario a simular
- 8 tipos sanguineos, 3 componentes, 300 unidades en inventario.
- Accidente multiple que consume 20 unidades de O negativo en 1 hora.
- Refrigerador que falla y compromete un lote.

## Casos dificiles
- Sustituir un tipo agotado por uno compatible.
- Unidad reservada que no se uso: ¿cuando se libera?
- Retirar de inmediato una unidad de un donante con prueba positiva tardia.

## Preguntas guia
1. ¿Cual es la politica cuando el tipo exacto se acabo?
2. ¿Como garantizas que una unidad vencida jamas sea asignada?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
