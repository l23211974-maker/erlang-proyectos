-module(p29_datos).
-behaviour(gen_server).

%% Vista de consulta del dominio. La fuente de verdad vive en los procesos
%% (un gen_statem por entrega, un gen_server por vehiculo); estas tablas ETS son
%% solo la vista de lectura que consumen la API, /metrics y el dashboard.
%% Escribir la fila de una entrega fuera de su propio proceso rompe el codigo
%% de asignacion segura: solo p29_entrega actualiza su fila.

-export([start_link/0, ensure/0,
         entrega_upsert/1, entrega/1, entrega_actualizar/2, entregas_todas/0,
         entregas_de/1, entregas_por_estado/1, conteo_entregas/0, proximo_id/0,
         vehiculo_upsert/1, vehiculo/1, vehiculo_actualizar/2, vehiculos_todas/0,
         conteo_vehiculos/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

-define(TAB_ENTREGAS, p29_entregas).
-define(TAB_VEHICULOS, p29_vehiculos).

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% idempotente: permite al despachador funcionar en tests sin el arbol completo
ensure() ->
  case whereis(?MODULE) of
    undefined -> {error, no_iniciado};
    _ ->
      asegurar_tablas(),
      ok
  end.

asegurar_tablas() ->
  case ets:info(?TAB_ENTREGAS) of
    undefined ->
      ets:new(?TAB_ENTREGAS, [named_table, public, set, {read_concurrency, true}]);
    _ ->
      ok
  end,
  case ets:info(?TAB_VEHICULOS) of
    undefined ->
      ets:new(?TAB_VEHICULOS, [named_table, public, set, {read_concurrency, true}]);
    _ ->
      ok
  end.

init([]) ->
  asegurar_tablas(),
  {ok, #{}}.

%% ---- entregas ----------------------------------------------------------------

%% Campos de la fila de entrega:
%%   id (entero), peso (kg), colonia, ventana {Desde, Hasta} (ticks), urgente (bool),
%%   estado (pendiente | en_ruta | entregada | fallida), vehiculo (entero | undefined),
%%   pid (pid del gen_statem), tick_asignado, tick_entregado, retraso (ticks), motivo.
entrega_upsert(Mapa) when is_map(Mapa) ->
  ets:insert(?TAB_ENTREGAS, {maps:get(id, Mapa), Mapa}).

entrega(Id) ->
  case ets:lookup(?TAB_ENTREGAS, Id) of
    [{_, Mapa}] -> Mapa;
    [] -> undefined
  end.

entrega_actualizar(Id, Cambios) when is_map(Cambios) ->
  case entrega(Id) of
    undefined -> {error, no_existe};
    Mapa -> entrega_upsert(maps:merge(Mapa, Cambios))
  end.

entregas_todas() ->
  [Mapa || {_, Mapa} <- ets:tab2list(?TAB_ENTREGAS)].

entregas_de(Vid) ->
  [M || M <- entregas_todas(), maps:get(vehiculo, M, undefined) =:= Vid].

entregas_por_estado(Estado) ->
  [M || M <- entregas_todas(), maps:get(estado, M) =:= Estado].

conteo_entregas() ->
  lists:foldl(
    fun(Mapa, Acc) ->
        maps:update_with(maps:get(estado, Mapa), fun(N) -> N + 1 end, 1, Acc)
    end, #{}, entregas_todas()).

%% ids crecientes: reutilizar el ultimo id colisionaria con la fila de una
%% entrega viva o con su historial entregado/fallido
proximo_id() ->
  case entregas_todas() of
    [] -> 1;
    Filas -> 1 + lists:max([maps:get(id, Mapa) || Mapa <- Filas])
  end.

%% ---- vehiculos ---------------------------------------------------------------

%% Campos de la fila de vehiculo:
%%   id (entero), pos {X, Y}, estado (en_ruta | sin_senal | averiado),
%%   ultimo_reporte (tick), capacidad (kg), pid.
vehiculo_upsert(Mapa) when is_map(Mapa) ->
  ets:insert(?TAB_VEHICULOS, {maps:get(id, Mapa), Mapa}).

vehiculo(Id) ->
  case ets:lookup(?TAB_VEHICULOS, Id) of
    [{_, Mapa}] -> Mapa;
    [] -> undefined
  end.

vehiculo_actualizar(Id, Cambios) when is_map(Cambios) ->
  case vehiculo(Id) of
    undefined -> {error, no_existe};
    Mapa -> vehiculo_upsert(maps:merge(Mapa, Cambios))
  end.

vehiculos_todas() ->
  [Mapa || {_, Mapa} <- ets:tab2list(?TAB_VEHICULOS)].

conteo_vehiculos() ->
  lists:foldl(
    fun(Mapa, Acc) ->
        maps:update_with(maps:get(estado, Mapa), fun(N) -> N + 1 end, 1, Acc)
    end, #{}, vehiculos_todas()).

%% ---- callbacks del gen_server (solo posee las tablas, no lleva logica) --------

handle_call(desconocido, _From, State) ->
  {reply, {error, desconocido}, State}.
handle_cast(_Msg, State) ->
  {noreply, State}.
handle_info(_Msg, State) ->
  {noreply, State}.
