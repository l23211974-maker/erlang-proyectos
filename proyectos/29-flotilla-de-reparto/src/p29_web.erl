-module(p29_web).
-behaviour(gen_server).

%% HTTP de la UI: levanta el listener cowboy en web_port (8080 default) y
%% mantiene el router. Va al FINAL de p29_sup (rest_for_one): depende de
%% datos, reloj, despachador y el broadcaster; si algo de eso cae, la web se
%% re-arranca con el resto en bloque. Las rutas estaticas salen de priv/static.

-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2]).

-define(APP, p29_flotilla_de_reparto).
-define(LISTENER, p29_web_http).

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% criba: el ref puede quedar vivo si una corrida anterior no pudo terminate;
%% si no existe, stop_listener falla y lo ignoramos
listeners_defensivo() ->
  try cowboy:stop_listener(?LISTENER)
  catch
    _:_ -> ok
  end,
  ok.

init([]) ->
  %% para que terminate/2 corra al recibir el shutdown del supervisor y
  %% librarnos del listener: sin esto un reinicio del arbol deja el puerto
  %% colgado y el siguiente arranque muere de {error, already_started}
  process_flag(trap_exit, true),
  Puerto = application:get_env(?APP, web_port, 8080),
  %% defensivo: si un arranque anterior dejo el ref vivo (crash sin terminate),
  %% tumbarlo antes de subir el nuevo listener
  listeners_defensivo(),
  %% idempotente: en la app completa ya esta corriendo; en los escenarios de
  %% test (start_link directo del supervisor, sin application:start) levanta
  %% ranch/cowboy antes del listener
  {ok, _} = application:ensure_all_started(cowboy),
  case cowboy:start_clear(?LISTENER, [{port, Puerto}],
                          #{env => #{dispatch => cowboy_router:compile(rutas())}}) of
    {ok, _Pid} ->
      logger:info("web #29 escuchando en el puerto ~p (/, /api/*, /eventos, /metrics)",
                  [Puerto], #{dominio => flotilla}),
      {ok, #{puerto => Puerto}};
    {error, Motivo} ->
      %% el puerto ocupado es un error de despliegue, no un fallo del dominio:
      %% fallar aqui reinicia el arbol completo (rest_for_one), correcto.
      {stop, Motivo}
  end.

rutas() ->
  %% formato de dispatch cowboy: [{Host, [Ruta...]}]; un host, rutas propias
  [{'_', [
   {"/", cowboy_static, {priv_file, ?APP, "static/index.html"}},
   {"/index.html", cowboy_static, {priv_file, ?APP, "static/index.html"}},
   {"/unidad.html", cowboy_static, {priv_file, ?APP, "static/unidad.html"}},
   {"/historial.html", cowboy_static, {priv_file, ?APP, "static/historial.html"}},
   {"/app.css", cowboy_static, {priv_file, ?APP, "static/app.css"}},
   {"/app.js", cowboy_static, {priv_file, ?APP, "static/app.js"}},
   {"/api/entregas", p29_api, entregas},
   {"/api/vehiculos", p29_api, vehiculos},
   {"/api/estado", p29_api, estado},
   {"/api/averiar", p29_api, averiar},
   {"/api/urgente", p29_api, urgente},
   {"/eventos", p29_sse, []},
   {"/metrics", p29_metrics, []}
  ]}].

handle_call(desconocido, _From, State) ->
  {reply, {error, desconocido}, State}.

handle_cast(_Msg, State) ->
  {noreply, State}.

handle_info(_Msg, State) ->
  {noreply, State}.

%% el listener vive en ranch_sup (no hay hijo del arbol): si este supervisor
%% cae o se detiene, hay que tumbarlo a mano o el siguiente arranque choca con
%% {error, {already_started, p29_web_http}}
terminate(_Razon, _Estado) ->
  try cowboy:stop_listener(?LISTENER) of
    ok -> ok
  catch
    _:_ -> ok
  end.
