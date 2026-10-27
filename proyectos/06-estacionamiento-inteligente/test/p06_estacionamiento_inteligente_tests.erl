-module(p06_estacionamiento_inteligente_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p06_estacionamiento_inteligente_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p06_estacionamiento_inteligente_server:ping()),
      ?_assert(is_map(p06_estacionamiento_inteligente_server:state()))]
   end}.
