-module(p32_linea_de_produccion_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p32_linea_de_produccion_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p32_linea_de_produccion_server:ping()),
      ?_assert(is_map(p32_linea_de_produccion_server:state()))]
   end}.
