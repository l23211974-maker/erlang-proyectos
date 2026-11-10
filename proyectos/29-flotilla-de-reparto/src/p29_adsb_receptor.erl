-module(p29_adsb_receptor).
-behaviour(gen_server).

%% Receptor ADS-B: simula la recepcion de transmisiones 1090 MHz
%% de las aeronaves. Se suscribe al reloj y procesa los reportes
%% de las aeronaves activadas, reenviandolos a p29_adsb.

-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
  case whereis(p29_reloj) of
    undefined -> ok;
    _ -> gen_server:call(p29_reloj, {subscribe, self()})
  end,
  {ok, #{}}.

handle_call(desconocido, _From, State) ->
  {reply, {error, desconocido}, State}.

handle_cast(_Msg, State) ->
  {noreply, State}.

handle_info({p29_tick, N}, State) ->
  %% Obtener todas las aeronaves en_ruta y solicitar su reporte ADS-B
  Aeronaves = p29_datos:aeronaves_todas(),
  EnRuta = [A || A <- Aeronaves, maps:get(estado, A) =:= en_ruta],
  [procesar_reporte(A, N) || A <- EnRuta],
  {noreply, State};

handle_info(_Msg, State) ->
  {noreply, State}.

procesar_reporte(Aeronave, Tick) ->
  Aid = maps:get(id, Aeronave),
  Pos = maps:get(pos, Aeronave),
  FL = maps:get(fl, Aeronave),
  GS = maps:get(gs, Aeronave),
  Comb = maps:get(combustible_pct, Aeronave),
  Payload = maps:get(payload_kg, Aeronave),

  case {Pos, FL, GS} of
    {{Lat, Lon}, FLVal, GSVal} when is_number(Lat), is_number(Lon),
                                      is_integer(FLVal), is_number(GSVal) ->
      ICAO = icao_por_id(Aid),
      CallSign = callsign_por_id(Aid),
      Track = track_hacia_waypoint(Pos, maps:get(waypoint_actual, Aeronave)),

      Datos = #{icao24 => ICAO, callsign => CallSign, aeronave_id => Aid,
                pos => Pos, fl => FLVal, gs => GSVal, track => Track,
                combustible_pct => Comb, payload_kg => Payload, tick => Tick},
      p29_adsb:reporte(Datos);
    _ ->
      %% No hay datos completos aun
      ok
  end.

icao_por_id(Id) ->
  %% Generar ICAO24 deterministico a partir del ID (6 hex chars = 24 bits)
  %% Retorna binario con representacion hex (ej: <<"A00123">>)
  Base = 16#A00000 + (Id * 16#100) rem 16#FFFFFF,
  HexStr = integer_to_list(Base, 16),
  Padded = case length(HexStr) < 6 of
    true -> lists:duplicate(6 - length(HexStr), $0) ++ HexStr;
    false -> HexStr
  end,
  list_to_binary(string:uppercase(Padded)).

callsign_por_id(Id) ->
  Prefijos = [<<"AER">>, <<"CGO">>, <<"FRT">>, <<"LIN">>, <<"XPR">>],
  Pref = lists:nth((erlang:phash2({cs, Id}) rem length(Prefijos)) + 1, Prefijos),
  Num = 100 + (erlang:phash2({csn, Id}) rem 900),
  NumBin = list_to_binary(integer_to_list(Num)),
  <<Pref/binary, NumBin/binary>>.

track_hacia_waypoint(_, undefined) -> 0;
track_hacia_waypoint({Lat1, Lon1}, Target) ->
  %% Target puede ser un tuple {Lat2, Lon2, FL} o un binary (waypoint ID)
  case Target of
    {Lat2, Lon2, _FL} ->
      %% Ya tenemos las coordenadas
      calcular_rumbo(Lat1, Lon1, Lat2, Lon2);
    WP_ID when is_binary(WP_ID) ->
      %% Lookup waypoint coordinates
      case p29_datos:waypoint(WP_ID) of
        #{coord := {Lat2, Lon2, _}} ->
          calcular_rumbo(Lat1, Lon1, Lat2, Lon2);
        _ ->
          0
      end;
    _ ->
      0
  end.

calcular_rumbo(Lat1, Lon1, Lat2, Lon2) ->
  DLon = math:pi() * (Lon2 - Lon1) / 180,
  Lat1Rad = math:pi() * Lat1 / 180,
  Lat2Rad = math:pi() * Lat2 / 180,
  Y = math:sin(DLon) * math:cos(Lat2Rad),
  X = math:cos(Lat1Rad) * math:sin(Lat2Rad) -
      math:sin(Lat1Rad) * math:cos(Lat2Rad) * math:cos(DLon),
  Brng = math:atan2(Y, X) * 180 / math:pi(),
  (round(Brng) + 360) rem 360.