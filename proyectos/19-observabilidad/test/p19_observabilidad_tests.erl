-module(p19_observabilidad_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p19_observabilidad_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p19_observabilidad_server:ping()),
      ?_assert(is_map(p19_observabilidad_server:state()))]
   end}.
