-module(p23_puertas_de_abordar_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p23_puertas_de_abordar_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p23_puertas_de_abordar_server:ping()),
      ?_assert(is_map(p23_puertas_de_abordar_server:state()))]
   end}.
