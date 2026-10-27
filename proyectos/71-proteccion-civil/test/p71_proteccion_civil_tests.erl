-module(p71_proteccion_civil_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p71_proteccion_civil_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p71_proteccion_civil_server:ping()),
      ?_assert(is_map(p71_proteccion_civil_server:state()))]
   end}.
