-module(p29_ruta_vectorial).
-behaviour(gen_server).

%% Gestion de rutas vectoriales entre waypoints/FIXes para el espacio aereo.
%% Rutas predefinidas y generacion de rutas ad-hoc para reasignaciones/desvios.

-export([start_link/0, ruta_para/3, ruta_alternativa/4,
         distancia_nm/2, tiempo_estimado/3, waypoints_de/1,
         fl_maximo_por_tipo/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

%% Waypoints base del espacio aereo (subset realistas para simulacion)
-define(WAYPOINTS_BASE, #{
  %% Mexico FIR
  <<"MEX">> => #{coord => {19.4363, -99.0721, 7316}, tipo => aeropuerto, fir => <<"MMMX">>},
  <<"TLC">> => #{coord => {19.3371, -99.5660, 8466}, tipo => aeropuerto, fir => <<"MMMX">>},
  <<"MTY">> => #{coord => {25.7785, -100.1069, 1278}, tipo => aeropuerto, fir => <<"MMMX">>},
  <<"GDL">> => #{coord => {20.5218, -103.3112, 5016}, tipo => aeropuerto, fir => <<"MMMX">>},
  <<"CUN">> => #{coord => {21.0365, -86.8771, 12}, tipo => aeropuerto, fir => <<"MMMX">>},
  <<"VAKUD">> => #{coord => {21.5000, -98.0000, 0}, tipo => fix, fir => <<"MMMX">>},
  <<"OTUBA">> => #{coord => {20.2000, -99.5000, 0}, tipo => fix, fir => <<"MMMX">>},
  <<"GIRAR">> => #{coord => {22.0000, -97.0000, 0}, tipo => fix, fir => <<"MMMX">>},
  <<"ULQ">> => #{coord => {19.0000, -98.5000, 0}, tipo => fix, fir => <<"MMMX">>},
  %% Central America / Caribbean
  <<"SAL">> => #{coord => {13.4409, -89.0557, 100}, tipo => aeropuerto, fir => <<"MSLP">>},
  <<"GUA">> => #{coord => {14.5833, -90.5275, 4951}, tipo => aeropuerto, fir => <<"MGGT">>},
  <<"PTY">> => #{coord => {9.0714, -79.3836, 47}, tipo => aeropuerto, fir => <<"MPTO">>},
  <<"BOG">> => #{coord => {4.7016, -74.1469, 8361}, tipo => aeropuerto, fir => <<"SKBO">>},
  <<"CLO">> => #{coord => {3.5431, -76.3816, 3162}, tipo => aeropuerto, fir => <<"SKCL">>},
  <<"MDE">> => #{coord => {6.1645, -75.4231, 7027}, tipo => aeropuerto, fir => <<"SKRG">>},
  <<"UIO">> => #{coord => {-0.1292, -78.3575, 9228}, tipo => aeropuerto, fir => <<"SEQU">>},
  <<"GYE">> => #{coord => {-2.1574, -79.8836, 19}, tipo => aeropuerto, fir => <<"SEGU">>},
  %% South America
  <<"EZE">> => #{coord => {-34.8222, -58.5358, 67}, tipo => aeropuerto, fir => <<"SAEZ">>},
  <<"SCL">> => #{coord => {-33.3930, -70.7858, 1555}, tipo => aeropuerto, fir => <<"SCEL">>},
  <<"LIM">> => #{coord => {-12.0219, -77.1143, 113}, tipo => aeropuerto, fir => <<"SPIM">>},
  %% Waypoints de ruta (FIXes sobre oceanos/areas remotas)
  <<"FIX01">> => #{coord => {15.0000, -92.0000, 0}, tipo => fix, fir => <<"MMMX">>},
  <<"FIX02">> => #{coord => {10.0000, -85.0000, 0}, tipo => fix, fir => <<"MSLP">>},
  <<"FIX03">> => #{coord => {5.0000, -80.0000, 0}, tipo => fix, fir => <<"MPTO">>},
  <<"FIX04">> => #{coord => {0.0000, -78.0000, 0}, tipo => fix, fir => <<"SEQU">>},
  <<"FIX05">> => #{coord => {-5.0000, -75.0000, 0}, tipo => fix, fir => <<"SPIM">>},
  <<"FIX06">> => #{coord => {-15.0000, -70.0000, 0}, tipo => fix, fir => <<"SCEL">>},
  <<"FIX07">> => #{coord => {-25.0000, -60.0000, 0}, tipo => fix, fir => <<"SAEZ">>},
  <<"FIX08">> => #{coord => {25.0000, -88.0000, 0}, tipo => fix, fir => <<"MMMX">>},
  <<"FIX09">> => #{coord => {30.0000, -95.0000, 0}, tipo => fix, fir => <<"KZHU">>},
  <<"FIX10">> => #{coord => {35.0000, -100.0000, 0}, tipo => fix, fir => <<"KZFW">>}
}).

%% Rutas predefinidas por segmento (keys como tuplas {Origen, Destino})
-define(RUTAS_PREDEFINIDAS, #{
  {<<"MEX">>, <<"BOG">>} => #{id_ruta => <<"MEX-BOG">>, nombre => <<"MEX → BOG">>,
                       waypoints => [<<"MEX">>, <<"VAKUD">>, <<"FIX01">>, <<"FIX02">>, <<"BOG">>],
                       segmento => aereo_internacional, distancia_nm => 1650,
                       fl_optimo => 350, tiempo_estimado_ticks => 540},
  {<<"MEX">>, <<"PTY">>} => #{id_ruta => <<"MEX-PTY">>, nombre => <<"MEX → PTY">>,
                       waypoints => [<<"MEX">>, <<"OTUBA">>, <<"FIX01">>, <<"FIX03">>, <<"PTY">>],
                       segmento => aereo_internacional, distancia_nm => 1350,
                       fl_optimo => 330, tiempo_estimado_ticks => 450},
  {<<"MEX">>, <<"EZE">>} => #{id_ruta => <<"MEX-EZE">>, nombre => <<"MEX → EZE">>,
                       waypoints => [<<"MEX">>, <<"GIRAR">>, <<"FIX01">>, <<"FIX02">>, <<"FIX04">>, <<"FIX05">>, <<"FIX06">>, <<"FIX07">>, <<"EZE">>],
                       segmento => aereo_internacional, distancia_nm => 4500,
                       fl_optimo => 370, tiempo_estimado_ticks => 1500},
  {<<"MEX">>, <<"LIM">>} => #{id_ruta => <<"MEX-LIM">>, nombre => <<"MEX → LIM">>,
                       waypoints => [<<"MEX">>, <<"VAKUD">>, <<"FIX01">>, <<"FIX03">>, <<"FIX05">>, <<"LIM">>],
                       segmento => aereo_internacional, distancia_nm => 2100,
                       fl_optimo => 350, tiempo_estimado_ticks => 700},
  {<<"BOG">>, <<"EZE">>} => #{id_ruta => <<"BOG-EZE">>, nombre => <<"BOG → EZE">>,
                       waypoints => [<<"BOG">>, <<"FIX04">>, <<"FIX05">>, <<"FIX06">>, <<"EZE">>],
                       segmento => aereo_internacional, distancia_nm => 2850,
                       fl_optimo => 370, tiempo_estimado_ticks => 950},
  {<<"PTY">>, <<"BOG">>} => #{id_ruta => <<"PTY-BOG">>, nombre => <<"PTY → BOG">>,
                       waypoints => [<<"PTY">>, <<"FIX03">>, <<"BOG">>],
                       segmento => aereo_internacional, distancia_nm => 750,
                       fl_optimo => 330, tiempo_estimado_ticks => 250},
  {<<"MTY">>, <<"MEX">>} => #{id_ruta => <<"MTY-MEX">>, nombre => <<"MTY → MEX">>,
                       waypoints => [<<"MTY">>, <<"OTUBA">>, <<"MEX">>],
                       segmento => troncal_terrestre, distancia_nm => 450,
                       fl_optimo => 250, tiempo_estimado_ticks => 150},
  {<<"GDL">>, <<"MEX">>} => #{id_ruta => <<"GDL-MEX">>, nombre => <<"GDL → MEX">>,
                       waypoints => [<<"GDL">>, <<"ULQ">>, <<"MEX">>],
                       segmento => troncal_terrestre, distancia_nm => 350,
                       fl_optimo => 250, tiempo_estimado_ticks => 120},
  {<<"CUN">>, <<"MEX">>} => #{id_ruta => <<"CUN-MEX">>, nombre => <<"CUN → MEX">>,
                       waypoints => [<<"CUN">>, <<"FIX08">>, <<"MEX">>],
                       segmento => aereo_internacional, distancia_nm => 1050,
                       fl_optimo => 330, tiempo_estimado_ticks => 350}
}).

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

ruta_para(OrigenIATA, DestinoIATA, TipoAeronave) ->
  gen_server:call(?MODULE, {ruta_para, OrigenIATA, DestinoIATA, TipoAeronave}).

ruta_alternativa(OrigenIATA, DestinoIATA, EvitarZonas, TipoAeronave) ->
  gen_server:call(?MODULE, {ruta_alternativa, OrigenIATA, DestinoIATA, EvitarZonas, TipoAeronave}).

distancia_nm(WP1, WP2) ->
  gen_server:call(?MODULE, {distancia_nm, WP1, WP2}).

tiempo_estimado(DistanciaNM, GS, TipoAeronave) ->
  gen_server:call(?MODULE, {tiempo_estimado, DistanciaNM, GS, TipoAeronave}).

waypoints_de(RutaId) ->
  gen_server:call(?MODULE, {waypoints_de, RutaId}).

init([]) ->
  %% Poblar tablas ETS con waypoints y rutas base
  poblar_waypoints(),
  poblar_rutas(),
  {ok, #{}}.

handle_call({ruta_para, Origen, Destino, Tipo}, _From, State) ->
  Key = {Origen, Destino},
  case maps:find(Key, ?RUTAS_PREDEFINIDAS) of
    {ok, Ruta} ->
      %% Adaptar FL optimo segun tipo de aeronave
      FLMax = fl_maximo_por_tipo(Tipo),
      RutaAdaptada = Ruta#{fl_optimo => min(maps:get(fl_optimo, Ruta), FLMax)},
      {reply, RutaAdaptada, State};
    error ->
      %% Generar ruta ad-hoc via waypoints intermedios y guardarla en ETS
      RutaGenerada = generar_ruta_adhoc(Origen, Destino, Tipo),
      p29_datos:ruta_upsert(RutaGenerada),
      {reply, RutaGenerada, State}
  end;

handle_call({ruta_alternativa, Origen, Destino, EvitarZonas, Tipo}, _From, State) ->
  %% Generar ruta evitando zonas de meteo y guardarla en ETS
  Ruta = generar_ruta_evitando(Origen, Destino, EvitarZonas, Tipo),
  p29_datos:ruta_upsert(Ruta),
  {reply, Ruta, State};

handle_call({distancia_nm, WP1, WP2}, _From, State) ->
  {Lat1, Lon1, _} = maps:get(coord, maps:get(WP1, ?WAYPOINTS_BASE, #{})),
  {Lat2, Lon2, _} = maps:get(coord, maps:get(WP2, ?WAYPOINTS_BASE, #{})),
  Dist = haversine_nm({Lat1, Lon1}, {Lat2, Lon2}),
  {reply, Dist, State};

handle_call({tiempo_estimado, DistNM, GS, Tipo}, _From, State) ->
  %% Ticks = (NM / kts) * 3600 / 10 (ticks de 10s)
  %% Con margen por tipo y congestion
  Margen = margen_por_tipo(Tipo),
  Ticks = round((DistNM / max(GS, 1)) * 360 * (1 + Margen)),
  {reply, Ticks, State};

handle_call({waypoints_de, RutaId}, _From, State) ->
  case p29_datos:ruta(RutaId) of
    undefined -> {reply, [], State};
    R -> {reply, maps:get(waypoints, R, []), State}
  end;

handle_call(desconocido, _From, State) ->
  {reply, {error, desconocido}, State}.

handle_cast(_Msg, State) ->
  {noreply, State}.

handle_info(_Msg, State) ->
  {noreply, State}.

%% ---- internos ----------------------------------------------------------------

poblar_waypoints() ->
  [p29_datos:waypoint_upsert(#{iata => IATA, coord => maps:get(coord, D),
                               tipo => maps:get(tipo, D), fir => maps:get(fir, D)})
   || {IATA, D} <- maps:to_list(?WAYPOINTS_BASE)],
  ok.

poblar_rutas() ->
  [p29_datos:ruta_upsert(R) || {_, R} <- maps:to_list(?RUTAS_PREDEFINIDAS)],
  ok.

generar_ruta_adhoc(Origen, Destino, Tipo) ->
  %% Buscar waypoints intermedios que conecten origen-destino
  FLMax = fl_maximo_por_tipo(Tipo),
  WPOrigen = maps:get(Origen, ?WAYPOINTS_BASE),
  WPDestino = maps:get(Destino, ?WAYPOINTS_BASE),
  case {WPOrigen, WPDestino} of
    {#{coord := C1}, #{coord := C2}} ->
      Dist = haversine_nm(C1, C2),
      %% Simplificado: ruta directa con 1-2 waypoints intermedios
      Intermedios = waypoints_intermedios(C1, C2),
      Waypoints = [Origen | Intermedios] ++ [Destino],
      #{id_ruta => list_to_binary("ADHOC-" ++ binary_to_list(Origen) ++ "-" ++ binary_to_list(Destino)),
        nombre => binary_to_list(Origen) ++ " → " ++ binary_to_list(Destino),
        waypoints => Waypoints,
        segmento => segmento_por_distancia(Dist),
        distancia_nm => Dist,
        fl_optimo => min(350, FLMax),
        tiempo_estimado_ticks => round(Dist / 450 * 360)};
    _ ->
      %% Fallback: ruta directa
      #{id_ruta => list_to_binary("DIRECT-" ++ binary_to_list(Origen) ++ "-" ++ binary_to_list(Destino)),
        nombre => binary_to_list(Origen) ++ " → " ++ binary_to_list(Destino),
        waypoints => [Origen, Destino],
        segmento => aereo_internacional,
        distancia_nm => 0, fl_optimo => FLMax, tiempo_estimado_ticks => 0}
  end.

generar_ruta_evitando(Origen, Destino, _EvitarZonas, Tipo) ->
  %% Por ahora: ruta ad-hoc ignorando EvitarZonas (simplificado)
  generar_ruta_adhoc(Origen, Destino, Tipo).

waypoints_intermedios({Lat1, Lon1, _}, {Lat2, Lon2, _}) ->
  %% Waypoints predefinidos en la zona
  Candidates = [<<"FIX01">>, <<"FIX02">>, <<"FIX03">>, <<"FIX04">>, <<"FIX05">>, <<"FIX06">>, <<"FIX07">>],
  %% Filtrar los que estan "en el camino" (simplificado: lat/lon entre origen y destino)
  [WP || WP <- Candidates,
         maps:is_key(WP, ?WAYPOINTS_BASE),
         case maps:get(coord, maps:get(WP, ?WAYPOINTS_BASE)) of
           {Lat, Lon, _} ->
             Lat =< max(Lat1, Lat2) + 5 andalso Lat >= min(Lat1, Lat2) - 5 andalso
             Lon =< max(Lon1, Lon2) + 5 andalso Lon >= min(Lon1, Lon2) - 5;
           _ -> false
         end].

segmento_por_distancia(Dist) when Dist > 2000 -> aereo_internacional;
segmento_por_distancia(Dist) when Dist > 500 -> troncal_terrestre;
segmento_por_distancia(_) -> ultima_milla.

fl_maximo_por_tipo(b777_f) -> 430;
fl_maximo_por_tipo(b767_300f) -> 410;
fl_maximo_por_tipo(a330_200f) -> 410;
fl_maximo_por_tipo(b737_800f) -> 390;
fl_maximo_por_tipo(atr_72f) -> 250;
fl_maximo_por_tipo(_) -> 350.

margen_por_tipo(b777_f) -> 0.05;
margen_por_tipo(b767_300f) -> 0.08;
margen_por_tipo(a330_200f) -> 0.08;
margen_por_tipo(b737_800f) -> 0.10;
margen_por_tipo(atr_72f) -> 0.15;
margen_por_tipo(_) -> 0.10.

haversine_nm({Lat1, Lon1}, {Lat2, Lon2}) ->
  haversine_nm({Lat1, Lon1, 0}, {Lat2, Lon2, 0});

haversine_nm({Lat1, Lon1, _}, {Lat2, Lon2, _}) ->
  R = 3440.065, %% NM
  DLat = math:pi() * (Lat2 - Lat1) / 180,
  DLon = math:pi() * (Lon2 - Lon1) / 180,
  Lat1Rad = math:pi() * Lat1 / 180,
  Lat2Rad = math:pi() * Lat2 / 180,
  A = math:sin(DLat/2)*math:sin(DLat/2) +
      math:sin(DLon/2)*math:sin(DLon/2) * math:cos(Lat1Rad) * math:cos(Lat2Rad),
  C = 2 * math:atan2(math:sqrt(A), math:sqrt(1-A)),
  R * C.