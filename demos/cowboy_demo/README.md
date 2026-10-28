# cowboy_demo

Demo didáctica de la exposición *Erlang/OTP en el mundo real*. Un sensor simulado
genera lecturas y Cowboy las sirve por REST, SSE y WebSocket, junto con una página
HTML/CSS/JS plana.

## Árbol de supervisión

```
cowboy_demo_sup (rest_for_one)
├── pg                   grupo `readings` (pub/sub local, viene con OTP)
├── cowboy_demo_store    gen_server dueño de la tabla ETS (últimas 120 lecturas)
├── cowboy_demo_sim      gen_server: caminata aleatoria de temp/hum cada 1 s
└── cowboy_demo_http     listener Ranch/Cowboy (ranch:child_spec)
```

`rest_for_one`: cada hijo depende de los anteriores, así que si cae `pg` o el store
se reinician simulador y listener.

## Flujo de datos

`sim` → `store` (ETS) → mensaje `{reading, R}` a todos los procesos del grupo `pg`
→ cada handler SSE/WS lo empuja a su cliente. Cada conexión es un proceso, y si un
handler falla solo muere esa conexión.

## Endpoints

| Ruta | Tipo | Descripción |
|---|---|---|
| `/` | estático | Página con tarjetas, gráfica y selector SSE/WebSocket |
| `/api/health` | GET JSON | Estado, versión de OTP y schedulers |
| `/api/readings` | GET JSON | Historial en ETS (405 con otros métodos) |
| `/sse` | SSE | Una lectura por evento, solo servidor → cliente |
| `/ws` | WebSocket | Lecturas al cliente; el cliente puede enviar `ping` y recibe `pong` |

## Uso

```bash
rebar3 compile
rebar3 eunit
rebar3 shell          # http://localhost:8080
rebar3 release       # _build/prod/rel/cowboy_demo
```

Pruebas rápidas:

```bash
curl localhost:8080/api/health
curl -N localhost:8080/sse
```

Diagnóstico con recon desde `rebar3 shell`: `recon:proc_count(message_queue_len, 5).`

## Notas

- Usa el módulo `json` incluido desde OTP 27, sin dependencias de JSON.
- Dependencias: solo `cowboy` 2.12.0 y `recon` 2.5.6 (stack del curso).
- La UI es una página de ejemplo y no se diseñó en Stitch; un proyecto de estudiante
  sí debe hacerlo (ver `AGENTS.md`).
- `vm.args` usa una cookie de ejemplo; cámbiala fuera del repo en producción.
