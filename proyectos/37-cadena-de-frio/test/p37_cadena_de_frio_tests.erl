-module(p37_cadena_de_frio_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p37_cadena_de_frio_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p37_cadena_de_frio_server:ping()),
      ?_assert(is_map(p37_cadena_de_frio_server:state()))]
   end}.
