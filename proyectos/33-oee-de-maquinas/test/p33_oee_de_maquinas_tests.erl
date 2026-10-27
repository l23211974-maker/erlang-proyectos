-module(p33_oee_de_maquinas_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p33_oee_de_maquinas_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p33_oee_de_maquinas_server:ping()),
      ?_assert(is_map(p33_oee_de_maquinas_server:state()))]
   end}.
