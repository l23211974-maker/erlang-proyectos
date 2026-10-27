-module(p29_flotilla_de_reparto_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p29_flotilla_de_reparto_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p29_flotilla_de_reparto_server:ping()),
      ?_assert(is_map(p29_flotilla_de_reparto_server:state()))]
   end}.
