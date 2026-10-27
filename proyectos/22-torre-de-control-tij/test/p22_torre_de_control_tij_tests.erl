-module(p22_torre_de_control_tij_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p22_torre_de_control_tij_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p22_torre_de_control_tij_server:ping()),
      ?_assert(is_map(p22_torre_de_control_tij_server:state()))]
   end}.
