# #13 — Rate limiter / caché: el problema

## Contexto
Toda API publica necesita protegerse: la API de GitHub permite 5,000 peticiones por hora a usuarios autenticados (60 sin autenticar); muchas APIs devuelven `429 Too Many Requests` con `Retry-After`. Y casi todo sistema lento se arregla con una cache... hasta que la cache causa nuevos problemas.

## Datos del mundo real
- Algoritmos de limite conocidos: *token bucket*, *leaky bucket*, ventana fija, ventana deslizante. Cada uno trata distinto las rafagas.
- Una ventana fija de 1 minuto permite hasta 2× el limite alrededor del cambio de ventana.
- Una cache tipica tiene tasa de aciertos de 80-95 %; subir de 90 % a 99 % reduce 10× las lecturas al origen.
- *Cache stampede*: cuando expira una llave muy popular, miles de peticiones golpean el origen a la vez.
- Politicas de expulsion: LRU, LFU, TTL. La memoria disponible es finita (~5.5 GB en el CM5).
- Datos obsoletos: algunos son tolerables (conteo de visitas) y otros no (saldo de cuenta).

## El problema
Construir un servicio que (a) decida en microsegundos si una peticion de un cliente excede su cuota y (b) mantenga una cache con limite de memoria, expiracion y proteccion contra avalanchas, ambos usados por miles de procesos concurrentes sin convertirse en cuello de botella.

## Escenario a simular
- 50,000 claves de cliente, 20,000 peticiones/s en pico.
- Un cliente abusivo mandando 100× su limite; una llave popular que expira.
- Presupuesto de memoria fijo de 500 MB para la cache.

## Casos dificiles
- Un solo proceso que serializa todo: ¿cuanto aguanta?
- Limites distintos por plan de cliente cambiados en caliente.
- Dos nodos del cluster: ¿el limite es global o por nodo?

## Preguntas guia
1. ¿Que estructura permite lecturas concurrentes sin pasar por un solo proceso?
2. ¿Cuanta imprecision en el conteo aceptas a cambio de velocidad?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
