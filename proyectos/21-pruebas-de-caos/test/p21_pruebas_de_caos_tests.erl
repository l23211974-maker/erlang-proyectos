-module(p21_pruebas_de_caos_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p21_pruebas_de_caos_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p21_pruebas_de_caos_server:ping()),
      ?_assert(is_map(p21_pruebas_de_caos_server:state()))]
   end}.
