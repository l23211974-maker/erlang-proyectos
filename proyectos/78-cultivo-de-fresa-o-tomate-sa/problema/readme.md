# #78 — Cultivo de fresa o tomate (San Quintín): el problema

## Contexto
El Valle de San Quintin, en Baja California, es una de las regiones agricolas de exportacion mas importantes del pais, en especial de fresa, zarzamora, frambuesa y tomate hacia EE. UU. Decenas de miles de jornaleros trabajan en las cosechas. La fruta fresca es muy perecedera y debe enfriarse rapidamente despues del corte.

## Datos del mundo real
- La fresa y otras berries requieren **preenfriamiento** a ~1-4 °C en pocas horas despues de la cosecha; cada hora de demora reduce la vida de anaquel.
- El rendimiento en fresa bien manejada puede ser de decenas de toneladas por hectarea al año; la cosecha es manual y repetida cada pocos dias por surco.
- A los jornaleros se les suele pagar a destajo (por caja o por kilo cosechado) o por jornada; el registro exacto es clave para pagar justo y evitar conflictos laborales.
- Una **cuadrilla** tiene un mayordomo y 15-40 jornaleros asignados a lotes y surcos; el rendimiento por persona varia ampliamente.
- Los compradores exigen **trazabilidad**: de cada caja debe saberse lote, surco, fecha, cuadrilla y condiciones de cosecha (certificaciones tipo GlobalG.A.P. y requisitos de FSMA de EE. UU.). Si hay un brote de contaminacion, se retira el lote exacto y no todo el producto.
- La conectividad en el campo es limitada, y la captura se hace en papel o en dispositivos simples.

## El problema
Registrar quien cosecha que, donde y cuando (cajas por jornalero, por lote, por hora), mantener la trazabilidad hasta la caja y el camion, calcular produccion y pago de las cuadrillas, vigilar los tiempos entre cosecha y enfriamiento, y consolidar la informacion de muchos puntos de captura que operan intermitentemente.

## Escenario a simular
- 10 lotes, 12 cuadrillas de 30 personas, 5,000 cajas por jornada.
- Un lote bajo sospecha de contaminacion que debe rastrearse.
- Una cuadrilla cuyos registros llegan tres horas despues por falta de señal.

## Casos dificiles
- Misma caja capturada dos veces.
- Cajas de distintos lotes mezcladas en una tarima.
- Tiempo entre corte y enfriamiento fuera de limite.

## Preguntas guia
1. ¿Cual es la unidad minima de trazabilidad y como se mantiene al agrupar?
2. ¿Como validas un registro capturado tarde y sin conexion?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
