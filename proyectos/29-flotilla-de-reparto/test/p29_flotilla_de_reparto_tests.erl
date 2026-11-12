-module(p29_flotilla_de_reparto_tests).
-include_lib("eunit/include/eunit.hrl").

%% OTP <= 26: thoas devuelve {ok, Termino}; normalizar a Termino seco.
decodificar(Bin) ->
  {ok, Termino} = thoas:decode(Bin),
  Termino.
%% Suite del proyecto #29 - AeroCargo. Cada escenario arranca su propio arbol de
%% supervision con envs pequenos (2 aeronaves, 12 envios) y reloj
%% MANUAL (reloj_auto false) para corridas deterministas y rapidas.

-define(APP, p29_flotilla_de_reparto).

%% ---- infraestructura de escenarios ------------------------------------------

arrancar(EnvsExtra) ->
  lists:foreach(
    fun({K, V}) -> application:set_env(?APP, K, V) end,
    [
     {aeronaves, 2}, {envios, 12}, {reloj_auto, false},
     {tick_interval_ms, 3600000}, {prob_fallida, 0.0}, {prob_desvio, 0.0},
     {sin_senal_ticks, 100}, {ticks_por_parada, 999999},
     {flota_uniforme_kg, 6000}, {asignar_al_inicio, true},
     %% web en puerto efimero: cada escenario levanta su propio cowboy
     {web_port, 0}
    ] ++ EnvsExtra),
  {ok, Pid} = p29_flotilla_de_reparto_sup:start_link(),
  esperar(fun() -> length(p29_datos:aeronaves_todas()) =:= 2 end),
  esperar(fun() -> length(p29_datos:envios_todos()) =:= 12 end),
  Pid.

cerrar(Pid) ->
  unlink(Pid),
  exit(Pid, shutdown),
  %% espera a que el supervisor y todos sus hijos terminen completamente
  esperar(fun() -> not is_process_alive(Pid) end),
  %% garantiza que las tablas ETS del escenario anterior mueren antes del siguiente
  esperar(fun() -> whereis(p29_datos) =:= undefined end),
  %% asegura que el reloj manual del test anterior se pare
  esperar(fun() -> whereis(p29_reloj) =:= undefined end, 2000).

%% polling con deadline real: el presupuesto se mide en tiempo de pared
%% (erlang:monotonic_time), no en iteraciones, para que un predicado que
%% duerme o tarda no convierta un timeout de 15 s en uno de minutos.
%% (Tests: permitido; el dominio sigue usando solo p29_reloj.)
esperar(Fun) -> esperar(Fun, 2000).
esperar(Fun, TimeoutMs) ->
  Fin = erlang:monotonic_time(millisecond) + TimeoutMs,
  esperar_hasta(Fun, Fin).
esperar_hasta(Fun, Fin) ->
  case Fun() of
    true -> ok;
    false ->
      Restante = Fin - erlang:monotonic_time(millisecond),
      case Restante =< 0 of
        true -> timeout;
        false ->
          timer:sleep(erlang:min(10, Restante)),
          esperar_hasta(Fun, Fin)
      end
  end.

esperar_asignadas(Total) ->
  esperar(fun() ->
              length(p29_datos:envios_por_estado(en_ruta)) =:= Total
          end).

%% colector de eventos SSE para los tests del difusor: cuenta los
%% {p29_estado, _, _} que le llegan sin bloquear el mailbox del test.
%% OJO: spawn/1 exige fun de aridad 0; el contador va en bucle/1.
colector() ->
  spawn(fun() -> bucle_colector(0) end).

bucle_colector(K) ->
  receive
    {p29_estado, _, _} -> bucle_colector(K + 1);
    {consulta, From} -> From ! {conteo, K}, bucle_colector(K);
    stop -> ok
  end.

conteo(Colector) ->
  Colector ! {consulta, self()},
  receive
    {conteo, K} -> K
  end.

%% ---- 1. arbol, arranque e invariantes ------------------------------------------

arbol_despues_de_arrancar_test_() ->
  {setup,
   fun() ->
       Pid = arrancar([]),
       esperar_asignadas(12),
       Pid
   end,
   fun cerrar/1,
   fun(_) ->
     [
      ?_test(begin
                Estado = p29_despachador:estado(),
                Envios = maps:get(envios, Estado),
                Aeronaves = maps:get(aeronaves, Estado),
                ?assertEqual(12, maps:get(en_ruta, Envios, 0)),
                ?assertEqual(0, maps:get(pendiente, Envios, 0)),
                ?assertEqual(2, maps:get(en_ruta, Aeronaves, 0))
              end)
     ]
   end}.

%% ---- 2. asignacion inicial greedy y capacidad ----------------------------------

asignacion_inicial_test_() ->
  {setup,
   fun() ->
       Pid = arrancar([]),
       esperar_asignadas(12),
       Pid
   end,
   fun cerrar/1,
   fun(_) ->
     [
      ?_test(begin
                Aeronaves = lists:usort(
                             [maps:get(aeronave, E)
                              || E <- p29_datos:envios_todos()]),
                ?assertEqual([1, 2], lists:sort(Aeronaves)),
                lists:foreach(
                  fun(Aid) ->
                      Carga = lists:sum(
                                [maps:get(peso_kg, E)
                                 || E <- p29_despachador:envios_de(Aid)]),
                      Row = p29_datos:aeronave(Aid),
                      ?assert(Carga =< maps:get(capacidad, Row))
                  end, [1, 2]),
                ?assertEqual(ok, p29_despachador:invariantes())
              end)
     ]
   end}.

%% ---- 3. gen_statem de envio: transiciones ------------------------------------

envio_statem_test_() ->
  {setup,
   fun() ->
       PidSup = arrancar([{asignar_al_inicio, false}]),
       esperar(fun() -> length(p29_datos:envios_por_estado(pendiente))
                             =:= 12 end),
       PidSup
   end,
   fun cerrar/1,
   fun(_) ->
     [
      ?_test(begin
                PidE1 = maps:get(pid, p29_despachador:envio(1)),
                ?assertEqual({pendiente, undefined}, p29_envio:estado(PidE1)),
                ?assertEqual(ok, p29_envio:asignar(PidE1, 1, 5)),
                ?assertEqual({en_ruta, 1}, p29_envio:estado(PidE1)),
                %% rechaza asignacion sin devolver antes: no duplica dueno
                ?assertEqual({error, ya_en_ruta},
                             p29_envio:asignar(PidE1, 2, 6)),
                ?assertEqual(ok, p29_envio:entregar(PidE1, 10)),
                ?assertEqual({entregada, 1}, p29_envio:estado(PidE1)),
                ?assertEqual({error, estado_final},
                             p29_envio:fallar(PidE1, cliente_ausente))
              end),
      ?_test(begin
                PidE2 = maps:get(pid, p29_despachador:envio(2)),
                %% devolver desde pendiente no es una transicion valida
                ?assertEqual({error, {evento_no_valido, devolver, pendiente}},
                             p29_envio:devolver(PidE2))
              end)
     ]
   end}.

%% ---- 4. averia: la carga de la aeronave caida pasa a la sana ----------------------

averia_reasignacion_test_() ->
  {setup,
   fun() ->
       PidSup = arrancar([]),
       esperar_asignadas(12),
       PidSup
   end,
   fun cerrar/1,
   fun(_) ->
     [
      ?_test(begin
                EnV1 = length(p29_despachador:envios_de(1)),
                ?assertNotEqual(0, EnV1),
                ?assertEqual(ok, p29_despachador:averiar(1)),
                ?assertEqual(averiado,
                             maps:get(estado, p29_datos:aeronave(1))),
                ?assertEqual([], p29_despachador:envios_de(1)),
                ?assertEqual(12, length(p29_despachador:envios_de(2))),
                ?assertEqual(EnV1, p29_despachador:reasignaciones()),
                ?assertEqual(ok, p29_despachador:invariantes())
              end)
     ]
   end}.

%% ---- 5. sin senal (watchdog ADS-B) y lote de reportes atrasado ------------------------

sin_senal_y_lote_atrasado_test_() ->
  {setup,
   fun() ->
       PidSup = arrancar([{sin_senal_ticks, 3}]),
       esperar_asignadas(12),
       PidSup
   end,
   fun cerrar/1,
   fun(_) ->
     [
      ?_test(begin
                %% impulsa via reloj para que AMBAS aeronaves reporten ADS-B;
                %% 30 ms entre ticks dejan procesar los ADS-B (sin carreras)
                ?assertEqual(1, p29_reloj:tick()),
                timer:sleep(30),
                PidAer2 = maps:get(pid, p29_datos:aeronave(2)),
                C2 = length(p29_despachador:envios_de(2)),
                ?assertNotEqual(0, C2),
                %% la aeronave 2 pierde senal: deja de recibir ticks
                ?assertEqual(ok, p29_reloj:desuscribir(PidAer2)),
                %% reloj: 2..4: el ultimo ADS-B de la aeronave 2 fue el tick 1:
                %% al tick 4 (4-1 >= 3) el watchdog la marca y reasigna
                ?assertEqual(2, p29_reloj:tick()),
                timer:sleep(30),
                ?assertEqual(3, p29_reloj:tick()),
                timer:sleep(30),
                ?assertEqual(4, p29_reloj:tick()),
                timer:sleep(30),
                esperar(fun() ->
                            maps:get(estado, p29_datos:aeronave(2))
                            =:= sin_senal
                        end),
                ?assertEqual(sin_senal,
                             maps:get(estado, p29_datos:aeronave(2))),
                ?assertEqual([], p29_despachador:envios_de(2)),
                ?assertEqual(C2, p29_despachador:reasignaciones()),
                ?assertEqual(ok, p29_despachador:invariantes())
              end),
      ?_test(begin
                %% caso dificil 3: reporte con tick atrasado se descarta
                PidAeronave = maps:get(pid, p29_datos:aeronave(1)),
                p29_despachador:reportar_adsb(1, {19.4363, -99.0721}, 250, 400, 100.0, 5000, 10, PidAeronave),
                p29_despachador:reportar_adsb(1, {19.5000, -99.1000}, 250, 400, 99.9, 5000, 5, PidAeronave),
                esperar(fun() ->
                            maps:get(pos, p29_datos:aeronave(1), none)
                            =:= {19.4363, -99.0721}
                        end),
                Fila = p29_datos:aeronave(1),
                ?assertEqual({19.4363, -99.0721}, maps:get(pos, Fila)),
                ?assertEqual(10, maps:get(tick_ultimo_reporte, Fila))
              end),
      ?_test(begin
                %% regresion: adsb_ultimo/1 devuelve el reporte de mayor tick
                %% (antes usaba lists:max/2, inexistente, y un match spec de
                %% 3 tuplas contra una tabla de 2)
                true = p29_datos:adsb_upsert(#{icao24 => <<"ABC123">>,
                                               callsign => <<"AC1">>,
                                               aeronave_id => 1, tick => 5,
                                               pos => {1.0, 2.0}}),
                true = p29_datos:adsb_upsert(#{icao24 => <<"ABC123">>,
                                               callsign => <<"AC1">>,
                                               aeronave_id => 1, tick => 9,
                                               pos => {3.0, 4.0}}),
                true = p29_datos:adsb_upsert(#{icao24 => <<"XYZ789">>,
                                               callsign => <<"AC2">>,
                                               aeronave_id => 2, tick => 7,
                                               pos => {5.0, 6.0}}),
                Ultimo1 = p29_datos:adsb_ultimo(1),
                ?assertEqual(9, maps:get(tick, Ultimo1)),
                ?assertEqual({3.0, 4.0}, maps:get(pos, Ultimo1)),
                ?assertEqual(7, maps:get(tick, p29_datos:adsb_ultimo(2))),
                ?assertEqual(undefined, p29_datos:adsb_ultimo(99))
              end)
     ]
   end}.

%% ---- 6. recuperacion: la supervision relanza la aeronave --------------------------

recuperacion_tras_averia_test_() ->
  {timeout, 60,
  {setup,
   fun() ->
       %% asegura limpieza completa de cualquier test anterior
       esperar(fun() -> whereis(p29_datos) =:= undefined end, 5000),
       esperar(fun() -> whereis(p29_reloj) =:= undefined end, 5000),
       PidSup = arrancar([]),
       esperar_asignadas(12),
       PidSup
   end,
   fun cerrar/1,
   fun(_) ->
     [
      ?_test(begin
                ?assertEqual(ok, p29_despachador:averiar(1)),
                PidViejo = maps:get(pid, p29_datos:aeronave(1)),
                %% el supervisor relanza la aeronave: su init repone el pid
                %% nuevo en ETS. Los envios de la caida ya los lleva la sana
                %% (manejar_caida reasigna), asi que no hay pendientes que la
                %% reactiven: la repuesta queda en_tierra hasta que el
                %% despachador le asigna carga nueva.
                ?assertEqual(ok,
                             esperar(fun() ->
                                         maps:get(pid, p29_datos:aeronave(1),
                                                  undefined)
                                             =/= PidViejo
                                     end, 15000)),
                Id = p29_despachador:urgente(
                       #{peso_kg => 40, origen_iata => <<"MEX">>,
                         destino_iata => <<"BOG">>}),
                %% en_tierra cuenta como disponible: el urgente la levanta
                esperar(fun() ->
                            maps:get(estado, p29_datos:aeronave(1),
                                     undefined) =:= en_ruta
                        end),
                Row = p29_datos:aeronave(1),
                ?assertEqual(en_ruta, maps:get(estado, Row)),
                ?assert(is_pid(maps:get(pid, Row))),
                ?assertEqual(en_ruta,
                             maps:get(estado, p29_despachador:envio(Id))),
                ?assertEqual(ok, p29_despachador:invariantes())
              end)
     ]
   end}}.

%% ---- 7. pedido urgente / AOG ----------------------------------------------------------

urgente_test_() ->
  {setup,
   fun() ->
       PidSup = arrancar([]),
       esperar_asignadas(12),
       PidSup
   end,
   fun cerrar/1,
   fun(_) ->
     [
      ?_test(begin
                Id = p29_despachador:urgente(#{peso_kg => 40, origen_iata => <<"MEX">>, destino_iata => <<"BOG">>}),
                Urgente = p29_despachador:envio(Id),
                ?assertEqual(true, maps:get(urgente, Urgente)),
                ?assertEqual(en_ruta, maps:get(estado, Urgente)),
                ?assert(is_integer(maps:get(aeronave, Urgente))),
                ?assertEqual(ok, p29_despachador:invariantes())
              end)
     ]
   end}.

%% ---- 8. mini-jornada del enunciado con averia y urgente --------------------------

%% Escenario AeroCargo en miniatura: jornada de 40 ticks (con reloj
%% automatico acelerado), averia al ~46% de la jornada y pedido urgente al 75%.
%% Con prob_fallida y prob_desvio 0 (env del helper) el resultado final es
%% exacto: 12 envios + 1 urgente = 13 entregados, 0 pendientes, 0 fallidos.
%% La jornada es de 40 y no 30 ticks: cada parada entrega 1 envio por
%% aeronave, y desde la averia (~46%) vuela una sola. Con 30 los huecos de
%% entrega tras la averia salian justos (filo) y la demo quedaba a 12/13.
simulador_test_() ->
  {setup,
   fun() ->
       Sup = arrancar([{reloj_auto, true}, {tick_interval_ms, 3},
                       {ticks_jornada, 40}, {ticks_por_parada, 3},
                       {sin_senal_ticks, 6}]),
       esperar_asignadas(12),
       PidSim = p29_simulador:demo(),
       {Sup, PidSim}
   end,
   fun({SupPid, _PidSim}) ->
       cerrar(SupPid)
   end,
   fun({_Sup, PidSim}) ->
      [
       ?_test(begin
                 %% la demo debe terminar sola al cerrar la jornada; polling
                 %% de vida en vez de receive (robusto ante mensajes ajenos
                 %% en el mailbox del proceso de prueba)
                 esperar(fun() -> not erlang:is_process_alive(PidSim) end, 6000),
                 %% margen para que el ultimo tick procese en el despachador
                 esperar(fun() ->
                             maps:get(entregada, p29_datos:conteo_envios(), 0)
                             =:= 13
                         end, 2000),
                 Estado = p29_despachador:estado(),
                 Envios = maps:get(envios, Estado),
                 ?assertEqual(13, maps:get(entregada, Envios, 0)),
                 ?assertEqual(0, maps:get(pendiente, Envios, 0)),
                 ?assertEqual(0, maps:get(en_ruta, Envios, 0)),
                 ?assertEqual(0, maps:get(fallida, Envios, 0)),
                 ?assertEqual(ok, p29_despachador:invariantes())
               end)
      ]
   end}.

%% ---- 8b. cadencia SSE tras la jornada --------------------------------------------

%% El difusor no puede seguir a 30 Hz eternos: tras el fin de la jornada la
%% flota ya no cambia y el SSE solo necesita un latido (~1 s real, 30 ticks).
%% La demo registra su jornada [T0, Fin) en el difusor con una llamada
%% sincrona, asi el test por ticks manuales es determinista.
sse_estrangulado_tras_jornada_test_() ->
  {setup,
   fun() ->
       Sup = arrancar([{reloj_auto, false}, {ticks_jornada, 5},
                       {ticks_por_parada, 999999}, {sin_senal_ticks, 100}]),
       esperar_asignadas(12),
       Colector = colector(),
       ok = p29_broadcaster:subscribe(Colector),
       {Sup, Colector}
   end,
   fun({SupPid, Colector}) ->
       p29_broadcaster:desuscribir(Colector),
       Colector ! stop,
       cerrar(SupPid)
   end,
   fun({_Sup, Colector}) ->
      [
       ?_test(begin
                  %% la demo registra su jornada en el difusor (llamada
                  %% sincrona): T0 = tick actual, Fin = T0 + ticks_jornada
                  _ = p29_simulador:demo(),
                  esperar(fun() ->
                              p29_broadcaster:jornada_actual() =/= undefined
                          end, 2000),
                  {T0, Fin} = p29_broadcaster:jornada_actual(),
                  %% dentro de la jornada: un evento por tick
                  _ = [p29_reloj:tick() || _ <- lists:seq(T0 + 1, Fin)],
                  timer:sleep(100),
                  ?assertEqual(Fin - T0, conteo(Colector)),
                  %% 25 ticks tras la jornada: nada (la cadencia idle es de 30)
                  _ = [p29_reloj:tick() || _ <- lists:seq(Fin + 1, Fin + 25)],
                  timer:sleep(100),
                  ?assertEqual(Fin - T0, conteo(Colector)),
                  %% el tick Fin + 30 dispara exactamente un latido
                  _ = [p29_reloj:tick() || _ <- lists:seq(Fin + 26, Fin + 30)],
                  timer:sleep(100),
                  ?assertEqual(Fin - T0 + 1, conteo(Colector))
                end)
       ]
   end}.
%% ---- 8c. caos extendido -----------------------------------------------------------

%% Apagon total de senal (los dos vuelos dejan de reportar ADS-B a la vez):
%% el watchdog marca ambas sin_senal, devuelve todas las cargas y las deja
%% pendiente (ninguna unidad en cupo). Al volver la senal (misma re-
%% suscripcion) el proximo reporte repone en_ruta y reasigna las pendientes.
caos_sector_sin_senal_test_() ->
  {setup,
   fun() ->
       Sup = arrancar([{sin_senal_ticks, 3}]),
       esperar_asignadas(12),
       Pids = [maps:get(pid, p29_datos:aeronave(Id)) || Id <- [1, 2]],
       ?assertEqual(1, p29_reloj:tick()),
       timer:sleep(30),
       {Sup, Pids}
   end,
   fun({SupPid, Pids}) ->
       lists:foreach(fun(P) -> p29_reloj:desuscribir(P) end, Pids),
       cerrar(SupPid)
   end,
   fun({_Sup, Pids}) ->
      [
       ?_test(begin
                  %% apagon: ninguna aeronave reporta
                  lists:foreach(fun(P) -> p29_reloj:desuscribir(P) end, Pids),
                  _ = [p29_reloj:tick() || _ <- lists:seq(2, 4)],
                  timer:sleep(30),
                  esperar(fun() ->
                              [maps:get(estado, p29_datos:aeronave(Id))
                               || Id <- [1, 2]] =:= [sin_senal, sin_senal]
                          end, 2000),
                  ?assertEqual([], p29_despachador:envios_de(1)),
                  ?assertEqual([], p29_despachador:envios_de(2)),
                  ?assertEqual(0, length(p29_datos:envios_por_estado(en_ruta))),
                  ?assertEqual(ok, p29_despachador:invariantes()),
                  %% vuelve la senal: reportan de nuevo y recuperan la carga
                  lists:foreach(fun(P) -> p29_reloj:subscribe(P) end, Pids),
                  ?assertEqual(5, p29_reloj:tick()),
                  timer:sleep(30),
                  esperar_asignadas(12),
                  ?assertEqual([en_ruta, en_ruta],
                               [maps:get(estado, p29_datos:aeronave(Id))
                                || Id <- [1, 2]]),
                  ?assertEqual(ok, p29_despachador:invariantes())
              end)
       ]
   end}.

%% Meteo severa que cubre toda la geografia y todos los FL: el despachador
%% pone toda la flota en alerta_meteo y el arbol sigue vivo e invariante.
caos_meteo_severa_test_() ->
  {setup,
   fun() -> Sup = arrancar([]), esperar_asignadas(12), Sup end,
   fun cerrar/1,
   fun(_Sup) ->
      [
       ?_test(begin
                  Zonas = lists:usort(
                            [begin
                                 {Lat, Lon} = maps:get(pos, A),
                                 {erlang:round(Lat / 5) * 5,
                                  erlang:round(Lon / 5) * 5}
                             end
                             || A <- p29_datos:aeronaves_todas()]),
                  ?assertNotEqual([], Zonas),
                  lists:foreach(
                    fun(Z) ->
                        p29_despachador:meteo_alerta(
                          #{zona => Z, fl_afectado => {0, 999},
                            severidad => severa, tipo => conveccion})
                    end, Zonas),
                  esperar(fun() ->
                              [maps:get(estado, A, none)
                               || A <- p29_datos:aeronaves_todas()]
                              =:= [alerta_meteo, alerta_meteo]
                          end, 2000),
                  ?assertEqual(ok, p29_despachador:invariantes()),
                  %% la flota sigue operando bajo alerta: un tick mas no rompe
                  ?assertEqual(1, p29_reloj:tick()),
                  timer:sleep(30),
                  ?assertEqual(ok, p29_despachador:invariantes())
              end)
       ]
   end}.

%% Fallo del hub: el gen_statem del transbordo muere en vuelo y el
%% simple_one_for_one (restart permanent) lo relanza con sus datos; el
%% despachador (monitor 'DOWN') devuelve el envio y lo reasigna, y un
%% doble fallo consecutivo tampoco tira el arbol.
caos_fallo_hub_transbordo_test_() ->
  {setup,
   fun() -> Sup = arrancar([]), esperar_asignadas(12), Sup end,
   fun cerrar/1,
   fun(_Sup) ->
      [
       ?_test(begin
                  EnvioId = maps:get(id, hd(p29_despachador:envios_de(1))),
                  p29_despachador:ejecutar_transbordo(EnvioId, 2, <<"MEX">>),
                  esperar(fun() ->
                              length(supervisor:which_children(
                                       p29_transbordo_sup)) =:= 1
                          end, 2000),
                  PidViejo = hd([P || {_, P, worker, _}
                                      <- supervisor:which_children(
                                           p29_transbordo_sup)]),
                  %% primer fallo del hub
                  exit(PidViejo, kill),
                  esperar(fun() ->
                              Pids = [P || {_, P, worker, _}
                                           <- supervisor:which_children(
                                                p29_transbordo_sup)],
                              Pids =/= [PidViejo] andalso Pids =/= []
                          end, 2000),
                  %% el envio no queda atascado en transbordo: el despachador
                  %% lo devuelve y reasigna (en_ruta o pendiente segun cupo)
                  esperar(fun() ->
                              E = p29_datos:envio(EnvioId),
                              maps:get(estado, E) =/= transbordo
                          end, 2000),
                  ?assertEqual(1, length(supervisor:which_children(
                                           p29_transbordo_sup))),
                  ?assertEqual(ok, p29_despachador:invariantes()),
                  %% segundo fallo consecutivo (intensity 20 lo tolera)
                  PidNuevo = hd([P || {_, P, worker, _}
                                      <- supervisor:which_children(
                                           p29_transbordo_sup)]),
                  exit(PidNuevo, kill),
                  esperar(fun() ->
                              Pids2 = [P || {_, P, worker, _}
                                            <- supervisor:which_children(
                                                 p29_transbordo_sup)],
                              Pids2 =/= [PidNuevo] andalso Pids2 =/= []
                          end, 2000),
                  esperar(fun() ->
                              E2 = p29_datos:envio(EnvioId),
                              maps:get(estado, E2) =/= transbordo
                          end, 2000),
                  ?assertEqual(ok, p29_despachador:invariantes())
              end)
       ]
   end}.

%% ---- 9. web: API, mapa y /metrics sobre el arbol completo -----------------------

%% El escenario levanta cowboy en un puerto efimero (web_port 0) contra los
%% mismos endpoints que consume la UI de la flotilla en produccion.
%% El wrapper {timeout, 60, ...} y los timeouts httpc holgados existen por un
%% quieque del runtime en Windows/OTP 29: tras 2-3 conexiones seguidas, una
%% conexion nueva puede tardar ~5 s en ser despachada por el listener (se vio
%% con stacktrace: los acceptors de ranch quedan en prim_inet:accept0 con la
%% conexion esperando en el backlog). En Linux/CI no ocurre; el margen no
%% cambia nada alla y aqui evita que el leaf de 5 s de eunit cancele el caso.
web_endpoints_test_() ->
  {timeout, 60,
   {setup,
    fun() ->
        Sup = arrancar([]),
        esperar_asignadas(12),
        {Sup, ranch:get_port(p29_web_http)}
    end,
    fun({SupPid, _Puerto}) ->
        cerrar(SupPid)
    end,
    fun({_Sup, Puerto}) ->
        [
         ?_test(begin
                   inets:start(),
                   Ruta = fun(Q) ->
                              "http://127.0.0.1:" ++ integer_to_list(Puerto) ++ Q
                          end,
                   %% Reintento para /metrics: el atasco de accept del
                   %% runtime en Windows/OTP 29 (comentario arriba) puede
                   %% superar incluso 15 s; pedir de nuevo lo libera. En
                   %% Linux/CI la primera tentativa siempre basta.
                   PedirMetricas =
                     fun Intento(N) when N > 0 ->
                             case (catch httpc:request(
                                          get, {Ruta("/metrics"), []},
                                          [{timeout, 15000}],
                                          [{body_format, binary}])) of
                               {ok, Respuesta} -> {ok, Respuesta};
                               _ when N > 1 ->
                                   timer:sleep(500),
                                   Intento(N - 1);
                               _ ->
                                   error({metrics_timeout, N})
                             end
                         end,
                   {ok, {{_, 200, _}, _, CuerpoEstado}} =
                     httpc:request(get, {Ruta("/api/estado"), []},
                                   [{timeout, 10000}], [{body_format, binary}]),
                   EstadoJson = decodificar(CuerpoEstado),
                   ?assertEqual(<<"ok">>, maps:get(<<"invariantes">>, EstadoJson)),
                   ?assertEqual(12,
                                maps:get(<<"en_ruta">>,
                                         maps:get(<<"envios">>, EstadoJson))),
                   {ok, {{_, 200, _}, _, CuerpoEnvios}} =
                     httpc:request(get, {Ruta("/api/envios"), []},
                                   [{timeout, 10000}], [{body_format, binary}]),
                   ?assertEqual(12, length(decodificar(CuerpoEnvios))),
                   {ok, {{_, 200, _}, _, CuerpoAeronaves}} =
                     httpc:request(get, {Ruta("/api/aeronaves"), []},
                                   [{timeout, 10000}], [{body_format, binary}]),
                   ?assertEqual(2, length(decodificar(CuerpoAeronaves))),
                   {ok, {{_, 200, _}, _, CuerpoMetricas}} =
                     PedirMetricas(3),
                   ?assertMatch({match, _},
                                re:run(CuerpoMetricas,
                                       <<"^p29_flotilla_envios\\{estado=">>,
                                       [multiline])),
                   %% caos por HTTP: averiar una aeronave viva y una inexistente
                   {ok, {{_, 200, _}, _, CuerpoAveriar}} =
                     httpc:request(post, {Ruta("/api/averiar"), [],
                                          "application/json",
                                          <<"{\"aeronave\":1}">>},
                                   [{timeout, 10000}], [{body_format, binary}]),
                   ?assertMatch(#{<<"ok">> := true, <<"aeronave">> := 1},
                                decodificar(CuerpoAveriar)),
                   {ok, {{_, 404, _}, _, CuerpoNoHubo}} =
                     httpc:request(post, {Ruta("/api/averiar"), [],
                                          "application/json",
                                          <<"{\"aeronave\":99}">>},
                                   [{timeout, 10000}], [{body_format, binary}]),
                   ?assertMatch(#{<<"ok">> := false}, decodificar(CuerpoNoHubo)),
                   %% cuerpo basura: 400, nunca crash
                   {ok, {{_, 400, _}, _, CuerpoBasura}} =
                     httpc:request(post, {Ruta("/api/averiar"), [],
                                          "application/json",
                                          <<"\x07no-es-json">>},
                                   [{timeout, 10000}], [{body_format, binary}]),
                   ?assertMatch(#{<<"ok">> := false}, decodificar(CuerpoBasura)),
                   %% urgente por HTTP: alta de un envio urgente fuera del lote
                   {ok, {{_, 200, _}, _, CuerpoUrgente}} =
                     httpc:request(post, {Ruta("/api/urgente"), [],
                                          "application/json",
                                          <<"{\"peso_kg\":30, \"origen_iata\":\"MEX\", \"destino_iata\":\"BOG\"}">>},
                                   [{timeout, 10000}], [{body_format, binary}]),
                   ?assertMatch(#{<<"ok">> := true, <<"envio">> := _},
                                decodificar(CuerpoUrgente))
                end)
         ]
     end}}.
