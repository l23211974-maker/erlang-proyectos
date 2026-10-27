# #24 — Cruce CBX / puente peatonal: el problema

## Contexto
Cross Border Xpress (CBX), inaugurado en diciembre de 2015, es un puente peatonal cerrado de unos 390 metros que conecta el Aeropuerto de Tijuana con una terminal en Otay Mesa, San Diego. Permite a pasajeros con boleto de avion abordar o llegar sin cruzar por las garitas terrestres, y ha movido millones de personas. Es una frontera internacional con revision migratoria en cada sentido.

## Datos del mundo real
- Solo pueden usarlo personas con un pase de abordar o itinerario aereo vigente; se compra un boleto del cruce.
- El flujo es muy irregular: sube en las horas previas a salidas de vuelos y despues de llegadas. Los picos coinciden con bloques de vuelos.
- Cada persona pasa por modulos: venta/validacion, revision migratoria (CBP o INM), a veces inspeccion aduanera. Cada modulo tiene un numero limitado de ventanillas con tiempo de servicio variable, de 1 a 5 minutos por persona.
- La capacidad del puente es finita y hay limite de personas por hora por modulo.
- Los tiempos de espera publicados se miden como espera estimada, y las personas deciden si cruzar segun ese numero.

## El problema
Modelar el flujo de personas por varios modulos en serie, cada uno con su cola, ventanillas y tiempo de servicio, calcular la espera estimada actual y futura, y decidir cuantas ventanillas abrir en cada modulo para no formar una fila que desborde el puente. El sistema debe reaccionar al horario de vuelos (la demanda es previsible).

## Escenario a simular
- 3 modulos en serie con 2-6 ventanillas c/u, llegada de 600 personas/hora en pico.
- Un vuelo que llega con 180 pasajeros al mismo tiempo.
- Una ventanilla que se cierra sin aviso.

## Casos dificiles
- Un modulo lento forma cola que llena al anterior (propagacion hacia atras).
- Estimar la espera con pocos datos recientes.
- Prioridades: tripulaciones, personas con discapacidad, adultos mayores.

## Preguntas guia
1. ¿Que informacion necesitas para estimar la espera de la persona que llega ahora?
2. ¿Cuando conviene abrir otra ventanilla?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
