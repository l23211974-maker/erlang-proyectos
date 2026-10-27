-module(p62_billetera_virtual_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p62_billetera_virtual_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p62_billetera_virtual_server:ping()),
      ?_assert(is_map(p62_billetera_virtual_server:state()))]
   end}.
