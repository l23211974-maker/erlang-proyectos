-module(p60_restaurante_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p60_restaurante_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p60_restaurante_server:ping()),
      ?_assert(is_map(p60_restaurante_server:state()))]
   end}.
