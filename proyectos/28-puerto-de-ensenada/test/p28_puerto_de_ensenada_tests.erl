-module(p28_puerto_de_ensenada_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p28_puerto_de_ensenada_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p28_puerto_de_ensenada_server:ping()),
      ?_assert(is_map(p28_puerto_de_ensenada_server:state()))]
   end}.
