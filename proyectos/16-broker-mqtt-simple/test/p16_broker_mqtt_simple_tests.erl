-module(p16_broker_mqtt_simple_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p16_broker_mqtt_simple_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p16_broker_mqtt_simple_server:ping()),
      ?_assert(is_map(p16_broker_mqtt_simple_server:state()))]
   end}.
