# #15 — Cluster de 2-3 nodos: el problema

## Contexto
Una sola maquina es un punto unico de falla. Erlang trae distribucion nativa (nodos que se hablan por mensajes), pero conectar nodos no resuelve la consistencia: la red se parte, los relojes difieren y los nodos mueren. Aqui se enfrenta el teorema CAP en la vida real, con 2 o 3 Raspberry Pi/VMs.

## Datos del mundo real
- Los nodos Erlang se descubren con `epmd` (puerto 4369) y comparten una cookie; por omision verifican que el otro este vivo con latidos cada ~60 s (`net_ticktime`), asi que detectar una caida puede tardar decenas de segundos.
- En una particion de red, ambos lados siguen vivos y creen ser los unicos: *split brain*.
- Con 2 nodos no hay mayoria posible; con 3 se tolera la caida de 1 (quorum = 2).
- Una red local suele tener latencia < 1 ms, pero un WiFi saturado o un enlace entre ciudades puede ser 50-200 ms con perdidas.
- Replicar datos implica escoger entre consistencia (rechazar escrituras en la particion minoritaria) y disponibilidad (aceptarlas y reconciliar despues).

## El problema
Hacer que un servicio sencillo (por ejemplo un contador o un registro de sesiones compartido) sobreviva a la caida de un nodo y a una particion de red, sin perder datos confirmados ni quedar con dos "verdades" divergentes. Los nodos deben unirse y salir sin intervencion manual.

## Escenario a simular
- 3 nodos; se mata uno; se desconecta otro de la red; se reconecta.
- Escrituras concurrentes del mismo dato en lados distintos de una particion.
- Un nodo con reloj adelantado 5 segundos.

## Casos dificiles
- Distinguir "nodo muerto" de "nodo lento".
- Reconciliar datos al sanar la particion.
- Un nodo que regresa con estado viejo.

## Preguntas guia
1. ¿Prefieres perder disponibilidad o consistencia, y por que en *este* servicio?
2. ¿Quien decide quien manda cuando hay desacuerdo?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
