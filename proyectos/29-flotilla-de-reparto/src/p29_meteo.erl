-module(p29_meteo).
-behaviour(gen_server).

%% Servicio meteorologico: genera y propaga alertas SIGMET/AIRMET
%% para el espacio aereo simulado. Se suscribe al reloj y emite
%% alertas que afectan a aeronaves en zonas especificas.

-export([start_link/0, alerta_para_zona/1, alertas_activas/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

-define(TIPOS_METEO, [turbulencia, cizalladura, conveccion, hielo, baja_visibilidad]).
-define(SEVERIDADES, [moderada, severa]).

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

alerta_para_zona(Zona) ->
  gen_server:call(?MODULE, {alerta_para_zona, Zona}).

alertas_activas() ->
  gen_server:call(?MODULE, alertas_activas).

init([]) ->
  case whereis(p29_reloj) of
    undefined -> ok;
    _ -> gen_server:call(p29_reloj, {subscribe, self()})
  end,
  {ok, #{alertas_activas => #{}, tick_siguiente_alerta => 50}}.

handle_call({alerta_para_zona, Zona}, _From, State) ->
  Alertas = maps:get(alertas_activas, State),
  {reply, maps:get(Zona, Alertas, undefined), State};

handle_call(alertas_activas, _From, State) ->
  {reply, maps:values(maps:get(alertas_activas, State)), State};

handle_call(desconocido, _From, State) ->
  {reply, {error, desconocido}, State}.

handle_cast(_Msg, State) ->
  {noreply, State}.

handle_info({p29_tick, N}, State) ->
  %% Generar nuevas alertas meteorologicas aleatoriamente (deterministico)
  State1 = maybe_generar_alerta(N, State),
  %% Expirar alertas viejas
  State2 = expirar_alertas(N, State1),
  {noreply, State2};

handle_info(_Msg, State) ->
  {noreply, State}.

maybe_generar_alerta(N, State = #{tick_siguiente_alerta := Next}) ->
  if
    N >= Next ->
      %% Generar alerta en zona aleatoria
      Zona = zona_aleatoria(N),
      Tipo = tipo_aleatorio(N),
      Severidad = severidad_aleatoria(N),
      FLMin = fl_min_aleatorio(N),
      FLMax = FLMin + 40 + (erlang:phash2({fl, N}) rem 60),
      TickFin = N + 30 + (erlang:phash2({dur, N}) rem 120), %% 5-20 min simulados

      Alerta = #{zona => Zona, tipo => Tipo, severidad => Severidad,
                 fl_afectado => {FLMin, FLMax}, tick_inicio => N,
                 tick_fin_estimado => TickFin,
                 sigmet_id => sigmet_id(N)},

      AlertasNuevas = maps:put(Zona, Alerta, maps:get(alertas_activas, State)),
      NextTick = N + 100 + (erlang:phash2({next, N}) rem 200), %% cada 16-50 min
      State#{alertas_activas => AlertasNuevas, tick_siguiente_alerta => NextTick};
    true ->
      State
  end.

expirar_alertas(N, State) ->
  Alertas = maps:get(alertas_activas, State),
  AlertasVigentes = maps:filter(
    fun(_Zona, A) -> maps:get(tick_fin_estimado, A) > N end, Alertas),
  State#{alertas_activas => AlertasVigentes}.

zona_aleatoria(N) ->
  %% Zonas de 5x5 grados
  BaseLat = -30 + (erlang:phash2({lat, N}) rem 60),
  BaseLon = -120 + (erlang:phash2({lon, N}) rem 60),
  {BaseLat, BaseLon}.

tipo_aleatorio(N) ->
  lists:nth((erlang:phash2({tipo, N}) rem length(?TIPOS_METEO)) + 1, ?TIPOS_METEO).

severidad_aleatoria(N) ->
  lists:nth((erlang:phash2({sev, N}) rem length(?SEVERIDADES)) + 1, ?SEVERIDADES).

fl_min_aleatorio(N) ->
  280 + (erlang:phash2({flmin, N}) rem 100). %% FL280-FL380

sigmet_id(N) ->
  <<"WS", (erlang:phash2({sigmet, N}) rem 1000)/integer>>.

%% ---- Notificacion a aeronaves ------------------------------------------------

%% Not used - weather alerts are handled directly via p29_despachador:meteo_alerta/1
%% Called by p29_reloj or externally to notify aircraft of weather
% notificar_aeronaves(State) ->
%   Alertas = maps:values(maps:get(alertas_activas, State)),
%   [p29_despachador:meteo_alerta(A) || A <- Alertas],
%   ok.