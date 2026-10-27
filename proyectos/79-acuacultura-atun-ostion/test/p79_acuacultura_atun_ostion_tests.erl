-module(p79_acuacultura_atun_ostion_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p79_acuacultura_atun_ostion_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p79_acuacultura_atun_ostion_server:ping()),
      ?_assert(is_map(p79_acuacultura_atun_ostion_server:state()))]
   end}.
