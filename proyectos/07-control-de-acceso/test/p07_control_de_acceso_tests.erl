-module(p07_control_de_acceso_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p07_control_de_acceso_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p07_control_de_acceso_server:ping()),
      ?_assert(is_map(p07_control_de_acceso_server:state()))]
   end}.
