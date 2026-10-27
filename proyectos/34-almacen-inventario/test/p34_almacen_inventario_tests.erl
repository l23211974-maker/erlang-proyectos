-module(p34_almacen_inventario_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p34_almacen_inventario_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p34_almacen_inventario_server:ping()),
      ?_assert(is_map(p34_almacen_inventario_server:state()))]
   end}.
