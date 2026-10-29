-module(p29_flotilla_de_reparto_tests).
-include_lib("eunit/include/eunit.hrl").

%% Suite del proyecto #29. Cada escenario arranca su propio arbol de
%% supervision con envs pequenos (2 unidades, entregas contadas) y reloj
%% MANUAL (reloj_auto false) para corridas deterministas y rapidas.

-define(APP, p29_flotilla_de_reparto).

%% ---- infraestructura de escenarios ------------------------------------------

arrancar(EnvsExtra) ->
  lists:foreach(
    fun({K, V}) -> application:set_env(?APP, K, V) end,
    [
     {vehiculos, 2}, {entregas, 12}, {reloj_auto, false},
     {tick_interval_ms, 3600000}, {prob_fallida, 0.0},
     {sin_senal_ticks, 100}, {ticks_por_parada, 999999},
     {capacidad_kg, 6000}, {asignar_al_inicio, true}
    ] ++ EnvsExtra),
  {ok, Pid} = p29_flotilla_de_reparto_sup:start_link(),
  esperar(fun() -> length(p29_datos:vehiculos_todas()) =:= 2 end),
  esperar(fun() -> length(p29_datos:entregas_todas()) =:= 12 end),
  Pid.

cerrar(Pid) ->
  unlink(Pid),
  exit(Pid, shutdown),
  %% garantiza que las tablas ETS del escenario anterior mueren antes del siguiente
  esperar(fun() -> whereis(p29_datos) =:= undefined end).

%% polling con timeout generoso (los broadcasts del reloj son asincronos)
esperar(Fun) -> esperar(Fun, 2000).
esperar(_Fun, 0) -> timeout;
esperar(Fun, Restante) ->
  case Fun() of
    true -> ok;
    false ->
      timer:sleep(10),
      esperar(Fun, Restante - 10)
  end.

esperar_asignadas(Total) ->
  esperar(fun() ->
              length(p29_datos:entregas_por_estado(en_ruta)) =:= Total
          end).

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
                Entregas = maps:get(entregas, Estado),
                Vehiculos = maps:get(vehiculos, Estado),
                ?assertEqual(12, maps:get(en_ruta, Entregas, 0)),
                ?assertEqual(0, maps:get(pendiente, Entregas, 0)),
                ?assertEqual(2, maps:get(en_ruta, Vehiculos, 0))
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
                Unidades = lists:usort(
                             [maps:get(vehiculo, E)
                              || E <- p29_datos:entregas_todas()]),
                ?assertEqual([1, 2], lists:sort(Unidades)),
                lists:foreach(
                  fun(Vid) ->
                      Carga = lists:sum(
                                [maps:get(peso, E)
                                 || E <- p29_despachador:entregas_de(Vid)]),
                      Row = p29_datos:vehiculo(Vid),
                      ?assert(Carga =< maps:get(capacidad, Row))
                  end, [1, 2]),
                ?assertEqual(ok, p29_despachador:invariantes())
              end)
     ]
   end}.

%% ---- 3. gen_statem de entrega: transiciones ------------------------------------

entrega_statem_test_() ->
  {setup,
   fun() ->
       PidSup = arrancar([{asignar_al_inicio, false}]),
       esperar(fun() -> length(p29_datos:entregas_por_estado(pendiente))
                             =:= 12 end),
       PidSup
   end,
   fun cerrar/1,
   fun(_) ->
     [
      ?_test(begin
                PidE1 = maps:get(pid, p29_despachador:entrega(1)),
                ?assertEqual({pendiente, undefined}, p29_entrega:estado(PidE1)),
                ?assertEqual(ok, p29_entrega:asignar(PidE1, 1, 5)),
                ?assertEqual({en_ruta, 1}, p29_entrega:estado(PidE1)),
                %% rechaza asignacion sin devolver antes: no duplica dueno
                ?assertEqual({error, ya_en_ruta},
                             p29_entrega:asignar(PidE1, 2, 6)),
                ?assertEqual(ok, p29_entrega:entregar(PidE1, 10)),
                ?assertEqual({entregada, 1}, p29_entrega:estado(PidE1)),
                ?assertEqual({error, estado_final},
                             p29_entrega:fallar(PidE1, cliente_ausente))
              end),
      ?_test(begin
                PidE2 = maps:get(pid, p29_despachador:entrega(2)),
                %% devolver desde pendiente no es una transicion valida
                ?assertEqual({error, {evento_no_valido, devolver, pendiente}},
                             p29_entrega:devolver(PidE2))
              end)
     ]
   end}.

%% ---- 4. averia: la carga de la unidad caida pasa a la sana ----------------------

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
                EnV1 = length(p29_despachador:entregas_de(1)),
                ?assertNotEqual(0, EnV1),
                ?assertEqual(ok, p29_despachador:averiar(1)),
                ?assertEqual(averiado,
                             maps:get(estado, p29_datos:vehiculo(1))),
                ?assertEqual([], p29_despachador:entregas_de(1)),
                ?assertEqual(12, length(p29_despachador:entregas_de(2))),
                ?assertEqual(EnV1, p29_despachador:reasignaciones()),
                ?assertEqual(ok, p29_despachador:invariantes())
              end)
     ]
   end}.

%% ---- 5. sin senal (watchdog) y lote de reportes atrasado ------------------------

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
                %% impulsa via reloj para que AMBAS unidades reporten GPS;
                %% 30 ms entre ticks dejan procesar los GPS (sin carreras)
                ?assertEqual(1, p29_reloj:tick()),
                timer:sleep(30),
                PidVeh2 = maps:get(pid, p29_datos:vehiculo(2)),
                C2 = length(p29_despachador:entregas_de(2)),
                ?assertNotEqual(0, C2),
                %% la unidad 2 pierde senal: deja de recibir ticks
                ?assertEqual(ok, p29_reloj:desuscribir(PidVeh2)),
                %% reloj: 2..4: el ultimo GPS de la unidad 2 fue el tick 1:
                %% al tick 4 (4-1 >= 3) el watchdog la marca y reasigna
                ?assertEqual(2, p29_reloj:tick()),
                timer:sleep(30),
                ?assertEqual(3, p29_reloj:tick()),
                timer:sleep(30),
                ?assertEqual(4, p29_reloj:tick()),
                timer:sleep(30),
                esperar(fun() ->
                            maps:get(estado, p29_datos:vehiculo(2))
                            =:= sin_senal
                        end),
                ?assertEqual(sin_senal,
                             maps:get(estado, p29_datos:vehiculo(2))),
                ?assertEqual([], p29_despachador:entregas_de(2)),
                ?assertEqual(C2, p29_despachador:reasignaciones()),
                ?assertEqual(ok, p29_despachador:invariantes())
              end),
      ?_test(begin
                %% caso dificil 3: reporte con tick atrasado se descarta
                PidUnidad = maps:get(pid, p29_datos:vehiculo(1)),
                p29_despachador:reportar_gps(1, {5, 5}, 10, PidUnidad),
                p29_despachador:reportar_gps(1, {9, 9}, 5, PidUnidad),
                esperar(fun() ->
                            maps:get(pos, p29_datos:vehiculo(1), none)
                            =:= {5, 5}
                        end),
                Fila = p29_datos:vehiculo(1),
                ?assertEqual({5, 5}, maps:get(pos, Fila)),
                ?assertEqual(10, maps:get(ultimo_reporte, Fila))
              end)
     ]
   end}.

%% ---- 6. recuperacion: la supervision relanza la unidad --------------------------

recuperacion_tras_averia_test_() ->
  {timeout, 30,
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
                ?assertEqual(ok, p29_despachador:averiar(1)),
                PidViejo = maps:get(pid, p29_datos:vehiculo(1)),
                %% el supervisor relanza la unidad; su GPS nuevo la repone.
                %% Con reloj manual el tick del test puede llegar ANTES de que
                %% la unidad nueva se suscriba: se repiten ticks durante la
                %% espera para no depender del orden de suscripcion
                ?assertEqual(1, p29_reloj:tick()),
                esperar(fun() ->
                            timer:sleep(50),
                            _ = p29_reloj:tick(),
                            Row0 = p29_datos:vehiculo(1),
                            maps:get(estado, Row0) =:= en_ruta
                            andalso maps:get(pid, Row0) =/= PidViejo
                        end, 3000),
                Row = p29_datos:vehiculo(1),
                ?assertEqual(en_ruta, maps:get(estado, Row)),
                ?assertEqual(ok, p29_despachador:invariantes())
              end)
     ]
   end}}.

%% ---- 7. pedido urgente ----------------------------------------------------------

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
                Id = p29_despachador:urgente(#{peso => 40, colonia => playas}),
                Urgente = p29_despachador:entrega(Id),
                ?assertEqual(true, maps:get(urgente, Urgente)),
                ?assertEqual(en_ruta, maps:get(estado, Urgente)),
                ?assert(is_integer(maps:get(vehiculo, Urgente))),
                ?assertEqual(ok, p29_despachador:invariantes())
              end)
     ]
   end}.

%% ---- 8. mini-jornada del enunciado con averia y urgente --------------------------

%% Escenario del enunciado en miniatura: jornada de 30 ticks (con reloj
%% automatico acelerado), averia al ~46% de la jornada y pedido urgente al 75%.
%% Con prob_fallida 0 (env del helper) el resultado final es exacto:
%% 12 entregas + 1 urgente = 13 entregadas, 0 pendientes, 0 fallidas.
simulador_test_() ->
  {setup,
   fun() ->
       Sup = arrancar([{reloj_auto, true}, {tick_interval_ms, 3},
                       {ticks_jornada, 30}, {ticks_por_parada, 3},
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
                             maps:get(entregada, p29_datos:conteo_entregas(), 0)
                             =:= 13
                         end, 2000),
                 Estado = p29_despachador:estado(),
                 Entregas = maps:get(entregas, Estado),
                 ?assertEqual(13, maps:get(entregada, Entregas, 0)),
                 ?assertEqual(0, maps:get(pendiente, Entregas, 0)),
                 ?assertEqual(0, maps:get(en_ruta, Entregas, 0)),
                 ?assertEqual(0, maps:get(fallida, Entregas, 0)),
                 ?assertEqual(ok, p29_despachador:invariantes())
               end)
      ]
   end}.
