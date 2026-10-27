-module(p18_subasta_o_reservas_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p18_subasta_o_reservas_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p18_subasta_o_reservas_server:ping()),
      ?_assert(is_map(p18_subasta_o_reservas_server:state()))]
   end}.
