-module(p80_cerveceria_artesanal_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p80_cerveceria_artesanal_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p80_cerveceria_artesanal_server:ping()),
      ?_assert(is_map(p80_cerveceria_artesanal_server:state()))]
   end}.
