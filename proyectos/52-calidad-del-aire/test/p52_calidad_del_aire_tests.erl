-module(p52_calidad_del_aire_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p52_calidad_del_aire_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p52_calidad_del_aire_server:ping()),
      ?_assert(is_map(p52_calidad_del_aire_server:state()))]
   end}.
