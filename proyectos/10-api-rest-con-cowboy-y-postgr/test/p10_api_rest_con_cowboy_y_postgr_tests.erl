-module(p10_api_rest_con_cowboy_y_postgr_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p10_api_rest_con_cowboy_y_postgr_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p10_api_rest_con_cowboy_y_postgr_server:ping()),
      ?_assert(is_map(p10_api_rest_con_cowboy_y_postgr_server:state()))]
   end}.
