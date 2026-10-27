# #38 — Andon digital: el problema

## Contexto
Andon es una herramienta del sistema de produccion de Toyota: cualquier operador puede jalar un cordon o presionar un boton para pedir ayuda cuando detecta un problema, incluso deteniendo la linea. La idea es resolver el problema en el momento, no al final. En las maquiladoras de Tijuana se usan tableros luminosos y botones en cada estacion.

## Datos del mundo real
- Codigo de colores habitual: verde (normal), amarillo (se necesita ayuda/atencion), rojo (linea detenida), a veces azul (falta material) o blanco (calidad).
- **Escalamiento por tiempo:** si nadie atiende la llamada, sube de nivel: lider de grupo (en minutos), supervisor, gerente de area, gerente de planta. Tiempos tipicos de respuesta objetivo: 1-2 min para el lider y 5-10 min para el supervisor.
- El costo de una linea detenida puede ser de cientos o miles de dolares por minuto; por eso cada llamada y su respuesta se miden.
- Se miden tiempo de respuesta, tiempo de solucion, frecuencia por estacion y causa, para alimentar mejora continua.
- Una estacion con muchas llamadas falsas hace que la gente deje de atenderlas.

## El problema
Recibir llamadas de ayuda de muchas estaciones, mostrar su estado en tiempo real, notificar a la persona responsable, escalar automaticamente al siguiente nivel si el tiempo de respuesta se vence, registrar quien atendio y cuando se resolvio, y producir indicadores para el equipo de mejora.

## Escenario a simular
- 40 estaciones, 3 lideres, 1 supervisor, 1 gerente por area.
- Llamada que nadie atiende durante 6 minutos; ocho llamadas simultaneas.
- Un lider que esta ocupado con otra llamada.

## Casos dificiles
- Temporizadores de escalamiento que deben sobrevivir un reinicio.
- Cancelacion de una llamada justo cuando se escala.
- Cambio de turno con llamadas abiertas.

## Preguntas guia
1. ¿Que pasa con una llamada si el sistema se reinicia a mitad de escalamiento?
2. ¿Quien puede cerrar una llamada y con que evidencia?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
