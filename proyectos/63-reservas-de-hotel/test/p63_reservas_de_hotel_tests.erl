-module(p63_reservas_de_hotel_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p63_reservas_de_hotel_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p63_reservas_de_hotel_server:ping()),
      ?_assert(is_map(p63_reservas_de_hotel_server:state()))]
   end}.
