-module(p35_control_de_calidad_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p35_control_de_calidad_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p35_control_de_calidad_server:ping()),
      ?_assert(is_map(p35_control_de_calidad_server:state()))]
   end}.
