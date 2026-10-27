-module(p66_mercado_de_abastos_tianguis_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p66_mercado_de_abastos_tianguis_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p66_mercado_de_abastos_tianguis_server:ping()),
      ?_assert(is_map(p66_mercado_de_abastos_tianguis_server:state()))]
   end}.
