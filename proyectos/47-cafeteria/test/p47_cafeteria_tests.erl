-module(p47_cafeteria_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p47_cafeteria_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p47_cafeteria_server:ping()),
      ?_assert(is_map(p47_cafeteria_server:state()))]
   end}.
