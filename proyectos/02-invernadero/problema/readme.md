# #2 — Invernadero: el problema

## Contexto
La agricultura protegida (invernaderos y malla sombra) en Mexico ocupa decenas de miles de hectareas y crece cada año; el tomate, pepino y pimiento son los cultivos principales de exportacion. En Baja California y Sinaloa un invernadero tecnificado puede producir 10-20 veces mas por hectarea que campo abierto, pero depende de mantener un microclima.

## Datos del mundo real
- **Tomate:** rango optimo ~21-26 °C de dia y 13-16 °C de noche; arriba de ~32 °C hay aborto de flores; debajo de ~10 °C se detiene el crecimiento.
- **Humedad relativa:** ideal 60-80 %. Arriba de ~90 % por varias horas favorece botrytis y cenicilla. Se controla con DPV (deficit de presion de vapor), con objetivo cercano a 0.8-1.2 kPa.
- **CO2:** atmosfera ~420 ppm; enriquecer a 800-1000 ppm de dia con ventanas cerradas aumenta rendimiento, pero abrir la ventana tira el CO2 al exterior.
- **Actuadores:** ventanas cenitales y laterales, mallas de sombra/termicas, extractores, nebulizacion, calefaccion, fertirriego (CE y pH de la solucion nutritiva; CE tipica 2-3.5 dS/m, pH 5.5-6.5).
- Un sensor de ambiente reporta cada 10-60 s; el clima puede cambiar en minutos (nube, viento, sol).

## El problema
Varios objetivos compiten: bajar temperatura abre ventanas (se pierde CO2 y entra humedad o plaga), subir humedad con nebulizacion baja la temperatura pero aumenta riesgo de hongos, cerrar para calentar sube la humedad. Los actuadores no deben oscilar (abrir/cerrar cada 10 s los destruye) ni operar al mismo tiempo en conflicto. El sistema debe mantener el clima aun si un sensor falla.

## Escenario a simular
- 4 naves de ~1 ha, cada una con 6 sensores de clima, 4 actuadores y 2 lineas de fertirriego.
- Dia soleado con viento repentino que obliga a cerrar ventanas laterales.
- Falla de un sensor de temperatura durante una ola de calor.

## Casos dificiles
- Dos zonas de la misma nave piden acciones contrarias.
- Un actuador no responde o se queda atorado.
- Perdida de energia y retorno: ¿en que estado queda cada actuador?

## Preguntas guia
1. ¿Que prioridad tienen las metas climaticas entre si y quien arbitra?
2. ¿Cuanto tiempo minimo debe pasar entre dos cambios de un actuador?
3. ¿Que hace el sistema cuando no confia en ninguna lectura?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
