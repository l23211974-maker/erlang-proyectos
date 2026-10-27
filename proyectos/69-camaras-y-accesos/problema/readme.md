# #69 — Cámaras y accesos: el problema

## Contexto
Una empresa o campus genera millones de eventos de seguridad: puertas abiertas, tarjetas leidas, movimiento detectado por camara, alarmas. Cuando ocurre un incidente, la pregunta es "¿que paso entre las 2:10 y las 2:25 en el edificio B?". Si no se puede buscar rapido, el registro no sirve. Este proyecto trabaja con la **bitacora de eventos**, no con el video.

## Datos del mundo real
- Un sistema de 100 puertas y 200 camaras con analitica puede generar de decenas a cientos de eventos por segundo en picos, y millones al dia.
- Una camara de 1080p H.264 produce unos 2-4 Mbps, es decir, 20-40 GB por dia por camara; por eso el video se guarda poco tiempo y los **eventos con marcas de tiempo** (metadatos) se conservan mas.
- Politicas tipicas de retencion: 30-90 dias de video y de 1 a varios años de bitacora; la Ley Federal de Proteccion de Datos Personales en Posesion de los Particulares exige tratar con cuidado los datos de personas.
- Para que la bitacora sirva como evidencia no debe poder alterarse: se encadenan los registros con hashes.
- Los relojes de los dispositivos se desajustan; sin sincronizacion NTP los eventos de dos camaras no se pueden ordenar bien.
- Las consultas mas comunes son por **rango de tiempo**, por dispositivo, por tipo y por persona.

## El problema
Ingerir un flujo continuo de eventos de muchos dispositivos, guardarlos sin perder ninguno aun en picos, permitir busquedas rapidas por rango de tiempo y filtros, aplicar retencion y borrado seguro, y demostrar que la bitacora no fue alterada.

## Escenario a simular
- 100 puertas y 200 camaras, 150 eventos/s promedio, picos de 2,000/s.
- Busqueda de todos los eventos de un edificio entre dos horas del mes pasado.
- Un dispositivo cuyo reloj tiene 4 minutos de atraso.

## Casos dificiles
- Eventos que llegan tarde con marca de tiempo antigua.
- Borrar lo vencido sin afectar las busquedas en curso.
- Reinicio con eventos aun en memoria.

## Preguntas guia
1. ¿Que significa que la bitacora "no perdio nada"?
2. ¿Como organizas los datos para que buscar un rango no recorra todo?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
