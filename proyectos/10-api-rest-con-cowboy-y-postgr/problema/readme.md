# #10 — API REST con cowboy y PostgreSQL: el problema

## Contexto
La mayoria de los sistemas reales terminan siendo una API HTTP sobre una base de datos relacional. Es tambien donde mas fallan: conexiones agotadas, consultas lentas, reintentos del cliente que duplican datos, y despliegues que tiran peticiones en vuelo. Elige un dominio concreto y acotado (por ejemplo, catalogo de productos y pedidos de una tienda local, o inventario de una papeleria escolar).

## Datos del mundo real
- PostgreSQL trae `max_connections = 100` por omision y cada conexion consume memoria (del orden de varios MB); abrir una conexion por peticion no escala. Una regla comun para dimensionar pools es del orden de `nucleos × 2 + discos`.
- Objetivo de latencia comun para una API interactiva: p95 < 200-300 ms y p99 < 1 s. El humano percibe como "lento" arriba de ~1 s.
- Los clientes moviles reintentan peticiones en redes inestables: el mismo `POST` puede llegar 2-3 veces.
- Una consulta sin indice sobre 1 millon de filas puede pasar de milisegundos a segundos.
- En el CM5 hay 4 nucleos y ~5.5 GB para la aplicacion; PostgreSQL comparte esos recursos.

## El problema
Exponer operaciones CRUD y consultas de un dominio real asegurando consistencia (un pedido no vende mas de lo que hay en inventario), tolerando clientes que reintentan, protegiendo la base de datos de un exceso de trafico y devolviendo errores claros. Debe seguir sirviendo lo que pueda si la base de datos se cae un momento.

## Escenario a simular
- 200 usuarios concurrentes, 80 % lecturas / 20 % escrituras.
- Dos clientes compran la ultima unidad al mismo tiempo.
- La base de datos se reinicia durante 20 segundos.

## Casos dificiles
- Paginacion consistente mientras se insertan filas.
- Migraciones de esquema sin detener el servicio.
- Respuestas lentas de la base que acumulan peticiones en espera.

## Preguntas guia
1. ¿Que operaciones deben ser idempotentes y como se reconoce un reintento?
2. ¿Cuantas conexiones necesitas realmente y que haces cuando se agotan?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
