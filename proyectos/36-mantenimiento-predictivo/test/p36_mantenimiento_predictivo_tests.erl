-module(p36_mantenimiento_predictivo_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p36_mantenimiento_predictivo_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p36_mantenimiento_predictivo_server:ping()),
      ?_assert(is_map(p36_mantenimiento_predictivo_server:state()))]
   end}.
