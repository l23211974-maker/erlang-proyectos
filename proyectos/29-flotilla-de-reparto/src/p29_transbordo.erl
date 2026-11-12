-module(p29_transbordo).
-behaviour(gen_statem).

%% Proceso de transbordo: traslado de carga entre aeronaves en waypoint intermedio.
%% Un gen_statem por transbordo programado.
%%
%% Estados: programado -> en_proceso -> completado | fallido

-export([start_link/1, estado/1]).
-export([init/1, callback_mode/0,
         programado/3, en_proceso/3, completado/3, fallida/3,
         terminate/3]).

start_link(Datos) ->
  gen_statem:start_link(?MODULE, Datos, []).

estado(Pid) ->
  gen_statem:call(Pid, estado).

callback_mode() ->
  [state_functions].

init(Datos) ->
  %% Datos: #{id_transbordo, envio_id, aeronave_origen, aeronave_destino,
  %%   waypoint_transbordo, tick_programado, tick_timeout}
  p29_datos:transbordo_upsert(
    Datos#{estado => programado, tick_ejecutado => undefined, pid => self()}),
  %% Suscribirse al reloj para recibir ticks
  case whereis(p29_reloj) of
    undefined -> ok;
    _ -> gen_server:call(p29_reloj, {subscribe, self()})
  end,
  {ok, programado, Datos#{tick_ejecutado => undefined}}.

%% ---- programado --------------------------------------------------------------

programado({call, From}, estado, Data) ->
  {keep_state_and_data, [{reply, From, {programado, maps:get(envio_id, Data)}}]};

programado({call, From}, _Otro, Data) ->
  {keep_state, Data, [{reply, From, {error, estado_no_valido}}]};

programado(info, {p29_tick, N}, Data = #{tick_programado := TickProg}) ->
  if
    N >= TickProg ->
      %% Tiempo de iniciar el transbordo
      iniciar_transbordo(Data#{tick_ejecutado := N});
    true ->
      {keep_state, Data}
  end;

programado(cast, _Evento, Data) ->
  {keep_state, Data}.

%% ---- en_proceso --------------------------------------------------------------

en_proceso({call, From}, estado, Data) ->
  {keep_state_and_data, [{reply, From, {en_proceso, maps:get(envio_id, Data)}}]};

en_proceso(info, {p29_tick, N}, Data = #{tick_ejecutado := TickEj}) ->
  %% Verificar si el transbordo debe completarse (simplificado: 10 ticks)
  if
    N >= TickEj + 10 ->
      completar_transbordo(Data);
    true ->
      {keep_state, Data}
  end;

en_proceso(cast, _Evento, Data) ->
  {keep_state, Data}.

%% ---- completado / fallida (estados finales) ----------------------------------

completado({call, From}, estado, Data) ->
  {keep_state_and_data, [{reply, From, {completado, maps:get(envio_id, Data)}}]};

completado({call, From}, _Otro, Data) ->
  {keep_state, Data, [{reply, From, {error, estado_final}}]};

completado(cast, _Evento, Data) ->
  {keep_state, Data};

completado(info, _Evento, Data) ->
  {keep_state, Data}.

fallida({call, From}, estado, Data) ->
  {keep_state_and_data, [{reply, From, {fallida, maps:get(envio_id, Data)}}]};

fallida({call, From}, _Otro, Data) ->
  {keep_state, Data, [{reply, From, {error, estado_final}}]};

fallida(cast, _Evento, Data) ->
  {keep_state, Data};

fallida(info, _Evento, Data) ->
  {keep_state, Data}.

terminate(_Reason, _StateName, _Data) ->
  case whereis(p29_reloj) of
    undefined -> ok;
    _ -> gen_server:call(p29_reloj, {desuscribir, self()})
  end,
  ok.

%% ---- internos ----------------------------------------------------------------

iniciar_transbordo(Data) ->
  %% Notificar a despachador que inicie transbordo en el envio
  p29_despachador:ejecutar_transbordo(
    maps:get(envio_id, Data),
    maps:get(aeronave_destino, Data),
    maps:get(waypoint_transbordo, Data)
  ),
  %% Actualizar estado en ETS
  p29_datos:transbordo_upsert(Data#{estado => en_proceso}),
  {next_state, en_proceso, Data}.

completar_transbordo(Data) ->
  %% Notificar completado
  p29_despachador:transbordo_completado(maps:get(envio_id, Data)),
  p29_datos:transbordo_upsert(Data#{estado => completado}),
  {next_state, completado, Data}.