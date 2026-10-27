-module(p26_central_camionera_rutas_urba_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p26_central_camionera_rutas_urba_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p26_central_camionera_rutas_urba_server:ping()),
      ?_assert(is_map(p26_central_camionera_rutas_urba_server:state()))]
   end}.
