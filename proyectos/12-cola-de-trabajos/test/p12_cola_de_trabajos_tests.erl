-module(p12_cola_de_trabajos_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p12_cola_de_trabajos_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p12_cola_de_trabajos_server:ping()),
      ?_assert(is_map(p12_cola_de_trabajos_server:state()))]
   end}.
