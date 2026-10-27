-module(p75_carreras_simuladas_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p75_carreras_simuladas_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p75_carreras_simuladas_server:ping()),
      ?_assert(is_map(p75_carreras_simuladas_server:state()))]
   end}.
