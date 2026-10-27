# #14 — Acortador de URLs: el problema

## Contexto
Servicios como Bitly o los enlaces cortos de redes sociales convierten una URL larga en una de ~7 caracteres. Parece trivial pero tiene el patron clasico de "muchas lecturas, pocas escrituras" y problemas de abuso.

## Datos del mundo real
- Un identificador de 7 caracteres en base62 (a-z, A-Z, 0-9) admite 62^7 ≈ 3.5 billones de combinaciones.
- La relacion lectura:escritura suele ser de 100:1 o mas; un enlace viral recibe miles de visitas por segundo.
- Una redireccion `301` la cachea el navegador (no se cuentan visitas posteriores); una `302` no.
- Los acortadores son usados para phishing y malware: hay que poder desactivar enlaces y validar destinos.
- Los identificadores secuenciales son faciles de enumerar; los aleatorios pueden colisionar (paradoja del cumpleaños: con 3.5 billones de espacio, las colisiones aparecen tras ~2 millones de ids aleatorios).
- Cada redireccion debe responder en pocas decenas de milisegundos.

## El problema
Generar identificadores unicos y cortos sin coordinarse en cada escritura, redirigir muy rapido, contar visitas (con referente, pais, fecha) sin frenar la redireccion, permitir enlaces personalizados y con expiracion, y poder bloquear un enlace malicioso de inmediato.

## Escenario a simular
- 1 millon de enlaces, 500 redirecciones/s sostenidas, rafaga de 5,000/s a un solo enlace.
- Alta de enlaces concurrente con alias personalizado repetido.
- Enlace reportado como phishing que debe dejar de funcionar de inmediato.

## Casos dificiles
- Dos usuarios piden el mismo alias personalizado al mismo tiempo.
- Contador de visitas que no debe perder ni duplicar mucho bajo carga.
- Que pasa con la cache cuando un enlace se bloquea.

## Preguntas guia
1. ¿Que operaciones estan en el camino critico de la redireccion y cuales no?
2. ¿Como generas ids unicos sin un cuello de botella?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
