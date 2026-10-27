# #20 — Release y despliegue: el problema

## Contexto
Un sistema que solo corre en la laptop de quien lo programo no existe. Llevar una aplicacion Erlang del Mac del estudiante a un Raspberry Pi CM5 (aarch64, Debian 13, OTP 27.3.4.19) implica construir un *release* autonomo, instalarlo, arrancarlo como servicio, actualizarlo y poder volver atras.

## Datos del mundo real
- El desarrollo es en macOS (posiblemente x86_64 o arm64), el destino es Linux aarch64: un binario nativo no se copia entre ellos. Debe coincidir la version de OTP, o se debe incluir el runtime (`include_erts`).
- `systemd` envia SIGTERM al detener y espera `TimeoutStopSec` (90 s por omision) antes de matar con SIGKILL; el apagado ordenado importa para no perder peticiones.
- Las actualizaciones en caliente (`appup`/`relup`) son posibles en Erlang pero fragiles; la practica comun es reemplazo con reinicio rapido.
- La configuracion cambia por ambiente: puertos, URL de base de datos, cookie de distribucion; los secretos no van en el repositorio.
- Un despliegue fallido a las 2 a. m. debe poder revertirse en minutos, no horas.

## El problema
Definir como se empaqueta, instala, configura, arranca, monitorea y actualiza la aplicacion en el CM5 de forma repetible, de modo que cualquier integrante del equipo pueda hacerlo igual, sabiendo que version corre en cada momento y regresando a la anterior si algo sale mal.

## Escenario a simular
- Entrega de la version 1.0, luego 1.1 con una migracion de datos, luego un rollback.
- Corte de luz durante la actualizacion.
- La app no arranca por una variable de entorno faltante.

## Casos dificiles
- Versiones distintas entre desarrollo y destino.
- Dos aplicaciones que quieren el mismo puerto.
- Actualizar sin perder conexiones de usuarios activos.

## Preguntas guia
1. ¿Como sabes, desde fuera, que version exacta corre?
2. ¿Que haces cuando el arranque falla: quien te avisa y como regresas?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
