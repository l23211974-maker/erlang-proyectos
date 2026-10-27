-module(p57_incendios_forestales_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p57_incendios_forestales_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p57_incendios_forestales_server:ping()),
      ?_assert(is_map(p57_incendios_forestales_server:state()))]
   end}.
