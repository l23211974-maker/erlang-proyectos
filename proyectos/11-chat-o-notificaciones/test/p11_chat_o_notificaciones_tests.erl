-module(p11_chat_o_notificaciones_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p11_chat_o_notificaciones_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p11_chat_o_notificaciones_server:ping()),
      ?_assert(is_map(p11_chat_o_notificaciones_server:state()))]
   end}.
