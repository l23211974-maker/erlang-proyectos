-module(p09_semaforos_o_cruceros_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p09_semaforos_o_cruceros_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p09_semaforos_o_cruceros_server:ping()),
      ?_assert(is_map(p09_semaforos_o_cruceros_server:state()))]
   end}.
