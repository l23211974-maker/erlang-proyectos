-module(p08_monitor_de_energia_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p08_monitor_de_energia_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p08_monitor_de_energia_server:ping()),
      ?_assert(is_map(p08_monitor_de_energia_server:state()))]
   end}.
