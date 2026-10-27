-module(p20_release_y_despliegue_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p20_release_y_despliegue_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p20_release_y_despliegue_server:ping()),
      ?_assert(is_map(p20_release_y_despliegue_server:state()))]
   end}.
