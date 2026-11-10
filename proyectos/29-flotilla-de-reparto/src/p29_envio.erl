-module(p29_envio).
-behaviour(gen_statem).

%% Un gen_statem por envio de carga aerea: la fuente de verdad del dominio
%% sobre cada paquete. Solo su propio proceso cambia su estado y su fila ETS;
%% el despachador pide asignar o devolver, pero nunca escribe la fila
%% directamente. Eso evita tener el mismo envio en dos aeronaves.
%%
%% Estados: pendiente -> en_ruta -> entregada | fallida | desviada | transbordo

-export([start_link/1, asignar/3, devolver/1, entregar/2, fallar/2,
         estado/1, transbordo/3]).
-export([init/1, callback_mode/0,
         pendiente/3, en_ruta/3, entregada/3, fallida/3, desviada/3, transbordo_state/3]).

%% Compat exports (for tests transition)
-export([asignar_compat/3, devolver_compat/1, entregar_compat/2,
         fallar_compat/2, estado_compat/1]).

start_link(Datos) ->
  gen_statem:start_link(?MODULE, Datos, []).

asignar(Pid, Aid, Tick) ->
  gen_statem:call(Pid, {asignar, Aid, Tick}).

devolver(Pid) ->
  gen_statem:call(Pid, devolver).

entregar(Pid, Tick) ->
  gen_statem:call(Pid, {entregar, Tick}).

fallar(Pid, Motivo) ->
  gen_statem:call(Pid, {fallar, Motivo}).

estado(Pid) ->
  gen_statem:call(Pid, estado).

%% Iniciar transbordo: mover envio a otra aeronave en waypoint intermedio
transbordo(Pid, NuevaAeronave, WaypointIATA) ->
  gen_statem:call(Pid, {transbordo, NuevaAeronave, WaypointIATA}).

%% ---- COMPAT: old function names for test transition --------------------------

asignar_compat(Pid, Vid, Tick) -> asignar(Pid, Vid, Tick).
devolver_compat(Pid) -> devolver(Pid).
entregar_compat(Pid, Tick) -> entregar(Pid, Tick).
fallar_compat(Pid, Motivo) -> fallar(Pid, Motivo).
estado_compat(Pid) -> estado(Pid).

callback_mode() ->
  [state_functions].

init(Datos) ->
  %% Datos esperados: #{id, peso_kg, tipo_carga, origen_iata, destino_iata,
  %%   ventana {Desde, Hasta}, urgente, ruta_id}
  p29_datos:envio_upsert(
    Datos#{estado => pendiente, aeronave => undefined, pid => self(),
           tick_asignado => undefined, tick_entregado => undefined,
           retraso => undefined, motivo => undefined,
           waypoint_actual => undefined, transbordo => false}),
  {ok, pendiente,
   Datos#{aeronave => undefined, tick_asignado => undefined,
          tick_entregado => undefined, retraso => undefined,
          motivo => undefined, waypoint_actual => undefined,
          transbordo => false}}.

%% ---- pendiente ---------------------------------------------------------------

pendiente({call, From}, {asignar, Aid, Tick}, Data) ->
  mapa_actualizar(maps:get(id, Data),
                  #{estado => en_ruta, aeronave => Aid, tick_asignado => Tick}),
  {next_state, en_ruta, Data#{aeronave := Aid, tick_asignado := Tick},
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
  mapa_actualizar(maps:get(id, Data), #{estado => pendiente, aeronave => undefined}),
  {next_state, pendiente, Data#{aeronave := undefined}, [{reply, From, ok}]};

en_ruta({call, From}, estado, Data) ->
  {keep_state_and_data, [{reply, From, {en_ruta, maps:get(aeronave, Data)}}]};

en_ruta({call, From}, {fallar, Motivo}, Data) ->
  mapa_actualizar(maps:get(id, Data), #{estado => fallida, motivo => Motivo}),
  {next_state, fallida, Data#{motivo := Motivo}, [{reply, From, ok}]};

en_ruta({call, From}, {asignar, _Aid, _Tick}, Data) ->
  %% Una entrega en ruta NO se reasigna sin pasar por pendiente
  {keep_state, Data, [{reply, From, {error, ya_en_ruta}}]};

en_ruta({call, From}, {transbordo, NuevaAeronave, WaypointIATA}, Data) ->
  %% Transbordo: cambiar de aeronave en waypoint intermedio
  mapa_actualizar(maps:get(id, Data),
                  #{estado => transbordo, aeronave => NuevaAeronave,
                    waypoint_actual => WaypointIATA, transbordo => true}),
  {next_state, transbordo_state, Data#{aeronave := NuevaAeronave,
                                         waypoint_actual := WaypointIATA,
                                         transbordo := true},
   [{reply, From, ok}]};

en_ruta({call, From}, Otro, Data) ->
  {keep_state, Data, [{reply, From, {error, {evento_no_valido, Otro, en_ruta}}}]};

en_ruta(cast, _Evento, Data) ->
  {keep_state_and_data, Data};

en_ruta(info, _Evento, Data) ->
  {keep_state_and_data, Data}.

%% ---- transbordo_state --------------------------------------------------------

transbordo_state({call, From}, {entregar, Tick}, Data = #{ventana := {_, Hasta}}) ->
  Retraso = erlang:max(0, Tick - Hasta),
  mapa_actualizar(maps:get(id, Data),
                  #{estado => entregada, tick_entregado => Tick, retraso => Retraso}),
  {next_state, entregada, Data#{tick_entregado := Tick, retraso := Retraso},
   [{reply, From, ok}]};

transbordo_state({call, From}, devolver, Data) ->
  mapa_actualizar(maps:get(id, Data), #{estado => pendiente, aeronave => undefined,
                                         transbordo => false}),
  {next_state, pendiente, Data#{aeronave := undefined, transbordo => false},
   [{reply, From, ok}]};

transbordo_state({call, From}, estado, Data) ->
  {keep_state_and_data, [{reply, From, {transbordo, maps:get(aeronave, Data)}}]};

transbordo_state({call, From}, {fallar, Motivo}, Data) ->
  mapa_actualizar(maps:get(id, Data), #{estado => fallida, motivo => Motivo}),
  {next_state, fallida, Data#{motivo := Motivo}, [{reply, From, ok}]};

transbordo_state({call, From}, Otro, Data) ->
  {keep_state, Data, [{reply, From, {error, {evento_no_valido, Otro, transbordo}}}]};

transbordo_state(cast, _Evento, Data) ->
  {keep_state_and_data, Data};

transbordo_state(info, _Evento, Data) ->
  {keep_state_and_data, Data}.

%% ---- entregada / fallida / desviada (estados finales) ------------------------

entregada({call, From}, estado, Data) ->
  {keep_state_and_data,
   [{reply, From, {entregada, maps:get(aeronave, Data, undefined)}}]};

entregada({call, From}, _Otro, Data) ->
  {keep_state, Data, [{reply, From, {error, estado_final}}]};

entregada(cast, _Evento, Data) ->
  {keep_state_and_data, Data};

entregada(info, _Evento, Data) ->
  {keep_state_and_data, Data}.

fallida({call, From}, estado, Data) ->
  {keep_state_and_data,
   [{reply, From, {fallida, maps:get(aeronave, Data, undefined)}}]};

fallida({call, From}, _Otro, Data) ->
  {keep_state, Data, [{reply, From, {error, estado_final}}]};

fallida(cast, _Evento, Data) ->
  {keep_state_and_data, Data};

fallida(info, _Evento, Data) ->
  {keep_state_and_data, Data}.

desviada({call, From}, estado, Data) ->
  {keep_state_and_data,
   [{reply, From, {desviada, maps:get(aeronave, Data, undefined)}}]};

desviada({call, From}, _Otro, Data) ->
  {keep_state, Data, [{reply, From, {error, estado_final}}]};

desviada(cast, _Evento, Data) ->
  {keep_state_and_data, Data};

desviada(info, _Evento, Data) ->
  {keep_state_and_data, Data}.

%% ---- utilerias ---------------------------------------------------------------

mapa_actualizar(Id, Cambios) ->
  case p29_datos:envio(Id) of
    undefined -> ok;
    Mapa -> p29_datos:envio_upsert(maps:merge(Mapa, Cambios))
  end.