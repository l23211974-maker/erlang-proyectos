-module(p46_asistencia_por_qr_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p46_asistencia_por_qr_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p46_asistencia_por_qr_server:ping()),
      ?_assert(is_map(p46_asistencia_por_qr_server:state()))]
   end}.
