# #74 — Radio o streaming: el problema

## Contexto
Una radio en linea o un "jukebox" colaborativo (la comunidad vota que suena despues) parece sencillo hasta que hay cientos de oyentes recibiendo el mismo audio al mismo tiempo, una cola de canciones que cambia por votos, y reglas de licencias y de convivencia.

## Datos del mundo real
- Un stream de audio de 128 kbps consume 16 KB/s: una hora son ~58 MB por oyente. Con 500 oyentes, son ~29 GB por hora de transferencia de salida.
- Los formatos de difusion usan segmentos de 2-10 segundos (HLS/DASH) o flujo continuo (Icecast/Shoutcast); los oyentes escuchan con unos segundos de retraso respecto al servidor y entre ellos.
- Se difunde musica con licencia: en Mexico las sociedades de gestion colectiva (como SACM) cobran derechos de ejecucion publica; por eso muchas radios en linea usan musica libre (Creative Commons).
- En una lista colaborativa, el votante tiene incentivos para trampear (cuentas multiples) y puede saturar a la cola con votos; hace falta limitar y ponderar.
- El flujo debe continuar sin silencios entre canciones aunque la cola este vacia o falle un archivo.
- Un oyente nuevo debe entrar "en vivo" en el segundo exacto en que va la emision.

## El problema
Mantener una cola de reproduccion dinamica donde los usuarios proponen y votan canciones, decidir la siguiente de forma justa y resistente a abusos, transmitir el audio de manera continua a muchos oyentes sincronizados, y mostrar en tiempo real lo que suena, lo que sigue y los votos.

## Escenario a simular
- 500 oyentes, 80 votantes activos, 200 canciones en catalogo.
- 100 votos en 10 segundos para la misma cancion desde 3 cuentas.
- Archivo corrupto a mitad de una cancion.

## Casos dificiles
- Votos que llegan justo cuando termina la cancion.
- Oyente con mala red que se queda atras y reconecta.
- Cola vacia: ¿que suena?

## Preguntas guia
1. ¿Como mantienes a todos escuchando lo mismo en el mismo momento?
2. ¿Que haces para que el voto de alguien con cinco cuentas no valga cinco veces?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
