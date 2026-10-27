-module(p05_estacion_meteorologica_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p05_estacion_meteorologica_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p05_estacion_meteorologica_server:ping()),
      ?_assert(is_map(p05_estacion_meteorologica_server:state()))]
   end}.
