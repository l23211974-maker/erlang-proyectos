-module(p74_radio_o_streaming_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p74_radio_o_streaming_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p74_radio_o_streaming_server:ping()),
      ?_assert(is_map(p74_radio_o_streaming_server:state()))]
   end}.
