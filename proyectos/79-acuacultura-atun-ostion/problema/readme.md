# #79 — Acuacultura (atún, ostión): el problema

## Contexto
Frente a Ensenada se engorda atun aleta azul del Pacifico en jaulas flotantes que se exportan principalmente a Japon, y en la Bahia de San Quintin se cultiva ostion. Son granjas en el mar, caras y expuestas: una noche con poco oxigeno o una marea roja puede acabar con meses de trabajo.

## Datos del mundo real
- Los peces necesitan oxigeno disuelto: el atun suele requerir niveles altos, y por debajo de ~3-5 mg/L hay estres y mortalidad. El oxigeno cae de noche (la fotosintesis se detiene) y con aguas calidas y poco movimiento.
- El atun se engorda en jaulas circulares de decenas de metros de diametro, con miles de ejemplares, alimentado con sardina y macarela; la conversion alimenticia es muy alta (decenas de kg de pescado por kg ganado), por lo que alimentar bien o mal pesa en el costo.
- La temperatura optima ronda 16-20 °C; cambios fuera de ese rango alteran el apetito.
- Un ostion tarda ~12-18 meses en llegar a talla comercial y es muy sensible a la calidad del agua: la **marea roja** (floraciones de algas toxicas) obliga a suspender cosecha y venta.
- Los sensores en boyas miden temperatura, oxigeno, salinidad, clorofila, corrientes; el mar corroe y ensucia los sensores (bioincrustacion) y hay falta de energia y señal.
- Cada jaula tiene biomasa, lote, fecha de ingreso y plan de alimentacion.

## El problema
Monitorear las condiciones de cada jaula, decidir cuanto y cuando alimentar segun apetito, temperatura y oxigeno, detectar condiciones de riesgo (poco oxigeno, algas, tormenta) con anticipacion para activar aireacion o mover/ajustar operaciones, y registrar biomasa y alimento para controlar costos.

## Escenario a simular
- 8 jaulas de atun y 20 lineas de ostion, 6 boyas, lecturas cada 5 min.
- Caida de oxigeno nocturna a 3.5 mg/L en dos jaulas.
- Boya sin señal durante la noche.

## Casos dificiles
- Sensor cubierto de incrustaciones que deriva sin fallar.
- Decidir con datos de una boya que no representa a la jaula.
- Alimentar menos sin saber si el problema es apetito o la medicion.

## Preguntas guia
1. ¿Cuantas lecturas anormales justifican una accion costosa?
2. ¿Como representas una decision que depende del tiempo (noche) y de la tendencia?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
