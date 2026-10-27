-module(p02_invernadero_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p02_invernadero_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p02_invernadero_server:ping()),
      ?_assert(is_map(p02_invernadero_server:state()))]
   end}.
