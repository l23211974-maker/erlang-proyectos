# Gemelo digital de la flotilla de reparto (#29)

Modelo lógico, en SWI-Prolog, de la flotilla que el proyecto #29 simula en Erlang/OTP.
Aquí no se simula nada: se declaran hechos (estado de unidades, entregas, tramos,
eventos) y reglas que responden, con explicación, las cinco situaciones de
[`PROBLEMA.md`](PROBLEMA.md). El servidor web y su interfaz solo consultan esas reglas.

```
gemelo/
├── hechos.pl               escenario: 4 unidades, 14 entregas, 8 puntos, eventos
├── reglas.pl               todas las reglas del dominio (nada de dominio fuera de aquí)
├── servidor.pl             library(http/…): JSON en /api/* + estáticos de web/
├── janus_bridge.pl         puente py_call/2 (Janus nativo o proceso Python + JSON)
├── integracion_janus.pl    lecturas simuladas y gráficas vía Python desde Prolog
├── janus_call.py           runner genérico para llamadas Python desde Prolog
├── janus_sim.py            lecturas simuladas y gráficas SVG (stdlib, sin deps)
├── tests/reglas_tests.pl   28 pruebas plunit (averia, urgente, silencio, llegada, fallida, contrato)
├── tests/extensiones_tests.pl 18 pruebas plunit de extensiones posibles
├── tests/janus_tests.pl    6 pruebas plunit de integración Janus/Python
├── web/                    interfaz de solo consulta (index.html, style.css, app.js)
├── PROBLEMA.md             enunciado de la extensión
└── CONTEXTO_AGENTES.md     restricciones de arquitectura y criterios de aceptación
```

## Cómo se corre

```powershell
# pruebas del modelo (28 casos; verde = exit 0)
swipl -q -g run_tests -t halt tests/reglas_tests.pl

# servidor + interfaz en http://127.0.0.1:8089/
swipl servidor.pl
$env:GEMELO_PORT = 8090; swipl servidor.pl    # otro puerto
swipl servidor.pl 8091                        # o como argumento
```

Requisitos: SWI-Prolog 9.0.4+ (probado en Linux aarch64 y Windows) y Python 3 (stdlib)
para la integración Janus. Se usan bibliotecas estándar: plunit, lists, heaps,
library(http/…), library(process), library(readutil). Janus se integra vía py_call/2
(nativo si library(janus) está disponible, o puente compatible janus_bridge.pl +
janus_call.py) para lecturas simuladas y gráficas SVG (janus_sim.py, sin dependencias externas).

## Supuestos (cifras propias de esta extensión)

Todo lo que sigue es **inventado para el escenario reducido** que autoriza
`PROBLEMA.md` («Supuestos de esta extensión»); no son datos de una empresa real.

| Supuesto | Valor | Dónde |
|---|---|---|
| Jornada | 08:00–14:00, en minutos desde las 08:00 (`jornada_inicio(0)`, `jornada_fin(360)`) | `hechos.pl` |
| Instante de consulta por omisión | `ahora(300)` = 13:00 | `hechos.pl` |
| Escala | 4 unidades, 14 entregas, 8 puntos, 14 tramos | `hechos.pl` |
| Capacidad | peso (kg) **y** volumen (unidades de bodega) por unidad; caber en una no implica caber en la otra | `unidad/3` |
| Tope de manejo | 480 min al volante | `max_manejo/1` |
| Silencio | 60 min sin lectura vuelven dudosa a la unidad | `umbral_silencio/1` |
| Parada | entre 2 y 5 min, como intervalo (no un número) | `rango(parada, 2, 5)` |
| Tramo lento | `c_centro–d_sur` pasa de 9 a 24 min a las 280 | `evento/4` |
| Pedido urgente | `ue1` en `f_oeste`, 25 kg / 2 u, ventana 300–360 | `urgente/4` |
| Reintento | `e8` puede reprogramarse a 330–420 | `reintento/3` |
| Escala de tiempo | el «ahora» es un hecho; ninguna regla llama a `get_time/1` ni a `random/1` | `reglas.pl` |

## Cifras del enunciado que verifiqué

Estas sí vienen del problema original y las comprobé en
[`../problema/readme.md`](../problema/readme.md) antes de citarlas (líneas 7–9 y 17–18):

- 15 unidades y 900 entregas en el día, con GPS simulado cada 10 s.
- Una unidad averiada a las 11 a. m. con 40 entregas pendientes.
- Cada parada toma de 2 a 5 minutos.
- La entrega fallida (cliente ausente, dirección mala) ronda 5–15 % del total.
- Un conductor pasa una hora sin señal y luego reporta todo junto.

En el gemelo se conservan las **proporciones** (una avería, un urgente, un silencio con
reporte en lote, una fallida de cada motivo, un tramo lento que comparten dos rutas), pero
no la escala: 4 unidades y 14 entregas en vez de 15 y 900.

## Las cinco situaciones y qué devuelve cada una

Los números que siguen están verificados ejecutando la API contra el escenario actual.

**1. La unidad averiada (u3, avería a las 180).** Sus entregas pendientes son
`e4, e7, e10, e12`. `decide_en/4` enumera **9 repartos válidos** que respetan peso,
volumen, ventanas, horas y la recogida del paquete en `c_centro`. Cada plan trae la
explicación por entrega (`cabe`, `desde`, `punto`, `ventana`, `minutos_de_viaje`) y la
lista `no_cambia` con las asignaciones ajenas que no se tocaron. Si no hay plan, el
diagnóstico distingue tres causas: `individual(...)` (una entrega que no cabe en ninguna
unidad, con los rechazos por unidad), `capacidad_conjunta(peso_excedido/volumen_excedido)`
y `ventanas_u_horas_en_conflicto`.

**2. El pedido urgente.** Para cada unidad se evalúan **todas** las inserciones en su ruta
y se informa el retraso por entrega y si rompe alguna ventana. La elegida es **u4**, no u1,
aunque u1 está más cerca de `f_oeste` (10 min en línea recta desde el almacén): u4 retrasa
solo 2 min a `e13`, mientras que u1 retrasaría 14 min a `e9` y u2 no tiene inserción
viable. La prioridad (menos entregas tardías → menos retraso total → menos distancia) se
declara una sola vez en `prioridad/3`.

**3. La unidad que se calló (u2, última lectura a las 180, reporte en lote a las 290).**
Cuatro veredictos distintos para las cuatro entregas de su ruta: `e5` **se_entrego** (la
entrega ocurrió a las 275 y se supo a las 290: se modela la hora del suceso y la de
recepción por separado con `recepcion/5`), `e3` y `e6` **no_se_entrego** (su ventana cerró
antes del último conocimiento), `e14` **no_se_sabe** (el reporte no la menciona). Además
señala que `e5` quedó **duplicada** por una decisión ya tomada: el despachador la pasó a
u1 a las 250.

**4. ¿Llega a su ventana?** Los tres veredictos aparecen en el escenario: `en_ventana`
(e1, e2 de u1; toda la ruta de u3; e8 de u4), `tarde` (e9 de u1, e3 y e6 de u2, e11 y e13
de u4) y `depende_de_paradas` (e14 de u2). Cada llegada sale de encadenar tramos, paradas
previas (con el intervalo 2–5) y el tramo lento; para u2 el conductor **no** alcanza sus
horas (`horas_restantes = 20`), y el tramo lento `c_centro–d_sur` (24 min) se atribuye a
u1 y u3 con la consulta inversa `unidad_usa_tramo/3`.

**5. La entrega fallida que sigue a bordo.** `e11` (dirección mala) es **no_ubicable**:
no hay punto al que ir. `e8` (cliente ausente) se puede **reintentar hoy con u1**, porque
u1 pasa por su punto dentro de la ventana nueva. El impacto se dice en las dos direcciones:
u4 tendría `libre(49-5)` si no contara el paquete y `libre(37-4)` contándolo.

**Qué falta.** `que_falta/2` responde la pregunta al revés: para el urgente devuelve las
unidades que lo tomarían sin romper nada (`u1`, `u4`); si ninguna pudiera, devuelve las
alternativas de decisión (`subir_capacidad`, `ampliar_ventanas`, `aceptar_un_retraso`).
Para el reparto de la avería dice `hay_plan`, porque existe.

## Cómo se modela el «no se sabe»

- Toda condición del dominio tiene tres resultados: `si`, `no`, `no_se_sabe`. No hay
  booleanos de dos valores escondidos.
- Los veredictos también son de tres valores: ventana (`en_ventana`, `depende_de_paradas`,
  `tarde`), silencio (`se_entrego`, `no_se_entrego`, `no_se_sabe`) y horas (`si`, `no`,
  `no_se_sabe`).
- Un hecho sabe **cuándo ocurrió** y **cuándo se supo**. `suceso/5` toma la hora de
  ocurrencia; `recepcion/5` permite que un reporte en lote traiga hechos viejos. Todas las
  consultas reciben `Ahora`, así que el mismo modelo responde antes y después del reporte
  sin cambiar una coma de las reglas.
- Lo dudoso nunca se convierte en hecho: `en_duda/2` no es `averiada/2`, y una unidad en
  duda no es candidata para absorber el urgente.

## API

El servidor sirve JSON bajo `/api/` y los estáticos de `web/`. La interfaz **solo** llama
a estos endpoints; no calcula capacidad, ventanas, prioridades ni veredictos.

| Endpoint | Qué devuelve |
|---|---|
| `GET /api/estado` | ahora, jornada, unidades (posición, capacidad, carga, libre, ruta, silencio, horas), puntos, tramos (base y observado), entregas (punto, ventana, estado, unidad, orden), situaciones deducidas |
| `GET /api/plan?entregas=e4,e7` | entregas, todos los planes válidos con su explicación, `no_cambia` y `sin_plan` (diagnóstico). Sin parámetro usa las pendientes de la unidad averiada |
| `GET /api/urgente` | pedido, candidatas con su evaluación, elegida, prioridad declarada y `que_falta` |
| `GET /api/silencio?unidad=u2` | `en_duda`, reporte, veredicto y evidencia por entrega, reasignadas y huérfanas |
| `GET /api/llegadas?unidad=u1` | llegada mínima/máxima y veredicto por parada, horas del conductor, tramos lentos con las unidades que los tocan |
| `GET /api/fallidas` | por fallida: motivo, destino (`no_ubicable`, `reintento_hoy(u)`, almacén), evidencia e impacto en la capacidad |
| `GET /api/que_falta?objetivo=urgente_sin_romper\|plan_averia` | la pregunta al revés: qué unidades o qué cambios harían falta |
| `GET /api/prioridad` | la prioridad declarada del urgente, en un solo lugar |

Una unidad que nunca estuvo en duda devuelve `en_duda: false` con listas vacías (no un
error), y un estático inexistente devuelve 404.

## Interfaz

Se diseñó a partir de la maqueta de Stitch del proyecto
([`../design/Plantilla Flotilla de Reparto/aeroterra_dispatch_telematics/DESIGN.md`](../design/Plantilla%20Flotilla%20de%20Reparto/aeroterra_dispatch_telematics/DESIGN.md)):
tema oscuro de telemetría, tarjetas con borde fino, acento turquesa para lo normal, ámbar
para lo dudoso y rojo para lo roto. Muestra el mapa con las unidades y sus rutas (el tramo
lento en rojo discontinuo), la tabla de entregas con su ventana y estado, la carga de cada
unidad en peso **y** volumen con barras, las unidades en duda por silencio, el tramo lento
con las rutas que toca, el plan con su explicación y a quién se le falla, y la respuesta a
«qué falta». En celular la rejilla pasa a una columna, el mapa a cuadrado y las tablas se
desplazan en horizontal.

`app.js` es la única hoja de hidratación y no contiene reglas: pinta lo que llega.

## Pruebas

`tests/reglas_tests.pl` tiene **28 casos** en seis bloques: `averia` (incluye «no hay plan»
y «no toca lo ajeno»), `urgente` (incluye «no elige la más cercana por serlo»),
`silencio` (los tres veredictos, el reporte que corrige el pasado y la duplicada),
`llegada` (los tres veredictos, horas y consulta inversa del tramo), `fallida` (no
ubicable, reintento, impacto en capacidad) y `contrato` (`decide/3`, `situacion/3` en
cualquier dirección y la verdad de tres valores). Todas pasan sin *choicepoints* abiertos.

```powershell
swipl -q -g run_tests -t halt tests/reglas_tests.pl   # exit 0
```

## Qué resolví en Erlang y qué en Prolog, y por qué

En **Erlang/OTP** está la flotilla viva: un proceso por unidad, un proceso por entrega y un
despachador que reacciona a eventos con reloj manual, supervisión, ETS como caché de
lectura y un release autocontenido para el Raspberry Pi. Ahí lo que importa es la
concurrencia y la tolerancia a fallos: que una unidad muerta se relance, que el reloj sea el
único dueño del tiempo y que el estado sobreviva a caídas parciales. En **Prolog** está el
modelo lógico de esa misma flotilla: hechos y reglas que responden *por qué* a una entrega
le toca tal unidad, si cabe en peso y volumen, si llega a su ventana, qué no se sabe y a
quién se le falla. Lo que en Erlang sería una cascada de `if` y contadores se convierte en
consultas sobre las mismas reglas, incluida la pregunta al revés («¿qué rutas tocan este
tramo?») y la enumeración de todos los repartos válidos. Cada cosa en su lugar: Erlang para
ejecutar la flotilla en tiempo real, Prolog para razonar sobre ella sin ambigüedad.

## Limitaciones conocidas

- `decide_en/4` enumera todas las soluciones, así que es exponencial: con las 4 entregas de
  la avería tarda milisegundos, pero no está pensado para 900 entregas. Para la escala de
  esta extensión (y para pedir *todos* los planes) es la herramienta correcta.
- El escenario es uno solo y vive en `hechos.pl`; cambiar el caso es editar hechos, no
  reescribir reglas.
- Janus/Python implementado: py_call/2 (nativo o puente compatible) llama a Python desde Prolog para generar lecturas simuladas (lecturas_simuladas_janus/4) y gráficas SVG (graficar_entregas_janus/1, graficar_llegadas_janus/2) vía /api/janus (ccion=ping|lecturas|resumen|graficar|graficar_llegadas). Las lecturas del escenario base siguen siendo hechos; Janus agrega lecturas simuladas y visualización bajo demanda.
- La interfaz no tiene autenticación ni escritura: es de solo consulta, por diseño.
