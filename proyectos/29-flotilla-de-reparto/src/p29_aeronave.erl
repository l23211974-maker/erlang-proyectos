-module(p29_aeronave).
-behaviour(gen_server).

%% Un gen_server por aeronave: movimiento en ruta vectorial entre waypoints/FIXes,
%% reporte ADS-B (posicion, FL, GS, combustible, payload) por tick.
%% No sabe nada de envios: las cargas las deriva el despachador.
%% Estados operativos: en_ruta, alerta_meteo, alerta_mecanica, desvio_critico, en_tierra.

-export([start_link/1, averiar/1, estado/1, modo/1, modo/2,
         asignar_ruta/3, desacargar/2, desviar_a/3]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

-define(FL_MIN, 290).   %% FL290
-define(FL_MAX, 410).   %% FL410
-define(GS_MIN, 380).   %% kts
-define(GS_MAX, 520).   %% kts

start_link(Id) ->
  gen_server:start_link({local, nombre(Id)}, ?MODULE, Id, []).

nombre(Id) ->
  list_to_atom("p29_aeronave_" ++ integer_to_list(Id)).

averiar(Id) ->
  exit(whereis(nombre(Id)), averia).

estado(Id) ->
  gen_server:call(nombre(Id), estado).

%% Cambio de modo operativo (para reasignacion manual, desvio, etc.)
modo(Id, NuevoModo) ->
  gen_server:call(nombre(Id), {modo, NuevoModo}).

modo(Id) ->
  gen_server:call(nombre(Id), modo).

%% ---- API para despachador: asignar ruta y carga ------------------------------

%% Called by despachador when assigning a shipment
asignar_ruta(Id, Ruta, PayloadKg) ->
  gen_server:cast(nombre(Id), {asignar_ruta, Ruta, PayloadKg}).

%% Called by despachador when delivery completed (unload payload)
desacargar(Id, PesoEntregado) ->
  gen_server:cast(nombre(Id), {desacargar, PesoEntregado}).

%% Called by despachador for diversion to alternate
desviar_a(Id, NuevoWP, NuevaRuta) ->
  gen_server:cast(nombre(Id), {desviar_a, NuevoWP, NuevaRuta}).

init(Id) ->
  case whereis(p29_reloj) of
    undefined -> ok;
    _ -> gen_server:call(p29_reloj, {subscribe, self()})
  end,
  %% Deterministic aircraft type and capacity from Id via phash2
  {Tipo, Capacidad} = tipo_por_id(Id),
  %% Initial position: first waypoint of assigned route (set by despachador)
  %% Before assignment, position is undefined
  p29_datos:aeronave_upsert(#{id => Id, tipo => Tipo, capacidad => Capacidad,
                               estado => en_tierra, pos => undefined, fl => undefined,
                               gs => undefined, combustible_pct => 100,
                               payload_kg => 0, waypoint_actual => undefined,
                               ruta => [], tick_ultimo_reporte => undefined,
                               pid => self()}),
  {ok, #{id => Id, tipo => Tipo}}.

handle_call(estado, _From, State) ->
  {reply, p29_datos:aeronave(maps:get(id, State)), State};

handle_call(modo, _From, State) ->
  Fila = p29_datos:aeronave(maps:get(id, State)),
  {reply, maps:get(estado, Fila, en_tierra), State};

handle_call({modo, NuevoModo}, _From, State = #{id := Id}) ->
  EstadosValidos = [en_ruta, alerta_meteo, alerta_mecanica, desvio_critico, en_tierra, mantenimiento],
  case lists:member(NuevoModo, EstadosValidos) of
    true ->
      p29_datos:aeronave_actualizar(Id, #{estado => NuevoModo}),
      {reply, ok, State};
    false ->
      {reply, {error, modo_invalido}, State}
  end;

handle_call(desconocido, _From, State) ->
  {reply, {error, desconocido}, State}.

handle_cast({asignar_ruta, Ruta, PayloadKg}, State = #{id := Id}) ->
  %% Take off: set initial position to first waypoint, climb to FL
  %% Ruta contains waypoint IDs (binaries); look up coordinates
  [PrimeroID | _] = Ruta,
  case p29_datos:waypoint(PrimeroID) of
    undefined ->
      %% Fallback: use default MEX coordinates
      {Lat, Lon, FL} = {19.4363, -99.0721, 250};
    #{coord := {Lat, Lon, Elev}} ->
      FL = Elev
  end,
  p29_datos:aeronave_actualizar(Id, #{
    pos => {Lat, Lon}, fl => FL, gs => 400,
    waypoint_actual => PrimeroID, ruta => Ruta,
    estado => en_ruta, payload_kg => PayloadKg,
    combustible_pct => 100
  }),
  {noreply, State};

handle_cast({desacargar, Peso}, State = #{id := Id}) ->
  Fila = p29_datos:aeronave(Id),
  PayloadActual = maps:get(payload_kg, Fila, 0),
  NuevoPayload = max(0, PayloadActual - Peso),
  p29_datos:aeronave_actualizar(Id, #{payload_kg => NuevoPayload}),
  {noreply, State};

handle_cast({desviar_a, NuevoWP, NuevaRuta}, State = #{id := Id}) ->
  p29_datos:aeronave_actualizar(Id, #{
    waypoint_actual => NuevoWP, ruta => NuevaRuta,
    estado => desvio_critico
  }),
  {noreply, State};

handle_cast(_Msg, State) ->
  {noreply, State}.

handle_info({p29_tick, N}, State = #{id := Id}) ->
  Fila = p29_datos:aeronave(Id),
  case maps:get(ruta, Fila) of
    [] ->
      %% On ground, no route assigned: report status so despachador detects restart
      Pos = maps:get(pos, Fila),
      FL = maps:get(fl, Fila),
      GS = maps:get(gs, Fila),
      Comb = maps:get(combustible_pct, Fila),
      Payload = maps:get(payload_kg, Fila),
      %% Use defaults if undefined (new aircraft just started)
      PosOK = case Pos of undefined -> {19.4363, -99.0721}; _ -> Pos end,
      FLOK = case FL of undefined -> 250; _ -> FL end,
      GSOK = case GS of undefined -> 0; _ -> GS end,
      CombOK = case Comb of undefined -> 100.0; _ -> Comb end,
      p29_datos:aeronave_actualizar(Id, #{
        tick_ultimo_reporte => N
      }),
      %% Report status to despachador (even on ground) so it knows we're alive
      p29_despachador:reportar_adsb(Id, PosOK, FLOK, GSOK,
                                    CombOK, Payload, N, self()),
      {noreply, State};
    _Ruta ->
      {NuevaPos, NuevoFL, NuevaGS, NuevoWP, Combustible, Payload, RutaRestante} =
        mover_en_ruta(Fila, N),
      p29_datos:aeronave_actualizar(Id, #{
        pos => NuevaPos, fl => NuevoFL, gs => NuevaGS,
        waypoint_actual => NuevoWP, combustible_pct => Combustible,
        payload_kg => Payload, ruta => RutaRestante,
        tick_ultimo_reporte => N
      }),
      %% Report ADS-B to despachador
      p29_despachador:reportar_adsb(Id, NuevaPos, NuevoFL, NuevaGS,
                                    Combustible, Payload, N, self()),
      {noreply, State}
  end;

handle_info({meteo_alerta, Zona, Severidad}, State = #{id := Id}) ->
  %% Receive weather alert for current zone
  Fila = p29_datos:aeronave(Id),
  ZonaActual = zona_de_posicion(maps:get(pos, Fila)),
  if
    ZonaActual =:= Zona ->
      NuevoEstado = case Severidad of
        moderada -> alerta_meteo;
        severa -> alerta_mecanica  %% severe weather treated as mechanical risk
      end,
      p29_datos:aeronave_actualizar(Id, #{estado => NuevoEstado}),
      {noreply, State};
    true ->
      {noreply, State}
  end;

handle_info(_Msg, State) ->
  {noreply, State}.

%% Movimiento en ruta vectorial: interpola entre waypoints
mover_en_ruta(Fila, _Tick) ->
  PosActual = maps:get(pos, Fila),
  FLActual = maps:get(fl, Fila),
  GSActual = maps:get(gs, Fila),
  Combustible = maps:get(combustible_pct, Fila),
  Payload = maps:get(payload_kg, Fila),
  Ruta = maps:get(ruta, Fila),
  WPActual = maps:get(waypoint_actual, Fila),

  %% Defensive: if critical fields are missing, stay put
  case {PosActual, FLActual, GSActual, Combustible, Ruta} of
    {undefined, _, _, _, _} ->
      {undefined, FLActual, GSActual, WPActual, Combustible, Payload, Ruta};
    {_, undefined, _, _, _} ->
      {PosActual, undefined, GSActual, WPActual, Combustible, Payload, Ruta};
    {_, _, undefined, _, _} ->
      {PosActual, FLActual, GSActual, WPActual, Combustible, Payload, Ruta};
    {_, _, _, undefined, _} ->
      {PosActual, FLActual, GSActual, WPActual, Combustible, Payload, Ruta};
    {_, _, _, _, []} ->
      %% Route completed - return to base or hold
      {PosActual, FLActual, GSActual, WPActual,
       max(0, Combustible - 0.5), Payload, []};
    {_, _, _, _, [WP_ID | Rest]} ->
      %% WP_ID is a binary (waypoint IATA); look up coordinates
      case p29_datos:waypoint(WP_ID) of
        undefined ->
          %% Fallback: stay at current position
          {PosActual, FLActual, GSActual, WPActual,
           max(0, Combustible - 0.5), Payload, Rest};
        #{coord := {Lat, Lon, Elev}} ->
          FL_WP = Elev,
          %% Calculate bearing and distance (simplified for simulation)
          {NuevaLat, NuevaLon} = interpolar_hacia(PosActual, {Lat, Lon}, GSActual),
          %% Adjust FL towards target FL
          NuevoFL = ajustar_fl(FLActual, FL_WP),
          %% GS varies slightly with wind/conditions, clamped to limits
          NuevaGS = clamp(GSActual + (erlang:phash2({turbulencia, _Tick}) rem 20) - 10,
                          ?GS_MIN, ?GS_MAX),
          %% Fuel burn ~0.1% per tick at cruise
          NuevoCombustible = max(0, Combustible - 0.1),
          %% Payload constant unless delivery completed (handled by despachador)
          { {NuevaLat, NuevaLon}, NuevoFL, NuevaGS, WP_ID, NuevoCombustible, Payload, Rest }
      end
  end.

%% Deterministic aircraft type assignment
tipo_por_id(Id) ->
  %% Solo las suites de test piden flota homogenea (tipos reales fuera).
  case application:get_env(p29_flotilla_de_reparto, flota_uniforme_kg) of
    {ok, Cap} when is_integer(Cap), Cap > 0 ->
      {test_uniform, Cap};
    _ ->
      Tipos = [
        {b767_300f, 52400},   %% kg payload max
        {b737_800f, 23900},
        {atr_72f, 8200},
        {b777_f, 102000},
        {a330_200f, 65000}
      ],
      lists:nth((erlang:phash2(Id) rem length(Tipos)) + 1, Tipos)
  end.

%% Interpolation towards waypoint (simplified great-circle approximation)
interpolar_hacia({Lat1, Lon1}, {Lat2, Lon2}, GS) ->
  %% Distance in NM per tick (10s): GS * 10/3600
  DistTick = GS * 10 / 3600,
  %% Simple linear interpolation (for simulation, not real navigation)
  Fraccion = min(1.0, DistTick / max(1.0, distancia_nm({Lat1, Lon1}, {Lat2, Lon2}))),
  NuevaLat = Lat1 + (Lat2 - Lat1) * Fraccion,
  NuevaLon = Lon1 + (Lon2 - Lon1) * Fraccion,
  {NuevaLat, NuevaLon}.

distancia_nm({Lat1, Lon1}, {Lat2, Lon2}) ->
  %% Haversine approximation (simplified)
  R = 3440, %% NM
  DLat = math:pi() * (Lat2 - Lat1) / 180,
  DLon = math:pi() * (Lon2 - Lon1) / 180,
  Lat1Rad = math:pi() * Lat1 / 180,
  Lat2Rad = math:pi() * Lat2 / 180,
  A = math:sin(DLat/2)*math:sin(DLat/2) +
      math:sin(DLon/2)*math:sin(DLon/2) * math:cos(Lat1Rad) * math:cos(Lat2Rad),
  C = 2 * math:atan2(math:sqrt(A), math:sqrt(1-A)),
  R * C.

ajustar_fl(Actual, Objetivo) ->
  Diff = Objetivo - Actual,
  case Diff of
    D when D > 10 -> Actual + 10;
    D when D < -10 -> Actual - 10;
    _ -> Objetivo
  end.

clamp(V, Min, Max) -> max(Min, min(Max, V)).

zona_de_posicion({Lat, Lon}) ->
  %% Simplified zone determination for weather alerts
  ZonaLat = erlang:round(Lat / 5) * 5,
  ZonaLon = erlang:round(Lon / 5) * 5,
  {ZonaLat, ZonaLon}.