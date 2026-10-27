-module(p58_playa_y_oleaje_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p58_playa_y_oleaje_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p58_playa_y_oleaje_server:ping()),
      ?_assert(is_map(p58_playa_y_oleaje_server:state()))]
   end}.
