-module(p64_taquilla_de_eventos_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p64_taquilla_de_eventos_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p64_taquilla_de_eventos_server:ping()),
      ?_assert(is_map(p64_taquilla_de_eventos_server:state()))]
   end}.
