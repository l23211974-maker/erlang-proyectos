# #62 — Billetera virtual: el problema

## Contexto
Una billetera virtual guarda saldos y mueve dinero entre personas. Aqui un error no es un bug: es dinero perdido o creado de la nada. En Mexico los pagos digitales crecen con SPEI (opera las 24 horas, todos los dias), CoDi y DiMo del Banco de Mexico, y las fintech estan reguladas por la Ley Fintech.

## Datos del mundo real
- El **doble gasto** ocurre cuando dos operaciones leen el mismo saldo y ambas lo gastan. Con 100 pesos de saldo, dos transferencias de 80 pesos simultaneas no pueden ambas tener exito.
- Las apps moviles reintentan: el mismo "enviar 200 pesos" puede llegar 2-3 veces por mala señal. Se resuelve con **claves de idempotencia** unicas por operacion.
- La contabilidad usa **partida doble**: toda transferencia es un debito y un credito por el mismo monto, y la suma de todo el sistema siempre es cero. Nunca se usan numeros decimales flotantes para dinero; se usan enteros (centavos).
- Un saldo no es un numero que se sobreescribe: es la suma de movimientos inmutables.
- Los limites regulatorios y antifraude (monto diario, nivel de cuenta, verificacion de identidad) son parte del negocio.
- Una transferencia a un banco externo puede quedar *pendiente* y despues confirmarse o devolverse.

## El problema
Mover dinero entre cuentas de forma que nunca se cree ni se pierda ni se gaste dos veces, aun con operaciones simultaneas, reintentos, caidas del sistema a mitad de una transferencia y fallos de un banco externo; y poder reconstruir y auditar cualquier saldo.

## Escenario a simular
- 10,000 cuentas, 50 transferencias por segundo, 5 % con reintento.
- 100 operaciones simultaneas contra una misma cuenta con saldo insuficiente.
- Caida del sistema justo entre el debito y el credito.

## Casos dificiles
- Transferencia a un banco externo que tarda minutos y falla.
- Reversos y contracargos.
- Conciliacion: demostrar que la suma de saldos coincide con los movimientos.

## Preguntas guia
1. ¿Que invariantes nunca pueden romperse y como lo garantizas tras una caida?
2. ¿Como reconoces un reintento legitimo de una operacion nueva?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
