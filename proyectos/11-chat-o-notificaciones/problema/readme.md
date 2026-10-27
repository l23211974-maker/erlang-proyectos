# #11 — Chat o notificaciones: el problema

## Contexto
Erlang gano fama mundial por WhatsApp: en 2012 reportaron mas de 2 millones de conexiones TCP en un solo servidor, y la app supera los 2,000 millones de usuarios. Un chat parece simple (mandar texto) pero esconde problemas dificiles de entrega, orden y presencia.

## Datos del mundo real
- Los usuarios esperan latencia de entrega en linea de decenas a pocos cientos de milisegundos.
- Un telefono pierde conexion con frecuencia (tuneles, cambio WiFi↔celular); las conexiones quedan "medio abiertas" y TCP puede tardar minutos en notarlo. Se usan *heartbeats* de ~30-60 s.
- Usuarios en grupos grandes: un mensaje a un grupo de 256 personas genera 256 entregas.
- Las palomitas de WhatsApp: enviado, entregado, leido → el cliente espera confirmaciones.
- Las notificaciones push (FCM/APNs) se usan cuando el usuario esta desconectado; no son confiables ni inmediatas.

## El problema
Entregar mensajes entre usuarios y grupos con: entrega garantizada (no perderlos aunque el destinatario este desconectado), orden dentro de una conversacion, confirmaciones de entrega y lectura, indicador de presencia ("en linea", "escribiendo") sin saturar la red, y soporte de miles de conexiones simultaneas en una maquina pequeña.

## Escenario a simular
- 5,000 conexiones simultaneas, 50 grupos de hasta 200 miembros.
- 20 % de usuarios cambian de red cada pocos minutos.
- Un usuario vuelve tras 6 horas offline con 300 mensajes pendientes.

## Casos dificiles
- Mensaje enviado dos veces por un reintento: ¿lo muestras duplicado?
- Dos mensajes concurrentes en un grupo: ¿que orden ven todos?
- Un cliente lento que no consume lo que le envias.

## Preguntas guia
1. ¿Que significa "entregado" y quien lo confirma?
2. ¿Que haces con la memoria cuando un cliente no lee su socket?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
