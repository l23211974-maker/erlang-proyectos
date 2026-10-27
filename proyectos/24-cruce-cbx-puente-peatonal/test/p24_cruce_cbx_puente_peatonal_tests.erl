-module(p24_cruce_cbx_puente_peatonal_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p24_cruce_cbx_puente_peatonal_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p24_cruce_cbx_puente_peatonal_server:ping()),
      ?_assert(is_map(p24_cruce_cbx_puente_peatonal_server:state()))]
   end}.
