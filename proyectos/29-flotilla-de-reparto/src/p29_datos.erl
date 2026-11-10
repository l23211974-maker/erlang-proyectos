-module(p29_datos).
-behaviour(gen_server).

%% Vista de consulta del dominio AeroCargo. La fuente de verdad vive en los procesos
%% (un gen_statem por envio, un gen_server por aeronave); estas tablas ETS son
%% solo la vista de lectura que consumen la API, /metrics y el dashboard.
%% Escribir la fila de un envio fuera de su propio proceso rompe el codigo
%% de asignacion segura: solo p29_envio actualiza su fila.

-export([start_link/0, ensure/0,
         envio_upsert/1, envio/1, envio_actualizar/2, envios_todos/0,
         envios_de/1, envios_por_estado/1, conteo_envios/0, proximo_id/0,
         aeronave_upsert/1, aeronave/1, aeronave_actualizar/2, aeronaves_todas/0,
         conteo_aeronaves/0,
         waypoint_upsert/1, waypoint/1, waypoints_todos/0,
         ruta_upsert/1, ruta/1, rutas_todas/0,
         meteo_upsert/1, meteo_zona/1, meteo_todas/0,
         adsb_upsert/1, adsb_ultimo/1, adsb_todos/0,
         transbordo_upsert/1, transbordo/1, transbordos_todos/0,
         conteo_transbordos/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

%% Backward compatibility exports (deprecated, for tests transition)
-export([entrega_upsert/1, entrega/1, entrega_actualizar/2, entregas_todas/0,
         entregas_de/1, entregas_por_estado/1, conteo_entregas/0,
         vehiculo_upsert/1, vehiculo/1, vehiculo_actualizar/2, vehiculos_todas/0,
         conteo_vehiculos/0]).

-define(TAB_ENVIOS, p29_envios).
-define(TAB_AERONAVES, p29_aeronaves).
-define(TAB_WAYPOINTS, p29_waypoints).
-define(TAB_RUTAS, p29_rutas).
-define(TAB_METEO, p29_meteo).
-define(TAB_ADSB, p29_adsb).
-define(TAB_TRANSBORDOS, p29_transbordos).

%% Compat: old table names
-define(TAB_ENTREGAS, p29_entregas).
-define(TAB_VEHICULOS, p29_vehiculos).

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% Idempotente: permite al despachador funcionar en tests sin el arbol completo
ensure() ->
  case whereis(?MODULE) of
    undefined -> {error, no_iniciado};
    _ ->
      asegurar_tablas(),
      ok
  end.

asegurar_tablas() ->
  %% Envios (was entregas)
  case ets:info(?TAB_ENVIOS) of
    undefined ->
      ets:new(?TAB_ENVIOS, [named_table, public, set, {read_concurrency, true}]);
    _ -> ok
  end,
  %% Aeronaves (was vehiculos)
  case ets:info(?TAB_AERONAVES) of
    undefined ->
      ets:new(?TAB_AERONAVES, [named_table, public, set, {read_concurrency, true}]);
    _ -> ok
  end,
  %% Waypoints
  case ets:info(?TAB_WAYPOINTS) of
    undefined ->
      ets:new(?TAB_WAYPOINTS, [named_table, public, set, {read_concurrency, true}]);
    _ -> ok
  end,
  %% Rutas vectoriales
  case ets:info(?TAB_RUTAS) of
    undefined ->
      ets:new(?TAB_RUTAS, [named_table, public, set, {read_concurrency, true}]);
    _ -> ok
  end,
  %% Meteo
  case ets:info(?TAB_METEO) of
    undefined ->
      ets:new(?TAB_METEO, [named_table, public, set, {read_concurrency, true}]);
    _ -> ok
  end,
  %% ADS-B reports
  case ets:info(?TAB_ADSB) of
    undefined ->
      ets:new(?TAB_ADSB, [named_table, public, set, {read_concurrency, true}]);
    _ -> ok
  end,
  %% Transbordos
  case ets:info(?TAB_TRANSBORDOS) of
    undefined ->
      ets:new(?TAB_TRANSBORDOS, [named_table, public, set, {read_concurrency, true}]);
    _ -> ok
  end,
  %% Compat: old tables (kept for tests transition)
  case ets:info(?TAB_ENTREGAS) of
    undefined ->
      ets:new(?TAB_ENTREGAS, [named_table, public, set, {read_concurrency, true}]);
    _ -> ok
  end,
  case ets:info(?TAB_VEHICULOS) of
    undefined ->
      ets:new(?TAB_VEHICULOS, [named_table, public, set, {read_concurrency, true}]);
    _ -> ok
  end.

init([]) ->
  asegurar_tablas(),
  {ok, #{}}.

%% ---- envios (was entregas) -----------------------------------------------------

%% Campos de la fila de envio:
%%   id (entero), peso_kg, tipo_carga (general | perecedero | peligroso | AOG),
%%   origen_iata, destino_iata, ventana {Desde, Hasta} (ticks), urgente (bool),
%%   estado (pendiente | en_ruta | entregada | fallida | desviada | transbordo),
%%   aeronave (entero | undefined), pid (pid del gen_statem),
%%   tick_asignado, tick_entregado, retraso (ticks), motivo,
%%   ruta_id (referencia a p29_rutas), waypoint_actual (indice en ruta).
envio_upsert(Mapa) when is_map(Mapa) ->
  ets:insert(?TAB_ENVIOS, {maps:get(id, Mapa), Mapa}).

envio(Id) ->
  case ets:lookup(?TAB_ENVIOS, Id) of
    [{_, Mapa}] -> Mapa;
    [] -> undefined
  end.

envio_actualizar(Id, Cambios) when is_map(Cambios) ->
  case envio(Id) of
    undefined -> {error, no_existe};
    Mapa -> envio_upsert(maps:merge(Mapa, Cambios))
  end.

envios_todos() ->
  [Mapa || {_, Mapa} <- ets:tab2list(?TAB_ENVIOS)].

envios_de(AeronaveId) ->
  [M || M <- envios_todos(), maps:get(aeronave, M, undefined) =:= AeronaveId].

envios_por_estado(Estado) ->
  [M || M <- envios_todos(), maps:get(estado, M) =:= Estado].

conteo_envios() ->
  lists:foldl(
    fun(Mapa, Acc) ->
        maps:update_with(maps:get(estado, Mapa), fun(N) -> N + 1 end, 1, Acc)
    end, #{}, envios_todos()).

%% ids crecientes: reutilizar el ultimo id colisionaria con la fila de un
%% envio vivo o con su historial entregado/fallido
proximo_id() ->
  case envios_todos() of
    [] -> 1;
    Filas -> 1 + lists:max([maps:get(id, Mapa) || Mapa <- Filas])
  end.

%% ---- aeronaves (was vehiculos) -------------------------------------------------

%% Campos de la fila de aeronave:
%%   id (entero), tipo (b767_300f | b737_800f | atr_72f | b777_f | a330_200f),
%%   capacidad_kg, estado (en_tierra | en_ruta | alerta_meteo | alerta_mecanica
%%       | desvio_critico | mantenimiento),
%%   pos {lat, lon}, fl (flight level), gs (ground speed kts),
%%   combustible_pct, payload_kg, waypoint_actual (tuple {lat, lon, fl} | undefined),
%%   ruta (lista de waypoints), tick_ultimo_reporte, pid.
aeronave_upsert(Mapa) when is_map(Mapa) ->
  ets:insert(?TAB_AERONAVES, {maps:get(id, Mapa), Mapa}).

aeronave(Id) ->
  case ets:lookup(?TAB_AERONAVES, Id) of
    [{_, Mapa}] -> Mapa;
    [] -> undefined
  end.

aeronave_actualizar(Id, Cambios) when is_map(Cambios) ->
  case aeronave(Id) of
    undefined -> {error, no_existe};
    Mapa -> aeronave_upsert(maps:merge(Mapa, Cambios))
  end.

aeronaves_todas() ->
  [Mapa || {_, Mapa} <- ets:tab2list(?TAB_AERONAVES)].

conteo_aeronaves() ->
  lists:foldl(
    fun(Mapa, Acc) ->
        maps:update_with(maps:get(estado, Mapa), fun(N) -> N + 1 end, 1, Acc)
    end, #{}, aeronaves_todas()).

%% ---- waypoints -----------------------------------------------------------------

%% Campos: {iata, {lat, lon, elev_ft}, tipo (FIX | VOR | NDB | AEROPUERTO),
%%   region (FIR/UIR), pais}
waypoint_upsert(Mapa) when is_map(Mapa) ->
  ets:insert(?TAB_WAYPOINTS, {maps:get(iata, Mapa), Mapa}).

waypoint(IATA) ->
  case ets:lookup(?TAB_WAYPOINTS, IATA) of
    [{_, Mapa}] -> Mapa;
    [] -> undefined
  end.

waypoints_todos() ->
  [Mapa || {_, Mapa} <- ets:tab2list(?TAB_WAYPOINTS)].

%% ---- rutas vectoriales ---------------------------------------------------------

%% Campos: id_ruta (atom), nombre, waypoints_lista [IATA], segmento (aereo_internacional
%%   | troncal_terrestre | ultima_milla), distancia_nm, fl_optimo, tiempo_estimado_ticks
ruta_upsert(Mapa) when is_map(Mapa) ->
  ets:insert(?TAB_RUTAS, {maps:get(id_ruta, Mapa), Mapa}).

ruta(IdRuta) ->
  case ets:lookup(?TAB_RUTAS, IdRuta) of
    [{_, Mapa}] -> Mapa;
    [] -> undefined
  end.

rutas_todas() ->
  [Mapa || {_, Mapa} <- ets:tab2list(?TAB_RUTAS)].

%% ---- meteo ---------------------------------------------------------------------

%% Campos: zona {lat_base, lon_base}, severidad (moderada | severa),
%%   tipo (turbulencia | cizalladura | conveccion | hielo | baja_visibilidad),
%%   fl_afectado {FL_min, FL_max}, tick_inicio, tick_fin_estimado,
%%   sigmet_id (opcional)
meteo_upsert(Mapa) when is_map(Mapa) ->
  Key = maps:get(zona, Mapa),
  ets:insert(?TAB_METEO, {Key, Mapa}).

meteo_zona(Zona) ->
  case ets:lookup(?TAB_METEO, Zona) of
    [{_, Mapa}] -> Mapa;
    [] -> undefined
  end.

meteo_todas() ->
  [Mapa || {_, Mapa} <- ets:tab2list(?TAB_METEO)].

%% ---- ADS-B reports -------------------------------------------------------------

%% Campos: icao24 (hex), callsign, aeronave_id, pos {lat, lon}, fl, gs, track,
%%   combustible_pct, payload_kg, tick, timestamp_utc
adsb_upsert(Mapa) when is_map(Mapa) ->
  Key = {maps:get(icao24, Mapa), maps:get(tick, Mapa)},
  ets:insert(?TAB_ADSB, {Key, Mapa}).

adsb_ultimo(AeronaveId) ->
  %% Return latest ADS-B report for an aircraft
  case ets:select(?TAB_ADSB, [{{'$1', '$2', '_'}, [], ['$$']}]) of
    [] -> undefined;
    Resultados ->
      %% Filter by aeronave_id and get latest tick
      Filtrados = [R || R <- Resultados, maps:get(aeronave_id, R) =:= AeronaveId],
      case Filtrados of
        [] -> undefined;
        _ -> lists:max(Filtrados, fun(A, B) ->
                                  maps:get(tick, A) =< maps:get(tick, B)
                                end)
      end
  end.

adsb_todos() ->
  [Mapa || {_, Mapa} <- ets:tab2list(?TAB_ADSB)].

%% ---- transbordos ---------------------------------------------------------------

%% Campos: id_transbordo, envio_id, aeronave_origen, aeronave_destino,
%%   waypoint_transbordo (IATA), tick_programado, tick_ejecutado, estado
%%   (programado | en_proceso | completado | fallido)
transbordo_upsert(Mapa) when is_map(Mapa) ->
  ets:insert(?TAB_TRANSBORDOS, {maps:get(id_transbordo, Mapa), Mapa}).

transbordo(Id) ->
  case ets:lookup(?TAB_TRANSBORDOS, Id) of
    [{_, Mapa}] -> Mapa;
    [] -> undefined
  end.

transbordos_todos() ->
  [Mapa || {_, Mapa} <- ets:tab2list(?TAB_TRANSBORDOS)].

conteo_transbordos() ->
  lists:foldl(
    fun(Mapa, Acc) ->
        maps:update_with(maps:get(estado, Mapa), fun(N) -> N + 1 end, 1, Acc)
    end, #{}, transbordos_todos()).

%% ---- COMPATIBILIDAD HACIA ATRAS (deprecated) -----------------------------------

%% These map to new tables for test transition
entrega_upsert(Mapa) -> envio_upsert(Mapa).
entrega(Id) -> envio(Id).
entrega_actualizar(Id, Cambios) -> envio_actualizar(Id, Cambios).
entregas_todas() -> envios_todos().
entregas_de(Vid) -> envios_de(Vid).
entregas_por_estado(Estado) -> envios_por_estado(Estado).
conteo_entregas() -> conteo_envios().

vehiculo_upsert(Mapa) -> aeronave_upsert(Mapa).
vehiculo(Id) -> aeronave(Id).
vehiculo_actualizar(Id, Cambios) -> aeronave_actualizar(Id, Cambios).
vehiculos_todas() -> aeronaves_todas().
conteo_vehiculos() -> conteo_aeronaves().

%% ---- callbacks del gen_server (solo posee las tablas, no lleva logica) --------

handle_call(desconocido, _From, State) ->
  {reply, {error, desconocido}, State}.
handle_cast(_Msg, State) ->
  {noreply, State}.
handle_info(_Msg, State) ->
  {noreply, State}.