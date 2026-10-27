-module(p38_andon_digital_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p38_andon_digital_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p38_andon_digital_server:ping()),
      ?_assert(is_map(p38_andon_digital_server:state()))]
   end}.
