-module(p44_banco_de_sangre_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p44_banco_de_sangre_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p44_banco_de_sangre_server:ping()),
      ?_assert(is_map(p44_banco_de_sangre_server:state()))]
   end}.
