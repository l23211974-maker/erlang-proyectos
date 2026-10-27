-module(p14_acortador_de_urls_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p14_acortador_de_urls_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p14_acortador_de_urls_server:ping()),
      ?_assert(is_map(p14_acortador_de_urls_server:state()))]
   end}.
