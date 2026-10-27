# #34 — Almacén / inventario: el problema

## Contexto
Una maquiladora o un centro de distribucion mueve miles de numeros de parte. Si el sistema dice que hay 40 piezas y en el estante hay 12, la linea se detiene o se promete lo que no hay. Estudios de la industria suelen reportar que la exactitud de inventario en muchos almacenes ronda 60-70 % sin control estricto.

## Datos del mundo real
- Politicas de salida: **FIFO** (primero en entrar, primero en salir) y **FEFO** (primero en caducar, primero en salir) para perecederos, quimicos y medicamentos.
- **Punto de reorden** = demanda diaria × tiempo de entrega + inventario de seguridad. Ej.: 50 piezas/dia × 6 dias + 100 = 400 piezas.
- Clasificacion **ABC**: ~20 % de los articulos suele representar ~80 % del valor; se cuentan con distinta frecuencia (conteos ciclicos).
- La trazabilidad por lote/serie es obligatoria en sectores como medico y automotriz: ante un defecto, hay que saber a que clientes llego cada lote.
- Errores comunes: recibir contra una orden equivocada, surtir una cantidad distinta, mover sin registrar, mermas.
- Muchos operadores con escaner mueven mercancia al mismo tiempo sobre las mismas ubicaciones.

## El problema
Mantener un inventario confiable por ubicacion y lote ante movimientos concurrentes (entradas, salidas, traspasos, ajustes), impedir existencias negativas o reservar el mismo material dos veces, disparar alertas de minimo y conservar la historia completa de cada movimiento para auditoria y trazabilidad.

## Escenario a simular
- 5,000 numeros de parte, 8 operadores, 2,000 movimientos por turno.
- Dos pedidos que reservan las ultimas 30 piezas al mismo tiempo.
- Un lote que se declara defectuoso y hay que rastrear a donde fue.

## Casos dificiles
- Un ajuste de inventario despues de un conteo fisico.
- Movimiento capturado dos veces por reintento del escaner.
- Reconstruir cuanto habia en una fecha pasada.

## Preguntas guia
1. ¿El saldo es un dato guardado o se deriva de los movimientos?
2. ¿Como impides la sobre-reservacion sin bloquear a todos?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
