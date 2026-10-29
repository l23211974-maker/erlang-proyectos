-module(p29_vehiculo).
-behaviour(gen_server).

%% Un gen_server por unidad fisica: guarda pos y solo sabe dos cosas,
%% moverse cuando el reloj emite un tick y reportar GPS al despachador.
%% No sabe nada de entregas: las cargas las deriva el despachador de las filas
%% de entrega (si el proceso muere y el supervisor lo relanza, no hay estado
%% de carga que reconstruir, solo pos de partida).

-export([start_link/1, averiar/1, estado/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

%% Movimiento en rejilla 10x10 (la ciudad simulada); 4 pasos posibles por tick.
-define(LADO_REJILLA, 10).

start_link(Id) ->
  gen_server:start_link({local, nombre(Id)}, ?MODULE, Id, []).

%% el nombre local permite matar la unidad de forma explicita en la prueba de caos
nombre(Id) ->
  list_to_atom("p29_vehiculo_" ++ integer_to_list(Id)).

averiar(Id) ->
  exit(whereis(nombre(Id)), averia).

estado(Id) ->
  gen_server:call(nombre(Id), estado).

init(Id) ->
  case whereis(p29_reloj) of
    undefined -> ok;  %% en tests el reloj puede no existir; el despachador impulsa manual
    _ -> gen_server:call(p29_reloj, {subscribe, self()})
  end,
  Capacidad = application:get_env(p29_flotilla_de_reparto, capacidad_kg, 2500),
  p29_datos:vehiculo_upsert(#{id => Id, pos => {0, 0}, estado => en_ruta,
                               %% undefined = nunca reporto: el watchdog no
                               %% debe juzgar a una unidad que apenas arranca
                               ultimo_reporte => undefined, capacidad => Capacidad,
                               pid => self()}),
  {ok, #{id => Id}}.

handle_call(estado, _From, State) ->
  {reply, p29_datos:vehiculo(maps:get(id, State)), State};
handle_call(pos, _From, State) ->
  {reply, maps:get(pos, p29_datos:vehiculo(maps:get(id, State)), {0, 0}), State};
handle_call(desconocido, _From, State) ->
  {reply, {error, desconocido}, State}.

handle_cast(_Msg, State) ->
  {noreply, State}.

handle_info({p29_tick, N}, State = #{id := Id}) ->
  Fila = p29_datos:vehiculo(Id),
  Pos = mover(maps:get(pos, Fila, {0, 0}), N),
  p29_datos:vehiculo_actualizar(Id, #{pos => Pos}),
  p29_despachador:reportar_gps(Id, Pos, N, self()),
  {noreply, State};
handle_info(_Msg, State) ->
  {noreply, State}.

%% movimiento determinista por tick: la misma secuencia de ticks produce la
%% misma traza (reproducible en la demo y en las capturas)
mover({X, Y}, N) ->
  case N rem 4 of
    0 -> {paso(X + 1), Y};
    1 -> {X, paso(Y + 1)};
    2 -> {paso(X - 1), Y};
    3 -> {X, paso(Y - 1)}
  end.

%% mantiene la pos dentro de la rejilla incluso con decrementos negativos
paso(V) -> (V + ?LADO_REJILLA) rem ?LADO_REJILLA.
