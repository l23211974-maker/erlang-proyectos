-module(p49_estacionamiento_del_campus_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p49_estacionamiento_del_campus_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p49_estacionamiento_del_campus_server:ping()),
      ?_assert(is_map(p49_estacionamiento_del_campus_server:state()))]
   end}.
