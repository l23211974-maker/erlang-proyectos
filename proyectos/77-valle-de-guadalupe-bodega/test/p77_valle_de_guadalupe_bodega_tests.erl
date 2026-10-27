-module(p77_valle_de_guadalupe_bodega_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p77_valle_de_guadalupe_bodega_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p77_valle_de_guadalupe_bodega_server:ping()),
      ?_assert(is_map(p77_valle_de_guadalupe_bodega_server:state()))]
   end}.
