-module(p30_bicicletas_o_scooters_compar_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p30_bicicletas_o_scooters_compar_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p30_bicicletas_o_scooters_compar_server:ping()),
      ?_assert(is_map(p30_bicicletas_o_scooters_compar_server:state()))]
   end}.
