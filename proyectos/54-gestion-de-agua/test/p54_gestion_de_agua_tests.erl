-module(p54_gestion_de_agua_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p54_gestion_de_agua_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p54_gestion_de_agua_server:ping()),
      ?_assert(is_map(p54_gestion_de_agua_server:state()))]
   end}.
