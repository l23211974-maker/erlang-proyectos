-module(p67_centro_de_emergencias_911_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p67_centro_de_emergencias_911_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p67_centro_de_emergencias_911_server:ping()),
      ?_assert(is_map(p67_centro_de_emergencias_911_server:state()))]
   end}.
