-module(p76_mesa_de_domino_o_loteria_en_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p76_mesa_de_domino_o_loteria_en_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p76_mesa_de_domino_o_loteria_en_server:ping()),
      ?_assert(is_map(p76_mesa_de_domino_o_loteria_en_server:state()))]
   end}.
