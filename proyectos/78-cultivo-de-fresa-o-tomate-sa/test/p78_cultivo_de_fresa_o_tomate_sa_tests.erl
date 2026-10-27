-module(p78_cultivo_de_fresa_o_tomate_sa_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p78_cultivo_de_fresa_o_tomate_sa_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p78_cultivo_de_fresa_o_tomate_sa_server:ping()),
      ?_assert(is_map(p78_cultivo_de_fresa_o_tomate_sa_server:state()))]
   end}.
