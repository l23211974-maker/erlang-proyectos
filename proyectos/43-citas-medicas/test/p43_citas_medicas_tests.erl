-module(p43_citas_medicas_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p43_citas_medicas_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p43_citas_medicas_server:ping()),
      ?_assert(is_map(p43_citas_medicas_server:state()))]
   end}.
