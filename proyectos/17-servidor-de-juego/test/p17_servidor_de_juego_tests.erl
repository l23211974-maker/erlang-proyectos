-module(p17_servidor_de_juego_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p17_servidor_de_juego_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p17_servidor_de_juego_server:ping()),
      ?_assert(is_map(p17_servidor_de_juego_server:state()))]
   end}.
