-module(p65_subasta_de_ganado_o_producto_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p65_subasta_de_ganado_o_producto_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p65_subasta_de_ganado_o_producto_server:ping()),
      ?_assert(is_map(p65_subasta_de_ganado_o_producto_server:state()))]
   end}.
