# #3 — Riego por zonas: el problema

## Contexto
La agricultura consume cerca del 70 % del agua dulce extraida en el mundo y alrededor del 75 % en Mexico, y aun asi gran parte se pierde: riego por gravedad ~40-50 % de eficiencia, aspersion ~70-80 %, goteo ~85-95 %. Baja California depende del Rio Colorado y de acuiferos en declive; un riego mal programado es dinero y agua tirados.

## Datos del mundo real
- **Demanda del cultivo:** ETc = ETo × Kc. La evapotranspiracion de referencia (ETo) en la region varia de ~2 mm/dia en invierno a ~7-8 mm/dia en verano.
- **Hidraulica:** una bomba entrega un caudal y presion finitos. Abrir mas zonas de las que soporta la bomba baja la presion y todas riegan mal. Cerrar una valvula de golpe causa golpe de ariete que revienta tuberia.
- **Valvulas solenoide:** tipicamente 24 VAC; tardan segundos en abrir/cerrar y pueden atorarse por sedimento.
- **Tarifas electricas:** bombear en horario punta es mas caro; muchos agricultores riegan de noche.
- **Sensores:** humedad de suelo, caudalimetro (pulsos), presion de linea, pluviometro.

## El problema
Hay N zonas con necesidades distintas y una sola fuente de agua limitada. Cada zona debe recibir su dosis dentro de una ventana de tiempo, sin exceder la capacidad de la bomba, sin riegos simultaneos en conflicto y suspendiendo si llueve. Si una valvula no cierra o hay una fuga (caudal sin zona activa), el sistema debe detectarlo.

## Escenario a simular
- 12 zonas, una bomba que soporta 3 zonas simultaneas, ventana nocturna de 8 horas.
- Una zona con valvula atorada abierta; una fuga con caudal sin valvula abierta.
- Lluvia inesperada a mitad del programa.

## Casos dificiles
- El programa no cabe en la ventana: ¿que se sacrifica?
- Reinicio del controlador a mitad del turno.
- Reloj desajustado entre el controlador y el servidor.

## Preguntas guia
1. ¿Como modelas "una zona esta regando" de forma que sea imposible olvidarla abierta?
2. ¿Que invariantes nunca deben romperse (p. ej. maximo de zonas abiertas)?
3. ¿Como distingues falla de sensor de falla de valvula?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
