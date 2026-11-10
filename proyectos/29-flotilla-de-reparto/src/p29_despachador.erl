-module(p29_despachador).
-behaviour(gen_server).

%% Gen_server despachador: asigna y reasigna entregas. Es SEPARADO del arbol de
%% vehiculos y entregas (criterio del docente): si una unidad muere, el
%% despachador sigue vivo y reasigna.
%%
%% Asignacion greedy first-fit (urgente primero, luego ventana mas proxima, y
%% entre unidades la de menor carga que pueda con el peso por capacidad), no un
%% VRP completo: el enunciado exige respuesta rapida sin recalcular todo el dia
%% (caso dificil 2).
%%
%% Respuesta a los casos dificiles del enunciado:
%%  - huerfanas/duplicadas: un solo proceso (gen_statem p29_entrega) es dueno de
%%    cada entrega; pasar entre unidades siempre por devolver -> pendiente ->
%%    asignar; invariantes/0 lo verifica en la prueba de caos.
%%  - buena y rapida vs perfecta y lenta: greedy en O(entregas x unidades).
%%  - senal perdida: los GPS llegan con el tick simulado de origen; un reporte
%%    con tick mas viejo que el ultimo se descarta (lote atrasado); el watchdog
%%    reasigna si la unidad deja de reportar sin_senal_ticks seguidos.

-export([start_link/0, tick/1, estado/0, reportar_gps/4, averiar/1, urgente/1,
         reasignar_pendientes/0, invariantes/0, eta/2, entrega/1, entregas_de/1,
         vehiculo_cargado/0, reasignaciones/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

%% Colonia -> coordenada {X, Y} en la rejilla 10x10 de la ciudad simulada.
-define(COLONIAS, [
  {centro, {2, 2}}, {zona_rio, {4, 1}}, {playas, {0, 7}},
  {la_presa, {7, 6}}, {sanchez_taboada, {5, 8}}, {cachanilla, {6, 3}},
  {lomas_anchura, {8, 7}}, {el_mirador, {7, 2}}, {villas_del_sol, {3, 9}},
  {la_mesa, {2, 6}}, {el_fortin, {1, 4}}, {satelito, {9, 1}},
  {otay, {9, 5}}, {el_florido, {8, 4}}, {ciudad_morelos, {1, 8}}
]).

%% ---- API ---------------------------------------------------------------------

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% impulsa un tick de forma sincrona (demo por inyeccion y tests)
tick(N) ->
  gen_server:call(?MODULE, {tick, N}).

estado() ->
  #{entregas => p29_datos:conteo_entregas(),
    vehiculos => p29_datos:conteo_vehiculos(),
    retraso_medio => retraso_medio(),
    reasignaciones => reasignaciones()}.

reasignaciones() ->
  gen_server:call(?MODULE, reasignaciones).

entrega(Id) ->
  p29_datos:entrega(Id).

entregas_de(Vid) ->
  p29_datos:entregas_de(Vid).

%% llamado por cada vehiculo en cada tick; Pid permite detectar reinicios
reportar_gps(Id, Pos, N, Pid) ->
  gen_server:cast(?MODULE, {gps, Id, Pos, N, Pid}).

%% averia explicita (inyeccion de fallo en demo y prueba de caos)
averiar(Vid) ->
  gen_server:call(?MODULE, {averiar, Vid}).

%% pedido urgente: crea la entrega y se asigna primero
urgente(Parcial) ->
  gen_server:call(?MODULE, {urgente, Parcial}).

reasignar_pendientes() ->
  gen_server:call(?MODULE, reasignar_pendientes).

%% ETA aproximada en ticks con congestion variable por tick (trafico simulado).
eta(Id, N) ->
  case p29_datos:entrega(Id) of
    undefined -> {error, no_existe};
    Entrega = #{ventana := {_, Hasta}} ->
      Base = calculo_eta(Entrega, N),
      RetrasoPrev = erlang:max(0, N + maps:get(eta_ticks, Base) - Hasta),
      {ok, maps:merge(Base, #{retraso_previsto => RetrasoPrev})}
  end.

%% ---- init y ciclo ------------------------------------------------------------

init([]) ->
  %% atrapa salidas: los enlaces de arranque directo (tests sin flota_sup) no
  %% deben matar al despachador cuando una unidad cae; la deteccion de muertes
  %% vive en los monitores ('DOWN'), no en los enlaces
  process_flag(trap_exit, true),
  p29_datos:ensure(),
  case whereis(p29_reloj) of
    undefined -> ok;
    _ -> gen_server:call(p29_reloj, {subscribe, self()})
  end,
  %% arranca la flota fuera del init: los demas hijos (flota_sup, entregas_sup)
  %% inician despues de que este init regresa; el mensaje entra cuando el arbol
  %% ya esta completo
  self() ! arrancar,
  {ok, #{vehiculos => #{}, monitores => #{}, reasignaciones => 0,
         tick => 0, arranque_asignado => false}}.

handle_call({tick, N}, _From, State) ->
  {reply, ok, procesar_tick(N, State)};
handle_call(reasignaciones, _From, State) ->
  {reply, maps:get(reasignaciones, State), State};
handle_call({averiar, Vid}, _From, State) ->
  case maps:find(Vid, maps:get(vehiculos, State)) of
    {ok, Pid} ->
      %% primero el dominio (reasignacion), al final la muerte del proceso:
      %% si se mata primero, el reinicio del supervisor entra en carrera
      State2 = manejar_caida(Vid, State),
      exit(Pid, averia),
      {reply, ok, State2};
    error ->
      {reply, {error, no_existe}, State}
  end;
handle_call({urgente, Parcial}, _From, State) ->
  Datos = datos_urgente(Parcial, maps:get(tick, State)),
  arrancar_entrega(Datos),
  State2 = reasignar_ahora(State),
  {reply, maps:get(id, Datos), State2};
handle_call(reasignar_pendientes, _From, State) ->
  State2 = reasignar_ahora(State),
  {reply, ok, State2};
handle_call(estado, _From, State) ->
  {reply, estado(), State};
handle_call(desconocido, _From, State) ->
  {reply, {error, desconocido}, State}.

handle_cast({gps, Id, Pos, N, Pid}, State) ->
  {noreply, procesar_gps(Id, Pos, N, Pid, State)};
handle_cast(desconocido, State) ->
  {noreply, State}.

handle_info(arrancar, State) ->
  {noreply, arrancar_flota(State)};
handle_info({'DOWN', _Ref, process, Pid, Motivo}, State) ->
  case vehiculo_por_pid(Pid, State) of
    undefined -> {noreply, State};
    Vid ->
      logger:info("vehiculo ~p caido (~p): reasignando cargas", [Vid, Motivo],
                  #{dominio => flotilla}),
      {noreply, manejar_caida(Vid, State)}
  end;
handle_info({p29_tick, N}, State) ->
  {noreply, procesar_tick(N, State)};
handle_info({'EXIT', _Pid, _Reason}, State) ->
  %% enlaces de arranque directo: la muerte ya la detecta el monitor 'DOWN'
  {noreply, State};
handle_info(_Msg, State) ->
  {noreply, State}.

%% ---- arranque de la flota ------------------------------------------------------

arrancar_flota(State) ->
  NVeh = application:get_env(p29_flotilla_de_reparto, vehiculos, 15),
  NEnt = application:get_env(p29_flotilla_de_reparto, entregas, 900),
  arrancar_flota(NVeh, NEnt, State).

arrancar_flota(NVeh, NEnt, State) ->
  Vehiculos = lists:foldl(
    fun(I, Acc) ->
        {Pid, Mon} = arrancar_vehiculo(I),
        Acc#{vehiculos := maps:put(I, Pid, maps:get(vehiculos, Acc)),
             monitores := maps:put(Mon, I, maps:get(monitores, Acc))}
    end, State, lists:seq(1, NVeh)),
  lists:foreach(fun(I) -> arrancar_entrega(datos_entrega(I)) end,
                lists:seq(1, NEnt)),
  case application:get_env(p29_flotilla_de_reparto, asignar_al_inicio, true) of
    true ->
      %% primera asignacion completa de la jornada (no cuenta como reasignacion)
      reasignar_ahora(Vehiculos);
    false ->
      Vehiculos
  end.

%% El mensaje arrancar puede llegar mientras el supervisor raiz aun no inicio
%% los supervisores dinamicos (van despues del despachador en rest_for_one):
%% si no hay sup, las unidades quedarian enlazadas a este proceso y NADIE las
%% relanzaria al morir. Espera-los antes de arrancar nada.
esperar_sup(_Nombre, 0) ->
  error;
esperar_sup(Nombre, Intentos) ->
  case whereis(Nombre) of
    undefined ->
      timer:sleep(10),
      esperar_sup(Nombre, Intentos - 1);
    Pid ->
      Pid
  end.

arrancar_vehiculo(I) ->
  Sup = esperar_sup(p29_flota_sup, 100),
  {ok, Pid} = supervisor:start_child(Sup, [I]),
  Mon = erlang:monitor(process, Pid),
  p29_datos:vehiculo_actualizar(I, #{pid => Pid}),
  {Pid, Mon}.

arrancar_entrega(Datos) ->
  Sup = esperar_sup(p29_entregas_sup, 100),
  supervisor:start_child(Sup, [Datos]),
  ok.

%% flota determinista erlang:phash2 (no rand): misma entrada -> misma corrida
datos_entrega(I) ->
  Peso = 5 + phash(I) rem 40,
  Colonia = colonia(phash(I) rem length(?COLONIAS)),
  Desde = 20 + (phash(I) rem 150),
  Hasta = Desde + 20 + (phash(I) rem 30),
  #{id => I, peso => Peso, colonia => Colonia, ventana => {Desde, Hasta},
    urgente => false}.

datos_urgente(Parcial, Tick) ->
  Id = p29_datos:proximo_id(),
  Base = #{id => Id, peso => 20, colonia => colonia(phash(Id) rem length(?COLONIAS)),
           ventana => {Tick, Tick + 60}, urgente => true},
  maps:merge(Base, maps:with([peso, colonia, ventana], Parcial)).

%% ---- progreso por tick -----------------------------------------------------------

procesar_tick(N, State) ->
  State1 = watchdog(N, State),
  completar_paradas(N),
  State1#{tick := N}.

%% detecta unidades caidas (proceso muerto) y unidades sin reportar
watchdog(N, State) ->
  SinSenalTicks = application:get_env(p29_flotilla_de_reparto, sin_senal_ticks, 6),
  lists:foldl(
    fun(Fila, Acc) ->
        case clasificar_unidad(Fila, N, SinSenalTicks) of
          caida -> manejar_caida(maps:get(id, Fila), Acc);
          senal_perdida -> sin_senal(maps:get(id, Fila), N, Acc);
          normal -> Acc
        end
    end, State, p29_datos:vehiculos_todas()).

clasificar_unidad(Fila, N, SinSenalTicks) ->
  Pid = maps:get(pid, Fila, undefined),
  Vivo = is_pid(Pid) andalso erlang:is_process_alive(Pid),
  Estado = maps:get(estado, Fila),
  Ultimo = maps:get(ultimo_reporte, Fila, undefined),
  SinReporte = not is_integer(Ultimo),
  if
    not Vivo andalso Estado =/= averiado -> caida;
    %% sin reporte inicial: la unidad apenas arranca, no es "senal perdida";
    %% si esta muerta la cubre la primera clausula
    SinReporte -> normal;
    Vivo andalso Estado =/= averiado andalso Estado =/= sin_senal
    andalso (N - Ultimo) >= SinSenalTicks -> senal_perdida;
    true -> normal
  end.

%% en cada "parada" la entrega mas antigua en ruta de la unidad termina:
%% entregada, o fallida por cliente ausente (5-15%; cfr. enunciado)
completar_paradas(N) ->
  case N rem application:get_env(p29_flotilla_de_reparto, ticks_por_parada, 36) =:= 0 of
    true -> completar_paradas_ahora(N);
    false -> ok
  end.

completar_paradas_ahora(N) ->
  Proba = application:get_env(p29_flotilla_de_reparto, prob_fallida, 0.10),
  lists:foreach(
    fun({Vid, [Primera | _Resto]}) ->
        Viva = vehiculo_vivo(Vid),
        if
          Viva ->
            Pid = maps:get(pid, Primera),
            case rand:uniform() < Proba of
              true -> p29_entrega:fallar(Pid, cliente_ausente);
              false -> p29_entrega:entregar(Pid, N)
            end;
          true -> ok
        end;
       ({_Vid, []}) -> ok
    end,
    entregas_en_ruta_por_vehiculo()).

%% ---- GPS -------------------------------------------------------------------------

procesar_gps(Id, Pos, N, Pid, State) ->
  case p29_datos:vehiculo(Id) of
    undefined -> State;
    Fila ->
      FilaPid = maps:get(pid, Fila, undefined),
      Ultimo = maps:get(ultimo_reporte, Fila, undefined),
      if
        is_integer(Ultimo) andalso N < Ultimo ->
          %% caso dificil 3: reporte de un lote atrasado; el mas nuevo manda
          State;
        FilaPid =:= Pid ->
          %% el mismo proceso reporta: si venia sin senal, el GPS la repone
          %% (solo averiado no se recupera: una averia fisica no se cura
          %% recibiendo datos)
          Recupera = maps:get(estado, Fila) =:= sin_senal,
          p29_datos:vehiculo_actualizar(
            Id, maps:merge(#{pos => Pos, ultimo_reporte => N},
                           case Recupera of
                             true -> #{estado => en_ruta};
                             false -> #{}
                           end)),
          case Recupera of
            true ->
              logger:info("vehiculo ~p recupera senal en tick ~p", [Id, N],
                          #{dominio => flotilla}),
              reasignar_ahora(State);
            false -> State
          end;
        true ->
          %% pid distinto: la supervision reanudo la unidad (recuperacion)
          logger:info("vehiculo ~p reiniciado y reportando de nuevo", [Id],
                      #{dominio => flotilla}),
          p29_datos:vehiculo_actualizar(
            Id, #{pos => Pos, ultimo_reporte => N, pid => Pid, estado => en_ruta}),
          registrar_reinicio(Id, Pid, State)
      end
  end.

%% ---- caidas y senal ----------------------------------------------------------------

manejar_caida(Vid, State) ->
  p29_datos:vehiculo_actualizar(Vid, #{estado => averiado}),
  devolver_todas(Vid),
  reasignar_ahora(State).

sin_senal(Vid, N, State) ->
  logger:info("vehiculo ~p sin senal >= ~p ticks: reasignando cargas",
              [Vid, N], #{dominio => flotilla}),
  p29_datos:vehiculo_actualizar(Vid, #{estado => sin_senal}),
  devolver_todas(Vid),
  reasignar_ahora(State).

devolver_todas(Vid) ->
  lists:foreach(
    fun(Entrega) ->
        Pid = maps:get(pid, Entrega, undefined),
        case maps:get(estado, Entrega) =:= en_ruta
             andalso is_pid(Pid) andalso erlang:is_process_alive(Pid) of
          true -> p29_entrega:devolver(Pid);
          false -> ok
        end
    end, p29_datos:entregas_de(Vid)).

%% ---- asignacion (greedy first-fit) ---------------------------------------------------

reasignar_ahora(State = #{reasignaciones := Cont, arranque_asignado := Arrancado}) ->
  Tipo = case Arrancado of false -> inicial; true -> reasignacion end,
  Cargas = cargas_map(),
  Pendientes = lists:sort(fun menor_prioridad/2,
                          p29_datos:entregas_por_estado(pendiente)),
  TickAsignacion = maps:get(tick, State),
  {Cont2, _CargasFin} =
    lists:foldl(
      fun(Entrega, {Acc, CargasAcc}) ->
          {Delta, CargasAcc2} =
            case buscar_cupo(Entrega, CargasAcc) of
              undefined ->
                p29_entrega:fallar(pid_de(Entrega), sin_cupo),
                {0, CargasAcc};
              Vid ->
                p29_entrega:asignar(pid_de(Entrega), Vid, TickAsignacion),
                CargasAccN = maps:update_with(
                  Vid, fun(N) -> N + peso_de(Entrega) end,
                  peso_de(Entrega), CargasAcc),
                {1, CargasAccN}
            end,
          case Tipo of
            reasignacion -> {Acc + Delta, CargasAcc2};
            inicial -> {Acc, CargasAcc2}
          end
      end, {Cont, Cargas}, Pendientes),
  State#{reasignaciones := Cont2, arranque_asignado := true}.

%% unidad con MENOR carga actual que quepa por capacidad: buen y barato,
%% no optimo (justificado: el despachador no recalcula todo el dia)
buscar_cupo(Entrega, Cargas) ->
  Peso = peso_de(Entrega),
  Candidatos = [ {carga_vid(Vid, Cargas), Fila}
                 || Fila = #{id := Vid} <- p29_datos:vehiculos_todas(),
                    vehiculo_vivo_id(Fila),
                    maps:get(estado, Fila) =:= en_ruta ],
  Ajustados = [ {Carga, Vid} || {Carga, #{id := Vid, capacidad := Cap}} <- Candidatos,
                                Carga + Peso =< Cap ],
  case lists:sort(Ajustados) of
    [] -> undefined;
    [{_CargaMinima, Vid} | _] -> Vid
  end.

%% ---- utilidades de flota --------------------------------------------------------------

vehiculo_vivo_id(Fila) ->
  Pid = maps:get(pid, Fila, undefined),
  is_pid(Pid) andalso erlang:is_process_alive(Pid).

vehiculo_vivo(Vid) ->
  case p29_datos:vehiculo(Vid) of
    undefined -> false;
    Fila -> vehiculo_vivo_id(Fila)
  end.

pid_de(Entrega) ->
  maps:get(pid, Entrega).

peso_de(Entrega) ->
  maps:get(peso, Entrega, 0).

carga_vid(Vid, Cargas) ->
  maps:get(Vid, Cargas, 0).

%% carga real de una unidad = suma de pesos de sus entregas en_ruta (dato
%% derivado: un reinicio no puede mentir sobre lo que lleva a bordo)
cargas_map() ->
  lists:foldl(
    fun(Entrega, Acc) ->
        case maps:get(estado, Entrega) of
          en_ruta ->
            Vid = maps:get(vehiculo, Entrega, undefined),
            maps:update_with(Vid, fun(N) -> N + peso_de(Entrega) end,
                             peso_de(Entrega), Acc);
          _ -> Acc
        end
    end, maps:new(), p29_datos:entregas_todas()).

%% carga real de una unidad individual (dato derivado de las entregas en ruta)
carga_de(Vid) ->
  case maps:find(Vid, cargas_map()) of
    {ok, Carga} -> Carga;
    error -> 0
  end.

%% entregas en ruta agrupadas por unidad, ordenadas por id (mas vieja primero)
entregas_en_ruta_por_vehiculo() ->
  Agrupadas =
    lists:foldl(
      fun(Entrega, Acc) ->
          case maps:get(estado, Entrega) of
            en_ruta ->
              Vid = maps:get(vehiculo, Entrega, undefined),
              maps:update_with(Vid, fun(Lista) -> [Entrega | Lista] end,
                               [Entrega], Acc);
            _ -> Acc
          end
      end, maps:new(), p29_datos:entregas_todas()),
  [{Vid, lists:sort(fun menor_id/2, Lista)}
   || {Vid, Lista} <- maps:to_list(Agrupadas)].

%% ---- resumen, metricas e invariantes ---------------------------------------------------

retraso_medio() ->
  Retrasos = [maps:get(retraso, E, 0) || E <- p29_datos:entregas_todas(),
                                         maps:get(estado, E) =:= entregada],
  case Retrasos of
    [] -> 0;
    _ -> lists:sum(Retrasos) / length(Retrasos)
  end.

%% permalink sobre el dominio: lista vacia significa flota consistente
invariantes() ->
  Huerfanas = [Id || E = #{id := Id} <- p29_datos:entregas_todas(),
                     maps:get(estado, E) =:= pendiente,
                     maps:get(vehiculo, E, undefined) =/= undefined],
  SinVehiculo = [Id || E = #{id := Id} <- p29_datos:entregas_todas(),
                       maps:get(estado, E) =:= en_ruta,
                       maps:get(vehiculo, E, undefined) =:= undefined],
  VehiculoMuerto = [Id || E = #{id := Id, vehiculo := Vid}
                            <- p29_datos:entregas_todas(),
                          maps:get(estado, E) =:= en_ruta,
                          not vehiculo_vivo(Vid)],
  case Huerfanas ++ SinVehiculo ++ VehiculoMuerto of
    [] -> ok;
    Viola -> {error, Viola}
  end.

vehiculo_cargado() ->
  case p29_datos:vehiculos_todas() of
    [] -> undefined;
    _ ->
      [{_Carga, Vid} | _] =
        lists:reverse(
          lists:sort([{carga_de(Vid), Vid}
                      || #{id := Vid} <- p29_datos:vehiculos_todas()])),
      Vid
  end.

%% ---- helpers ---------------------------------------------------------------------------

phash(T) ->
  erlang:phash2(T, 65536).

colonia(Index) ->
  element(1, lists:nth(Index + 1, ?COLONIAS)).

calculo_eta(Entrega, N) ->
  {CX, CY} = coord_colonia(maps:get(colonia, Entrega, centro)),
  Pos = case vehicle_pos(maps:get(vehiculo, Entrega, undefined)) of
          undefined -> {0, 0};
          P -> P
        end,
  Dist = manhattan(Pos, {CX, CY}),
  Cong = 1 + 0.20 * (N rem 5),  %% congestion variable por tick (trafico simulado)
  #{eta_ticks => ceil(Dist * Cong), dist_rejilla => Dist, congestion => Cong}.

coord_colonia(C) ->
  {_, Pos} = lists:keyfind(C, 1, ?COLONIAS),
  Pos.

vehicle_pos(Vid) ->
  case p29_datos:vehiculo(Vid) of
    undefined -> undefined;
    Fila -> maps:get(pos, Fila, {0, 0})
  end.

manhattan({X1, Y1}, {X2, Y2}) ->
  erlang:abs(X2 - X1) + erlang:abs(Y2 - Y1).

vehiculo_por_pid(Pid, State) ->
  case lists:keyfind(Pid, 1, maps:to_list(maps:get(vehiculos, State))) of
    {Vid, _} -> Vid;
    false -> undefined
  end.

%% el proceso viejo esta muerto: quita su monitor y vigila el nuevo (el del
%% supervisor) para volver a detectar la siguiente caida del mismo vehiculo
registrar_reinicio(Id, Pid, State = #{monitores := Monitores, vehiculos := Veh}) ->
  Monitores2 = maps:filter(fun(_Ref, V) -> V =/= Id end, Monitores),
  Ref = erlang:monitor(process, Pid),
  State#{vehiculos := maps:put(Id, Pid, Veh),
         monitores := maps:put(Ref, Id, Monitores2)}.

%% orden de la cola de asignacion: urgente primero; el resto por ventana mas
%% proxima (desde) y luego por id, para que la corrida sea reproducible
menor_prioridad(A, B) ->
  ClaveA = {not maps:get(urgente, A, false), desde(maps:get(ventana, A, {0, 0})),
            maps:get(id, A)},
  ClaveB = {not maps:get(urgente, B, false), desde(maps:get(ventana, B, {0, 0})),
            maps:get(id, B)},
  ClaveA =< ClaveB.

menor_id(A, B) ->
  maps:get(id, A) =< maps:get(id, B).

desde({Desde, _Hasta}) -> Desde.
