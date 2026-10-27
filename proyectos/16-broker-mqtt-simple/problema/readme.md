# #16 — Broker MQTT simple: el problema

## Contexto
MQTT (estandar OASIS, v3.1.1 y 5.0) es el protocolo de mensajeria dominante en IoT: sensores en el campo, medidores, vehiculos. Los brokers como EMQX, escritos en Erlang, manejan millones de conexiones. Tu broker es la pieza central de los demas proyectos de sensores.

## Datos del mundo real
- Puerto 1883 (texto) y 8883 (TLS). Cabecera fija minima de 2 bytes: ideal para enlaces celulares o LoRa lentos.
- **Temas jerarquicos** (`finca/parcela1/hilera3/humedad`) con comodines: `+` un nivel, `#` todos los niveles restantes.
- **QoS:** 0 (a lo mas una vez), 1 (al menos una, con ACK `PUBACK`), 2 (exactamente una, con 4 mensajes).
- **Sesiones persistentes:** un cliente desconectado recibe luego los mensajes QoS 1/2 que se perdio.
- **Retained:** el broker guarda el ultimo valor de un tema para quien se suscriba despues.
- **Last Will:** mensaje que el broker publica si el cliente muere sin despedirse. **Keep-alive:** si el cliente no manda nada en 1.5× el intervalo, se le desconecta.
- Dispositivos IoT tienen redes malas y reconectan sin parar.

## El problema
Implementar un broker que acepte conexiones, procese los paquetes del protocolo, enrute mensajes de publicadores a suscriptores segun comodines, cumpla las garantias de QoS 0 y 1, maneje sesiones, retained y Last Will, y siga estable con miles de clientes, incluyendo clientes lentos o maliciosos.

## Escenario a simular
- 3,000 clientes, 10,000 mensajes/s, 5 % reconectando constantemente.
- Un suscriptor lento que no lee su socket.
- Cliente que publica en `#` con 100 suscripciones comodin.

## Casos dificiles
- Como hacer el *match* de comodines eficientemente con miles de suscripciones.
- Mensajes QoS 1 pendientes al reiniciar el broker.
- Paquetes mal formados o a medio llegar (TCP es un flujo, no mensajes).

## Preguntas guia
1. ¿Que protege al broker de un cliente que no lee sus mensajes?
2. ¿Que se guarda en disco y que solo en memoria?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
