-module(p41_signos_vitales_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p41_signos_vitales_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p41_signos_vitales_server:ping()),
      ?_assert(is_map(p41_signos_vitales_server:state()))]
   end}.
