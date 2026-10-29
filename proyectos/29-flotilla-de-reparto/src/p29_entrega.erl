-module(p29_entrega).
-behaviour(gen_statem).

%% Un gen_statem por entrega: la fuente de verdad del dominio sobre cada paquete.
%% Solo su propio proceso cambia su estado y su fila ETS; el despachador pede
%% asignar o devolver, pero nunca escribe la fila directamente. Eso es lo que
%% hace imposible tener la misma entrega en dos unidades (caso dificil 1).

-export([start_link/1, asignar/3, devolver/1, entregar/2, fallar/2, estado/1]).
-export([init/1, callback_mode/0,
         pendiente/3, en_ruta/3, entregada/3, fallida/3]).

start_link(Datos) ->
  gen_statem:start_link(?MODULE, Datos, []).

asignar(Pid, Vid, Tick) ->
  gen_statem:call(Pid, {asignar, Vid, Tick}).

devolver(Pid) ->
  gen_statem:call(Pid, devolver).

entregar(Pid, Tick) ->
  gen_statem:call(Pid, {entregar, Tick}).

fallar(Pid, Motivo) ->
  gen_statem:call(Pid, {fallar, Motivo}).

estado(Pid) ->
  gen_statem:call(Pid, estado).

callback_mode() ->
  [state_functions].

init(Datos) ->
  p29_datos:entrega_upsert(
    Datos#{estado => pendiente, vehiculo => undefined, pid => self(),
           tick_asignado => undefined, tick_entregado => undefined,
           retraso => undefined, motivo => undefined}),
  %% siembra los campos que mutan en la corrida para que el patron `:=`
  %% nunca falle (los datos de arranque no los traen)
  {ok, pendiente,
   Datos#{vehiculo => undefined, tick_asignado => undefined,
          tick_entregado => undefined, retraso => undefined,
          motivo => undefined}}.

%% ---- pendiente ---------------------------------------------------------------

pendiente({call, From}, {asignar, Vid, Tick}, Data) ->
  mapa_actualizar(maps:get(id, Data),
                  #{estado => en_ruta, vehiculo => Vid, tick_asignado => Tick}),
  {next_state, en_ruta, Data#{vehiculo := Vid, tick_asignado := Tick},
   [{reply, From, ok}]};
pendiente({call, From}, estado, _Data) ->
  {keep_state_and_data, [{reply, From, {pendiente, undefined}}]};
pendiente({call, From}, {fallar, Motivo}, Data) ->
  mapa_actualizar(maps:get(id, Data), #{estado => fallida, motivo => Motivo}),
  {next_state, fallida, Data#{motivo := Motivo}, [{reply, From, ok}]};
pendiente({call, From}, Otro, Data) ->
  {keep_state, Data, [{reply, From, {error, {evento_no_valido, Otro, pendiente}}}]};
pendiente(cast, _Evento, Data) ->
  {keep_state_and_data, Data};
pendiente(info, _Evento, Data) ->
  {keep_state_and_data, Data}.

%% ---- en_ruta -----------------------------------------------------------------

en_ruta({call, From}, {entregar, Tick}, Data = #{ventana := {_, Hasta}}) ->
  Retraso = erlang:max(0, Tick - Hasta),
  mapa_actualizar(maps:get(id, Data),
                  #{estado => entregada, tick_entregado => Tick, retraso => Retraso}),
  {next_state, entregada, Data#{tick_entregado := Tick, retraso := Retraso},
   [{reply, From, ok}]};
en_ruta({call, From}, devolver, Data) ->
  mapa_actualizar(maps:get(id, Data), #{estado => pendiente, vehiculo => undefined}),
  {next_state, pendiente, Data#{vehiculo := undefined}, [{reply, From, ok}]};
en_ruta({call, From}, estado, Data) ->
  {keep_state_and_data, [{reply, From, {en_ruta, maps:get(vehiculo, Data)}}]};
en_ruta({call, From}, {fallar, Motivo}, Data) ->
  mapa_actualizar(maps:get(id, Data), #{estado => fallida, motivo => Motivo}),
  {next_state, fallida, Data#{motivo := Motivo}, [{reply, From, ok}]};
en_ruta({call, From}, {asignar, _Vid, _Tick}, Data) ->
  %% rechazado a conciencia: una entrega en ruta NO se reasigna sin pasar por
  %% pendiente; el despachador debe usar devolver + asignar
  {keep_state, Data, [{reply, From, {error, ya_en_ruta}}]};
en_ruta({call, From}, Otro, Data) ->
  {keep_state, Data, [{reply, From, {error, {evento_no_valido, Otro, en_ruta}}}]};
en_ruta(cast, _Evento, Data) ->
  {keep_state_and_data, Data};
en_ruta(info, _Evento, Data) ->
  {keep_state_and_data, Data}.

%% ---- entregada / fallida (estados finales) -----------------------------------

entregada({call, From}, estado, Data) ->
  {keep_state_and_data,
   [{reply, From, {entregada, maps:get(vehiculo, Data, undefined)}}]};
entregada({call, From}, _Otro, Data) ->
  {keep_state, Data, [{reply, From, {error, estado_final}}]};
entregada(cast, _Evento, Data) ->
  {keep_state_and_data, Data};
entregada(info, _Evento, Data) ->
  {keep_state_and_data, Data}.

fallida({call, From}, estado, Data) ->
  {keep_state_and_data,
   [{reply, From, {fallida, maps:get(vehiculo, Data, undefined)}}]};
fallida({call, From}, _Otro, Data) ->
  {keep_state, Data, [{reply, From, {error, estado_final}}]};
fallida(cast, _Evento, Data) ->
  {keep_state_and_data, Data};
fallida(info, _Evento, Data) ->
  {keep_state_and_data, Data}.

mapa_actualizar(Id, Cambios) ->
  case p29_datos:entrega(Id) of
    undefined -> ok;
    Mapa -> p29_datos:entrega_upsert(maps:merge(Mapa, Cambios))
  end.
