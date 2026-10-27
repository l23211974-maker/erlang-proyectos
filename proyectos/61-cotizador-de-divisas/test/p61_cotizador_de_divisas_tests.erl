-module(p61_cotizador_de_divisas_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p61_cotizador_de_divisas_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p61_cotizador_de_divisas_server:ping()),
      ?_assert(is_map(p61_cotizador_de_divisas_server:state()))]
   end}.
