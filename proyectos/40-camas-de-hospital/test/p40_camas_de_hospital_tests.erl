-module(p40_camas_de_hospital_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p40_camas_de_hospital_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p40_camas_de_hospital_server:ping()),
      ?_assert(is_map(p40_camas_de_hospital_server:state()))]
   end}.
