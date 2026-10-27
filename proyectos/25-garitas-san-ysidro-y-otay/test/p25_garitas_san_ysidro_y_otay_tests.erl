-module(p25_garitas_san_ysidro_y_otay_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p25_garitas_san_ysidro_y_otay_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p25_garitas_san_ysidro_y_otay_server:ping()),
      ?_assert(is_map(p25_garitas_san_ysidro_y_otay_server:state()))]
   end}.
