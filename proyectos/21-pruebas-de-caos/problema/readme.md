# #21 — Pruebas de caos: el problema

## Contexto
Los sistemas no fallan en el laboratorio, fallan en produccion y de formas que nadie imagino. Netflix creo Chaos Monkey (2011) para apagar servidores al azar en horas laborales y asi descubrir debilidades antes que sus clientes. Erlang parte de la misma filosofia ("let it crash"): el arbol de supervision promete recuperarse, pero esa promesa solo vale si se prueba.

## Datos del mundo real
- El 28 de febrero de 2017 un comando mal escrito durante un mantenimiento de Amazon S3 en us-east-1 tumbo muchos servicios de internet por unas 4 horas: una falla pequeña, un efecto dominó.
- Principios de la ingenieria del caos: definir un estado estable medible (peticiones/s, latencia p99, errores), plantear una hipotesis ("si muere el worker X, el servicio sigue"), inyectar la falla de forma controlada y comparar contra el estado estable.
- Fallas inyectables en un nodo Linux: matar procesos o el nodo (`exit/2`, `kill -9`), saturar CPU o memoria, llenar disco, añadir latencia y perdida de paquetes de red (`tc netem`), cortar un puerto.
- Las fallas reales son compuestas: un proceso reiniciandose en bucle (*restart intensity* excedida) puede escalar y tumbar al supervisor padre, y a toda la aplicacion.
- Jepsen demostro que muchas bases de datos prometian garantias que perdian bajo particiones de red.

## El problema
Disenar y ejecutar experimentos de falla controlada contra otro de los proyectos del curso (el equipo elige uno) para verificar con evidencia que su recuperacion es la que se dice, medir cuanto tarda en recuperarse y que se pierde, y descubrir lo que nadie habia previsto.

## Escenario a simular
- Matar procesos en distintos niveles del arbol (hoja, intermedio, raiz) bajo carga.
- Añadir 500 ms de latencia y 20 % de perdida a la conexion con la base de datos.
- Fallas en cascada: un proceso que muere cada 2 segundos.

## Casos dificiles
- Como definir "recuperado": ¿proceso vivo o servicio util?
- Que el experimento mismo no dañe datos reales.
- Estado en memoria que no sobrevive al reinicio.

## Preguntas guia
1. ¿Cual es tu hipotesis antes de cada falla y que numero la valida o la refuta?
2. ¿Cual es el radio de explosion maximo aceptable de un experimento?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
