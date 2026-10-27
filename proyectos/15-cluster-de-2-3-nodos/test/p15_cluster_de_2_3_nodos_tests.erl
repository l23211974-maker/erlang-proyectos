-module(p15_cluster_de_2_3_nodos_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p15_cluster_de_2_3_nodos_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p15_cluster_de_2_3_nodos_server:ping()),
      ?_assert(is_map(p15_cluster_de_2_3_nodos_server:state()))]
   end}.
