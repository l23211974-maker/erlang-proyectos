# #31 — Control de pista y rampa: el problema

## Contexto
Una pista es el recurso mas escaso de un aeropuerto: en TIJ hay una sola, y cada despegue y aterrizaje ocupa un tiempo durante el que nadie mas puede usarla. En la rampa (plataforma) se coordinan muchos servicios alrededor de cada avion: pasarelas, combustible, equipaje, limpieza, catering, remolque. Si uno se atrasa, el vuelo sale tarde.

## Datos del mundo real
- Un movimiento en pista ocupa de 1 a 2 minutos; entre una aeronave y otra se exigen separaciones por estela turbulenta (mas tiempo si una pesada precede a una ligera) y por seguridad.
- Las aeronaves en aproximacion tienen prioridad sobre las que esperan salir; emergencias medicas o de combustible pasan a todos.
- Una salida normal: pushback, arranque de motores, rodaje (5-15 min en aeropuertos concurridos), despegue.
- Existe el concepto A-CDM (toma de decisiones colaborativa en aeropuerto), con hitos como hora objetivo de fin de rotacion (TOBT) y hora objetivo de autorizacion de arranque (TSAT).
- Los equipos de rampa (tractores, unidades de energia, camiones de combustible) son pocos y se comparten entre puertas.

## El problema
Secuenciar aterrizajes y despegues en la pista unica respetando separaciones y prioridades, y coordinar los servicios de rampa para que cada avion tenga lo que necesita a tiempo, reorganizando la secuencia cuando llega una emergencia, una demora o un cambio de pista.

## Escenario a simular
- 40 movimientos en 2 horas, mezcla de tamaños de aeronave.
- Una emergencia que exige prioridad inmediata.
- Un tractor de remolque disponible para 3 aviones que lo necesitan simultaneamente.

## Casos dificiles
- Reordenar la secuencia sin violar separaciones.
- Un servicio de rampa retrasado que retrasa la salida y todo lo que sigue.
- Recurso compartido pedido por dos puertas.

## Preguntas guia
1. ¿Que invariantes nunca pueden violarse aunque la secuencia cambie?
2. ¿Como se decide entre minimizar demoras totales o proteger a un vuelo critico?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
