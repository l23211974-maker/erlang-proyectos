-module(p03_riego_por_zonas_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p03_riego_por_zonas_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p03_riego_por_zonas_server:ping()),
      ?_assert(is_map(p03_riego_por_zonas_server:state()))]
   end}.
