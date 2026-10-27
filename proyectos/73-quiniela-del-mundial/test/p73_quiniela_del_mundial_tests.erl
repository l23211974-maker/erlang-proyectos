-module(p73_quiniela_del_mundial_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p73_quiniela_del_mundial_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p73_quiniela_del_mundial_server:ping()),
      ?_assert(is_map(p73_quiniela_del_mundial_server:state()))]
   end}.
