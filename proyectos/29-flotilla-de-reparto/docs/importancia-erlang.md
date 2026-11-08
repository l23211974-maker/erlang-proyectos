# Importancia de Erlang en el proyecto 29 — Flotilla de reparto

> **Gist público:** [importancia-erlang.md](https://gist.github.com/l23211974-maker/7aa4a94d57b4eb7b17b89f21d18928cb)

> **Resumen rápido:** Erlang no es un detalle del lenguaje: es el núcleo del sistema. Permite que la aplicación maneje 15 unidades, 900 entregas, eventos GPS, reasignaciones, fallos, servidor HTTP y actualizaciones SSE como un conjunto de procesos aislados, supervisados y fáciles de mantener. La interfaz web es solo una vista; el trabajo real ocurre en la máquina virtual de Erlang/OTP.

## 1. ¿Qué es Erlang y por qué importa aquí?

Erlang es un lenguaje y, sobre todo, una **máquina virtual orientada a concurrencia, tolerancia a fallos y sistemas reactivos**. Su ecosistema más utilizado es **OTP**, que incluye bibliotecas como `gen_server`, `gen_statem`, supervisores y `cowboy`.

El comando `erl` es la consola de Erlang. No es la interfaz gráfica: es la entrada interactiva a la máquina virtual donde se ejecutan los módulos. Por ejemplo, `p29_simulador:demo().` se escribe en esa consola para iniciar la jornada simulada.

En este proyecto, la secuencia conceptual es:

```text
Navegador
   │
   │ HTTP / SSE
   ▼
cowboy (Erlang)
   │
   ├─ API: /api/entregas, /api/vehiculos, /api/estado
   ├─ SSE: /eventos
   └─ HTML/CSS/JS servido desde priv/static/
   │
   ▼
OTP: reloj, despachador, vehículos, entregas, broadcaster
   │
   ▼
Datos ETS consultables y reglas de dominio
```

La GUI es importante, pero **no contiene la lógica de la flotilla**. Si se cerrara el navegador, la jornada, los procesos y el estado seguirían existiendo en la máquina virtual de Erlang.

## 2. Erlang sostiene la estructura principal de la aplicación

El árbol de supervisión usa `rest_for_one` y este orden:

1. `p29_datos`: contiene tablas ETS de lectura.
2. `p29_reloj`: genera el tiempo simulado mediante ticks.
3. `p29_despachador`: asigna, reasigna y vigila la flota.
4. `p29_flota_sup`: administra un proceso por unidad.
5. `p29_entregas_sup`: administra un proceso por entrega.
6. `p29_broadcaster`: distribuye la instantánea en vivo a los navegadores.
7. `p29_web`: levanta cowboy y expone la interfaz y las APIs.

Este diseño hace que la web dependa del dominio, pero no al revés: un cambio de presentación no debería romper el despacho de entregas. Además, si un proceso intermedio cae, los componentes posteriores pueden reiniciarse sin dejar una interfaz visualmente activa sobre datos ya inválidos.

## 3. Concurrencia aislada: cada unidad y cada entrega son un proceso

Erlang permite crear procesos independientes sin complicar el código con hilos del sistema operativo ni variables compartidas. En la flotilla:

- Cada **vehículo** es un `gen_server` (`p29_vehiculo`).
- Cada **entrega** es un `gen_statem` (`p29_entrega`).

Esa separación tiene consecuencias concretas:

- Una unidad averiada no tumba el despachador.
- Una entrega inválida puede rechazarse en su propio estado sin corromper otras entregas.
- Las unidades pueden reportar GPS aunque otra unidad esté reasignando su carga.
- Los supervisores pueden relanzar la unidad caída sin reordenar todo el sistema.

Esto es clave para un sistema de flotilla: los estados ocurren simultáneamente y los errores son normales. Erlang modela esos eventos como procesos, monitores y mensajes, no como ramas de código difíciles de auditar.

## 4. Los `gen_statem` protegen la vida útil de cada entrega

Una entrega puede estar en:

- `pendiente`
- `en_ruta`
- `entregada`
- `fallida`

El estado correcto depende de las transiciones permitidas. Por ejemplo, no debe permitirse asignar una entrega sin haberla devuelto antes; tampoco debe poder entregarse dos veces.

`p29_entrega` resuelve esto delegando las reglas al propio `gen_statem`. Así el despachador coordina, pero **no redefine el ciclo de vida desde fuera**. `p29_despachador:invariantes/0` actúa como inspección final: verifica que no existan entregas huérfanas, duplicadas o asignadas a unidades muertas.

## 5. El reloj centraliza la simulación

El tiempo no depende de `timer:sleep/1` repartido en el dominio. Lo controla `p29_reloj`:

- Cada tick equivale a 10 segundos simulados de GPS.
- En la demo, el intervalo real es de 33 ms, por lo que un día de 6 horas se ejecuta en unos 72 segundos.
- Los vehículos, el despachador y el broadcaster reaccionan a los mismos eventos `{p29_tick, N}`.

La ventaja es reproductibilidad: la misma configuración produce la misma jornada y permite probar el sistema sin depender del tiempo real del hardware. La determinación se refuerza con `erlang:phash2/2`, en vez de usar aleatoriedad sin semilla en pesos, colonias y ventanas.

## 6. Erlang maneja datos y telemetría sin esperar al navegador

La aplicación conserva la información en tablas ETS:

- `p29_entregas`
- `p29_vehiculos`

Esas tablas son una capa de consulta, no una base de datos permanente. El proceso dueño de cada entrega o vehículo actualiza su fila; la API, las métricas y la interfaz leen el estado.

El proceso `p29_broadcaster` es el único suscriptor del reloj y envía una instantánea por tick a los navegadores conectados mediante SSE. Esto evita que cada conexión HTTP convierta cada tick en una petición separada y reduce la lógica duplicada.

La interfaz consume:

- `GET /api/estado`
- `GET /api/vehiculos`
- `GET /api/entregas`
- `GET /eventos` (SSE)
- `GET /metrics`

y modifica el dominio con:

- `POST /api/averiar`
- `POST /api/urgente`

Los handlers de cowboy no escriben directamente en ETS. Las acciones sensibles pasan por `p29_despachador`, respetando el principio de que cada proceso controla su propio estado.

## 7. Supervisión y recuperación ante fallos reales

El proyecto fue diseñado para escenarios de caos:

- **Avería explícita:** las entregas de la unidad vuelven a pendiente, el despachador las reasigna y el supervisor relanza la unidad vacía.
- **Crash no controlado:** el despachador detecta la muerte con monitores `DOWN`, no depende solo de mensajes de salida.
- **Pérdida de señal:** el watchdog detecta unidades que dejaron de reportar, devuelve su carga y reasigna.
- **Lotes GPS atrasados:** los reportes con un tick menor al último conocido se descartan; gana el más reciente.

Erlang facilita este comportamiento porque los procesos pueden monitorearse, reiniciarse y comunicarse mediante mensajes con origen y destino explícitos. El sistema no trata el fallo como una excepción excepcional: lo trata como un evento de diseño.

## 8. Erlang conecta backend, API, telemetría y presentación

La importancia de Erlang no se limita a “un lenguaje más rápido”. Es el componente que integra:

- Reglas de asignación greedy first-fit.
- Máquinas de estados para entregas.
- Supervisión de vehículos y entregas.
- Vigilancia de pérdidas de señal.
- Conversión del dominio a JSON.
- SSE para el mapa en vivo.
- HTTP con cowboy.
- Métricas Prometheus.
- Release y servicio `systemd` en Raspberry Pi.

El stack de presentación es independiente:

- HTML/CSS/JS plano en `priv/static/`.
- Tokens visuales derivados del diseño de Stitch.
- Sin frameworks de frontend ni paso de compilación web.

Esto deja una compartimentación clara: Erlang posee la lógica y la superficie de datos; el navegador únicamente presenta, filtra y envía comandos a la API.

## 9. Ventajas verificables del diseño elegido

| Necesidad | Solución en Erlang/OTP |
|---|---|
| Manejar muchas unidades y entregas a la vez | Procesos por vehículo y por entrega |
| Evitar corrupciones por estado compartido | Cada proceso es dueño de su estado |
| Modelar ciclos de vida estrictos | `gen_statem` por entrega |
| Reiniciar unidades tras un crash | Supervisores OTP |
| Escalar la experiencia del dominio sin VRP extremo | Asignación greedy first-fit |
| Detectar pérdidas de señal | Reloj, ticks y watchdog |
| Evitar estados imposibles | Invariantes y rechazos del statem |
| Consultar estado rápidamente | Tablas ETS |
| Actualizar la GUI sin polling HTTP | Broadcaster y SSE |
| Ejecutar pruebas reproducibles | Reloj manual, reloj automático y determinismo con `phash2` |
| Levantar HTTP en la misma aplicación | cowboy dentro de la supervisión |

## 10. Qué no hace Erlang dentro de este sistema

Erlang **no** controla directamente:

- La resolución de direcciones del navegador.
- Los cálculos visuales de diseño en CSS.
- La presentación de las tarjetas, filtros o la rejilla.
- El acceso físico a la Raspberry Pi o a la red Corellium.

Tampoco significa que cualquier parte del sistema sea automática: el operador debe ejecutar herramientas como `rebar3`, sincronizar el repositorio y reiniciar el servicio cuando se despliega un cambio nuevo. Erlang resuelve la lógica concurrente y la resiliencia, pero el despliegue sigue requiriendo disciplina operativa.

## 11. Por qué fue adecuado para este problema

La flotilla tiene simultáneamente:

1. **Estado complejo**: cada entrega cambia, cada vehículo se mueve.
2. **Fallos esperados**: averías, conexiones perdidas y lotes atrasados.
3. **Tiempo simulado**: el sistema debe ser reproducible y acelerar la jornada.
4. **Actualización en vivo**: la interfaz debe reflejar un mundo que cambia cada 33 ms.
5. **Reglas de negocio**: la asignación y la reasignación deben respetar capacidad, severidad y ventana.
6. **Recuperación**: relanzar unidades y reasignar carga sin reiniciar toda la aplicación.

Erlang/OTP encaja con esas exigencias porque combina procesos, mensajes, estados supervisados y protocolos de comunicación. No es suficiente con “leer y responder peticiones”: la aplicación se parece más a un sistema de control en tiempo real, y Erlang está pensado para ese tipo de problemas.

## 12. Mapa de conceptos clave

| Concepto | Para qué sirve en el proyecto |
|---|---|
| `erl` | Consola para ejecutar funciones Erlang, incluida la demo |
| `gen_server` | Proceso con estado y ciclo de vida para vehículo, datos, despachador |
| `gen_statem` | Ciclo de vida seguro de cada entrega |
| Supervisor | Mantiene procesos y los reinicia cuando fallan |
| Monitor | Detecta procesos caídos mediante `'DOWN'` |
| Mensajes | Comunicación explícita entre componentes |
| ETS | Tablas de lectura rápida para API e interfaz |
| Reloj | Fuente única de tiempo simulado |
| SSE | Actualización en vivo al navegador |
| cowboy | Servidor HTTP/API dentro del proceso web |
| Release | Paquete ejecutable completo para la Raspberry Pi |

## Conclusión

**Erlang es la columna vertebral de la flotilla.**

Sin Erlang:

- no habría procesos independientes para cada vehículo o entrega;
- la recuperación ante averías dependería de reinicios manuales;
- no existiría una fuente única y reproducible de tiempo;
- la interfaz en vivo dependería de actualizaciones manuales;
- las reglas de estado de cada entrega serían más difíciles de aislar y validar.

Con Erlang/OTP, el proyecto puede modelar la flota como lo que es: un sistema concurrente, reactivo y susceptible a fallos.
