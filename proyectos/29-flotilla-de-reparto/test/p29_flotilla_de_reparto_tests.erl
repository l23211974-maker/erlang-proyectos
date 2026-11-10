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
     {tick_interval_ms, 3600000}, {prob_fallida, 0.0},
     {sin_senal_ticks, 100}, {ticks_por_parada, 999999},
     {capacidad_kg, 6000}, {asignar_al_inicio, true},
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
              length(p29_datos:envios_por_estado(en_ruta)) =:= Total
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
              end)
     ]
   end}.

%% ---- 6. recuperacion: la supervision relanza la aeronave --------------------------

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
                PidViejo = maps:get(pid, p29_datos:aeronave(1)),
                %% el supervisor relanza la aeronave; su ADS-B nuevo la repone.
                %% Con reloj manual el tick del test puede llegar ANTES de que
                %% la aeronave nueva se suscriba: se repiten ticks durante la
                %% espera para no depender del orden de suscripcion
                ?assertEqual(1, p29_reloj:tick()),
                esperar(fun() ->
                            timer:sleep(50),
                            _ = p29_reloj:tick(),
                            Row0 = p29_datos:aeronave(1),
                            maps:get(estado, Row0) =:= en_ruta
                            andalso maps:get(pid, Row0) =/= PidViejo
                        end, 3000),
                Row = p29_datos:aeronave(1),
                ?assertEqual(en_ruta, maps:get(estado, Row)),
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

%% Escenario AeroCargo en miniatura: jornada de 30 ticks (con reloj
%% automatico acelerado), averia al ~46% de la jornada y pedido urgente al 75%.
%% Con prob_fallida 0 (env del helper) el resultado final es exacto:
%% 12 envios + 1 urgente = 13 entregados, 0 pendientes, 0 fallidos.
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

%% ---- 9. web: API, mapa y /metrics sobre el arbol completo -----------------------

%% El escenario levanta cowboy en un puerto efimero (web_port 0) contra los
%% mismos endpoints que consume la UI de la flotilla en produccion.
web_endpoints_test_() ->
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
                  {ok, {{_, 200, _}, _, CuerpoEstado}} =
                    httpc:request(get, {Ruta("/api/estado"), []},
                                  [{timeout, 3000}], [{body_format, binary}]),
                  EstadoJson = decodificar(CuerpoEstado),
                  ?assertEqual(<<"ok">>, maps:get(<<"invariantes">>, EstadoJson)),
                  ?assertEqual(12,
                               maps:get(<<"en_ruta">>,
                                        maps:get(<<"envios">>, EstadoJson))),
                  {ok, {{_, 200, _}, _, CuerpoEnvios}} =
                    httpc:request(get, {Ruta("/api/envios"), []},
                                  [{timeout, 3000}], [{body_format, binary}]),
                  ?assertEqual(12, length(decodificar(CuerpoEnvios))),
                  {ok, {{_, 200, _}, _, CuerpoAeronaves}} =
                    httpc:request(get, {Ruta("/api/aeronaves"), []},
                                  [{timeout, 3000}], [{body_format, binary}]),
                  ?assertEqual(2, length(decodificar(CuerpoAeronaves))),
                  {ok, {{_, 200, _}, _, CuerpoMetricas}} =
                    httpc:request(get, {Ruta("/metrics"), []},
                                  [{timeout, 5000}], [{body_format, binary}]),
                  ?assertMatch({match, _},
                               re:run(CuerpoMetricas,
                                      <<"^p29_flotilla_envios\\{estado=">>,
                                      [multiline])),
                  %% caos por HTTP: averiar una aeronave viva y una inexistente
                  {ok, {{_, 200, _}, _, CuerpoAveriar}} =
                    httpc:request(post, {Ruta("/api/averiar"), [],
                                         "application/json",
                                         <<"{\"aeronave\":1}">>},
                                  [{timeout, 3000}], [{body_format, binary}]),
                  ?assertMatch(#{<<"ok">> := true, <<"aeronave">> := 1},
                               decodificar(CuerpoAveriar)),
                  {ok, {{_, 404, _}, _, CuerpoNoHubo}} =
                    httpc:request(post, {Ruta("/api/averiar"), [],
                                         "application/json",
                                         <<"{\"aeronave\":99}">>},
                                  [{timeout, 3000}], [{body_format, binary}]),
                  ?assertMatch(#{<<"ok">> := false}, decodificar(CuerpoNoHubo)),
                  %% cuerpo basura: 400, nunca crash
                  {ok, {{_, 400, _}, _, CuerpoBasura}} =
                    httpc:request(post, {Ruta("/api/averiar"), [],
                                         "application/json",
                                         <<"\x07no-es-json">>},
                                  [{timeout, 3000}], [{body_format, binary}]),
                  ?assertMatch(#{<<"ok">> := false}, decodificar(CuerpoBasura)),
                  %% urgente por HTTP: alta de un envio urgente fuera del lote
                  {ok, {{_, 200, _}, _, CuerpoUrgente}} =
                    httpc:request(post, {Ruta("/api/urgente"), [],
                                         "application/json",
                                         <<"{\"peso_kg\":30, \"origen_iata\":\"MEX\", \"destino_iata\":\"BOG\"}">>},
                                  [{timeout, 3000}], [{body_format, binary}]),
                  ?assertMatch(#{<<"ok">> := true, <<"envio">> := _},
                               decodificar(CuerpoUrgente))
               end)
       ]
    end}.