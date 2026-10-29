-module(p29_simulador).

%% Demo del enunciado: jornada acelerada con averia al ~11 a.m. y pedido
%% urgente a media jornada. NO es un hijo de supervision: es un espectador
%% que se suscribe al reloj y decide cuando inyectar los fallos / urgencia.
%% Correr en la shell del release o con `rebar3 shell`: p29_simulador:demo().
%% Termina con resumen y exit normal al cerrar la jornada (ticks_jornada).

-export([demo/0]).

demo() ->
  spawn(fun inicio/0).

inicio() ->
  T = application:get_env(p29_flotilla_de_reparto, ticks_jornada, 2160),
  TickAveria = trunc(T * 0.4583),   %% ~11 a.m. en una jornada de 6 h (8 a 2 pm)
  TickUrgente = (T * 3) div 4,      %% urgente a media tarde
  ok = subscribir(),
  esperar_flota(),
  logger:info("demo #29: jornada de ~p ticks GPS (10 s cada uno simulados); "
              "averia en el tick ~p; urgente en el tick ~p",
              [T, TickAveria, TickUrgente], #{dominio => flotilla}),
  receive
    {p29_tick, N} -> paso(N, T, TickAveria, TickUrgente)
  end.

paso(N, T, _TickAveria, _TickUrgente) when N >= T ->
  resumen_final(),
  case whereis(p29_reloj) of
    undefined -> ok;
    _ -> gen_server:call(p29_reloj, {desuscribir, self()})
  end,
  exit(normal);
paso(N, T, TickAveria, TickUrgente) ->
  case N =:= TickAveria of
    true -> inyectar_averia();
    false -> ok
  end,
  case N =:= TickUrgente of
    true -> inyectar_urgente();
    false -> ok
  end,
  progreso(N),
  receive
    {p29_tick, N2} when is_integer(N2) -> paso(N2, T, TickAveria, TickUrgente)
  end.

inyectar_averia() ->
  case p29_despachador:vehiculo_cargado() of
    undefined -> ok;
    Vid ->
      logger:warning("demo: averia de la unidad ~p con ~p entregas a bordo",
                     [Vid, length(p29_despachador:entregas_de(Vid))],
                     #{dominio => flotilla}),
      ok = p29_despachador:averiar(Vid)
  end.

inyectar_urgente() ->
  Id = p29_despachador:urgente(#{peso => 25, colonia => playas}),
  logger:warning("demo: pedido urgente ~p insertado a media jornada",
                 [Id], #{dominio => flotilla}).

progreso(N) ->
  case N rem 5 =:= 0 of
    false -> ok;
    true ->
      EstadoTick = p29_despachador:estado(),
      logger:info("demo tick ~p: entregas ~p vehiculos ~p",
                  [N, maps:get(entregas, EstadoTick), maps:get(vehiculos, EstadoTick)],
                  #{dominio => flotilla})
  end.

resumen_final() ->
  Estado = p29_despachador:estado(),
  Inv = p29_despachador:invariantes(),
  logger:info("demo fin de jornada: ~p; invariantes: ~p",
              [Estado, Inv], #{dominio => flotilla}).

subscribir() ->
  case whereis(p29_reloj) of
    undefined -> ok;
    _ -> gen_server:call(p29_reloj, {subscribe, self()})
  end.

%% la demo arranca despues del arbol, pero por prudencia espera a que la
%% flota completa exista (en arranques muy cargados el autostart tarda ms)
esperar_flota() ->
  NVeh = application:get_env(p29_flotilla_de_reparto, vehiculos, 15),
  NEnt = application:get_env(p29_flotilla_de_reparto, entregas, 900),
  esperar_flota(NVeh, NEnt, 100).

esperar_flota(_N, _NE, 0) -> ok;
esperar_flota(NVeh, NEnt, Intentos) ->
  Caso = p29_datos:conteo_vehiculos(),
  Listo = maps:get(en_ruta, Caso, 0) =:= NVeh
    andalso length(p29_datos:entregas_todas()) =:= NEnt,
  case Listo of
    true -> ok;
    false ->
      timer:sleep(10),
      esperar_flota(NVeh, NEnt, Intentos - 1)
  end.
