-module(p69_camaras_y_accesos_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p69_camaras_y_accesos_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p69_camaras_y_accesos_server:ping()),
      ?_assert(is_map(p69_camaras_y_accesos_server:state()))]
   end}.
