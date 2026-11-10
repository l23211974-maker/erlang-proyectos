-module(p29_adsb).
-behaviour(gen_server).

%% Manejo de reportes ADS-B: recepcion, validacion, almacenamiento y
%% distribucion a suscriptores (despachador, UI via SSE).

-export([start_link/0, reporte/1, ultimos_para/2, estadisticas/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% Enviar reporte ADS-B (llamado por aeronave o receptor)
reporte(Datos) ->
  gen_server:cast(?MODULE, {reporte, Datos}).

%% Obtener ultimos N reportes para una aeronave
ultimos_para(AeronaveId, N) ->
  gen_server:call(?MODULE, {ultimos_para, AeronaveId, N}).

estadisticas() ->
  gen_server:call(?MODULE, estadisticas).

init([]) ->
  {ok, #{reportes_por_aeronave => #{}, total_reportes => 0, errores => 0}}.

handle_call({ultimos_para, Aid, N}, _From, State) ->
  Reportes = maps:get(Aid, maps:get(reportes_por_aeronave, State), []),
  Ultimos = lists:sublist(lists:reverse(Reportes), N),
  {reply, Ultimos, State};

handle_call(estadisticas, _From, State) ->
  {reply, #{total => maps:get(total_reportes, State),
            por_aeronave => map_size(maps:get(reportes_por_aeronave, State)),
            errores => maps:get(errores, State)}, State};

handle_call(desconocido, _From, State) ->
  {reply, {error, desconocido}, State}.

handle_cast({reporte, Datos}, State) ->
  %% Validar reporte ADS-B basico
  case validar_adsb(Datos) of
    {ok, DatosValidos} ->
      Aid = maps:get(aeronave_id, DatosValidos),
      Reportes = maps:get(Aid, maps:get(reportes_por_aeronave, State), []),
      %% Mantener ultimos 100 reportes por aeronave
      Nuevos = (Reportes ++ [DatosValidos]),
      Recortados = if length(Nuevos) > 100 -> lists:nthtail(length(Nuevos) - 100, Nuevos);
                      true -> Nuevos end,
      ReportesPorAeronave = maps:put(Aid, Recortados,
                                      maps:get(reportes_por_aeronave, State)),
      Total = maps:get(total_reportes, State) + 1,
      %% Tambien guardar en ETS para persistencia/queries
      p29_datos:adsb_upsert(DatosValidos),
      {noreply, State#{reportes_por_aeronave => ReportesPorAeronave,
                       total_reportes => Total}};
    {error, Razon} ->
      Errores = maps:get(errores, State) + 1,
      logger:warning("ADS-B invalido: ~p - ~p", [Razon, Datos]),
      {noreply, State#{errores => Errores}}
  end;

handle_cast(_Msg, State) ->
  {noreply, State}.

handle_info(_Msg, State) ->
  {noreply, State}.

validar_adsb(#{icao24 := ICAO, callsign := CS, aeronave_id := Aid,
               pos := {Lat, Lon}, fl := FL, gs := GS,
               combustible_pct := Comb, payload_kg := Payload,
               tick := Tick}) when is_binary(ICAO), is_binary(CS),
                                       is_integer(Aid), is_number(Lat),
                                       is_number(Lon), is_integer(FL),
                                       is_number(GS), is_number(Comb),
                                       is_number(Payload), is_integer(Tick) ->
  {ok, #{icao24 => ICAO, callsign => CS, aeronave_id => Aid,
         pos => {Lat, Lon}, fl => FL, gs => GS,
         track => maps:get(track, #{}, 0),
         combustible_pct => Comb, payload_kg => Payload,
         tick => Tick, timestamp_utc => timestamp_utc()}};
validar_adsb(Datos) ->
  {error, {campos_faltantes_o_invalidos, maps:keys(Datos)}}.

timestamp_utc() ->
  {{Y, M, D}, {H, Min, S}} = calendar:universal_time(),
  io_lib:format("~4..0w-~2..0w-~2..0wT~2..0w:~2..0w:~2..0wZ", [Y, M, D, H, Min, S]).