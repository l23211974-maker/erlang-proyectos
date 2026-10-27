# #19 — Observabilidad: el problema

## Contexto
Cuando un sistema falla a las 3 de la mañana, lo unico que importa es si puedes ver por que. Esta practica agrupa tres señales: metricas (numeros agregados), logs (eventos) y trazas (recorrido de una peticion). Aqui construyes la observabilidad de la flota de aplicaciones Erlang que corre en el Raspberry Pi CM5.

## Datos del mundo real
- Prometheus consulta (*scrape*) cada 15 s por omision; las metricas se exponen en `/metrics` en formato de texto.
- Las latencias se reportan en percentiles (p50, p95, p99): el promedio esconde los casos malos.
- **Cardinalidad:** cada combinacion de etiquetas es una serie nueva. Una etiqueta con el id de usuario puede explotar a millones de series y tumbar el monitor.
- **SLO:** una disponibilidad de 99.9 % permite ~43 minutos de caida al mes; 99.99 % solo ~4.3 minutos.
- Fatiga de alertas: si todo alerta, nada se atiende. Una buena alerta es accionable y avisa por sintomas del usuario.
- En la VM Erlang hay señales propias: cola de mensajes de procesos, uso de memoria por tipo, reducciones, planificadores, conteo de procesos, puertos. `recon` sirve para diagnostico en caliente.

## El problema
Instrumentar una aplicacion Erlang para exponer metricas utiles de negocio y de la VM, definir cuales revelan un problema antes de que lo note el usuario, correlacionar logs con peticiones, y detectar fugas de memoria, procesos con cola creciente y cuellos de botella, usando el menor recurso posible (el monitor no debe consumir mas que lo que vigila).

## Escenario a simular
- 5 aplicaciones, cada una con 20-50 metricas, scrape cada 15 s.
- Una fuga de memoria lenta; un proceso cuya cola de mensajes crece sin parar.
- Un pico de latencia p99 sin que el promedio cambie.

## Casos dificiles
- Metricas con alta cardinalidad introducidas por accidente.
- Diagnosticar en produccion sin pausar el nodo.
- Medir sin alterar lo medido.

## Preguntas guia
1. ¿Que 5 numeros te dicen si la aplicacion esta sana?
2. ¿Que no debes medir por su costo?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
