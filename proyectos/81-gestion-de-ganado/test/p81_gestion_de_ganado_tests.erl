-module(p81_gestion_de_ganado_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p81_gestion_de_ganado_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p81_gestion_de_ganado_server:ping()),
      ?_assert(is_map(p81_gestion_de_ganado_server:state()))]
   end}.
