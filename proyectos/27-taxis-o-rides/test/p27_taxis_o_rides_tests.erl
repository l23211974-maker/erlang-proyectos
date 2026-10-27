-module(p27_taxis_o_rides_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p27_taxis_o_rides_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p27_taxis_o_rides_server:ping()),
      ?_assert(is_map(p27_taxis_o_rides_server:state()))]
   end}.
