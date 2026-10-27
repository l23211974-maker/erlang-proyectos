-module(p50_examen_en_linea_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p50_examen_en_linea_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p50_examen_en_linea_server:ping()),
      ?_assert(is_map(p50_examen_en_linea_server:state()))]
   end}.
