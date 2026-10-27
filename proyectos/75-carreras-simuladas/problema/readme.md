# #75 — Carreras simuladas: el problema

## Contexto
Una carrera simulada es un juego de apuestas ficticias (con fichas virtuales, nunca dinero real) donde cada piloto es un agente con habilidad, estado y suerte, y los espectadores ven la competencia desarrollarse en vivo. Se inspira en la Formula 1 y en carreras reales para dar realismo a los numeros.

## Datos del mundo real
- Una parrilla de F1 tiene 20 autos; una vuelta dura ~70-100 s; una carrera de ~300 km, 50-70 vueltas, ~1.5-2 horas. Los tiempos se miden en milesimas.
- Una parada en pits dura aproximadamente 2-3 s de servicio; perdida total en pits de ~20-25 s con entrada y salida. El **safety car** neutraliza la carrera y comprime al grupo.
- La estrategia incluye desgaste de llantas (que reduce el rendimiento de forma progresiva), combustible y clima.
- En apuestas, los **momios** se derivan de la probabilidad estimada; en apuestas **parimutuel** el pago se calcula repartiendo el total apostado entre los ganadores, descontando una comision de la casa.
- Un sistema justo debe ser **reproducible**: con la misma semilla aleatoria la carrera debe dar el mismo resultado para depurar y auditar.
- Eventos tipicos: adelantamiento, error, falla mecanica, choque, bandera amarilla, lluvia.

## El problema
Simular una carrera con cada piloto como proceso independiente que reacciona a eventos, mantener un orden y tiempos consistentes, difundir el estado a los espectadores, recibir apuestas ficticias hasta antes de la salida, y calcular pagos exactos al terminar, con reglas claras para empates y carreras suspendidas.

## Escenario a simular
- 20 pilotos, 50 vueltas, 1,000 espectadores y 500 apuestas.
- Un safety car en la vuelta 20 y 3 paradas simultaneas.
- Un piloto cuyo proceso falla a mitad de carrera.

## Casos dificiles
- Fotofinish: dos pilotos con el mismo tiempo.
- Apuesta recibida en el segundo de la salida.
- Carrera cancelada: reembolso.

## Preguntas guia
1. ¿Como haces que la simulacion avance en tiempo y se pueda reproducir?
2. ¿Que pasa con las apuestas si cae el proceso de un piloto?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
