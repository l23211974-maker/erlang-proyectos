# #68 — Alarmas de domicilio: el problema

## Contexto
Una central de monitoreo vigila miles de casas y negocios. Cuando se activa una alarma, hay que decidir en segundos si es un robo real o una falsa alarma, y si se manda patrulla. Un exceso de falsos positivos agota a la policia y al cliente; un falso negativo es un robo no atendido.

## Datos del mundo real
- Se estima que entre 90 % y 98 % de las activaciones de alarma que se reportan a la policia resultan ser falsas (mascotas, puertas mal cerradas, errores del usuario, fallas del equipo); muchas ciudades multan las falsas alarmas repetidas.
- Los paneles reportan a la central con protocolos estandar (por ejemplo Contact ID de SIA), con codigos de evento y zona, por linea telefonica, internet o celular.
- Tecnicas de verificacion: llamada al usuario con contraseña ("palabra clave de coaccion" por si esta bajo amenaza), **verificacion cruzada** (dos zonas distintas en pocos minutos), video, audio.
- El panel manda tambien eventos de salud: **latido** periodico (supervision cada 24 h o menos), falla de bateria, corte de energia, corte de comunicacion. Si el latido no llega, puede ser un sabotaje.
- Hay un retardo de entrada de 30-60 s para que el usuario desarme antes de que suene.
- Cada alarma tiene un protocolo propio de contactos y escalamiento por cliente.

## El problema
Recibir eventos de miles de paneles, distinguir entre señal de robo, señal tecnica y falsa alarma, aplicar un protocolo de verificacion y escalamiento por cliente (llamar, esperar, reintentar, despachar), controlar a los operadores, y detectar paneles que dejaron de reportar.

## Escenario a simular
- 5,000 paneles, 800 eventos por hora, 3 operadores.
- Ola de tormenta que causa 400 eventos de corte de energia en 20 min.
- Un panel que no manda su latido en 26 horas.

## Casos dificiles
- Dos zonas activadas por la misma causa.
- Operador que no atiende una alarma critica a tiempo.
- Cliente que cancela por palabra clave despues de que ya se despacho.

## Preguntas guia
1. ¿Que evidencia eleva una alarma de "sospecha" a "despacho"?
2. ¿Que pasa si falla el sistema de monitoreo mismo?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
