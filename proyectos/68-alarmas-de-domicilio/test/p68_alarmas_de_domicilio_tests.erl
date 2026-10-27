-module(p68_alarmas_de_domicilio_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p68_alarmas_de_domicilio_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p68_alarmas_de_domicilio_server:ping()),
      ?_assert(is_map(p68_alarmas_de_domicilio_server:state()))]
   end}.
