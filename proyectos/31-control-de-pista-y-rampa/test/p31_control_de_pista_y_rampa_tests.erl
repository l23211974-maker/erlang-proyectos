-module(p31_control_de_pista_y_rampa_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p31_control_de_pista_y_rampa_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p31_control_de_pista_y_rampa_server:ping()),
      ?_assert(is_map(p31_control_de_pista_y_rampa_server:state()))]
   end}.
