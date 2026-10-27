-module(p04_apiario_o_ganado_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p04_apiario_o_ganado_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p04_apiario_o_ganado_server:ping()),
      ?_assert(is_map(p04_apiario_o_ganado_server:state()))]
   end}.
