# #4 — Apiario o ganado: el problema

## Contexto
Mexico esta entre los 10 principales productores de miel del mundo (del orden de 55-65 mil toneladas al año) y es potencia ganadera: millones de cabezas de bovino en pastoreo extensivo. En ambos casos los animales estan dispersos, lejos y sin supervision humana continua. Elige uno de los dos escenarios (o ambos).

## Datos del mundo real — Apiario
- Una colmena sana mantiene la zona de cria a ~34-35 °C casi todo el año; una caida sostenida indica perdida de la reina o colonia debilitada.
- En flujo de nectar una colmena puede ganar 1-5 kg/dia; un peso que cae sin causa indica enjambrazon, robo o saqueo.
- Plagas: Varroa destructor (principal causa de perdida de colonias), pequeño escarabajo de la colmena. Robo de colmenas es un delito comun en zonas rurales.
- Balanzas con celdas de carga, sensores de temperatura/humedad interna y acelerometro; solo hay cobertura LoRa o celular intermitente.

## Datos del mundo real — Ganado
- Un rancho extensivo puede tener cientos de cabezas en cientos de hectareas; un animal enfermo se detecta tarde.
- Fiebre bovina o estro se detectan por temperatura corporal y actividad (acelerometro en collar o arete). Una vaca en celo tiene ventana fertil de ~12-18 h.
- Collares GPS reportan cada 5-30 min para ahorrar bateria; fuera de cobertura acumulan lecturas.
- El abigeato (robo de ganado) es un problema real en el pais.

## El problema
Recibir telemetria irregular de decenas a cientos de activos moviles o remotos, saber el estado de cada uno y avisar a tiempo cuando algo se sale de lo normal (peso, temperatura, movimiento, salida de un cerco virtual), sin inundar al dueño de falsas alarmas.

## Escenario a simular
- 60 colmenas en 6 apiarios, o 300 cabezas en 4 potreros.
- Dispositivos que reportan en rafagas tras perder cobertura horas.
- Un animal/colmena que sale de la geocerca de madrugada.

## Casos dificiles
- Lecturas que llegan fuera de orden con marcas de tiempo del dispositivo.
- Bateria baja que distorsiona lecturas.
- Distinguir cambio normal (dia/noche, flujo de nectar) de anomalia.

## Preguntas guia
1. ¿Como representas un activo "perdido" frente a uno solo "sin cobertura"?
2. ¿Que alertas son urgentes y cuales pueden resumirse?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
