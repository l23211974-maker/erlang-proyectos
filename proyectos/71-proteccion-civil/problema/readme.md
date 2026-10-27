# #71 — Protección civil: el problema

## Contexto
Baja California enfrenta lluvias torrenciales que causan inundaciones y deslaves en colonias de laderas, incendios por Santa Ana y sismos. Cuando se abre un albergue, hay que saber en minutos cuantas personas estan, que necesitan y que falta. Esto es logistica de crisis, con informacion incompleta y gente cansada.

## Datos del mundo real
- Estandares humanitarios (Manual Esfera) recomiendan por persona: ~3.5 m² de espacio techado, un minimo de 15 litros de agua al dia y un sanitario por cada 20 personas.
- Un albergue improvisado en una escuela o gimnasio puede abrir con 50-300 personas en pocas horas; los registros se hacen en papel y la informacion se pierde.
- Necesidades tipicas: colchonetas, cobijas, agua, alimentos, medicinas, productos de higiene, kits para bebes, atencion medica y psicologica. Algunas personas tienen necesidades especiales (adultos mayores, embarazadas, medicacion continua).
- Las familias se separan; localizar a una persona es una de las demandas mas frecuentes.
- Las donaciones llegan de forma desordenada: toneladas de ropa que no se necesita y escasez de lo esencial.
- Las comunicaciones fallan: no hay luz ni internet; se necesita operar sin conexion y sincronizar despues.

## El problema
Abrir y operar albergues durante un evento: registrar personas y familias, controlar entradas y salidas, llevar inventario de insumos y su consumo, calcular cuanto durara cada cosa, pedir reabasto a donde corresponda, y consolidar la informacion de todos los albergues para quien coordina la respuesta.

## Escenario a simular
- 5 albergues, 1,200 personas en 72 h, 40 tipos de insumos.
- Un albergue que recibe a 200 personas de repente.
- Un albergue sin conexion durante 6 horas que luego se sincroniza.

## Casos dificiles
- La misma persona registrada en dos albergues.
- Transferir insumos de un albergue a otro.
- Calcular dias de agua o alimento restantes con consumo cambiante.

## Preguntas guia
1. ¿Que informacion debe estar disponible aunque no haya internet?
2. ¿Como reconcilias dos versiones del mismo albergue al reconectar?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
