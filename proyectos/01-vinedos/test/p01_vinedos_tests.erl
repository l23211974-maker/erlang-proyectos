-module(p01_vinedos_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p01_vinedos_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p01_vinedos_server:ping()),
      ?_assert(is_map(p01_vinedos_server:state()))]
   end}.
