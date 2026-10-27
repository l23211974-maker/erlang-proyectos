-module(p13_rate_limiter_cache_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p13_rate_limiter_cache_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p13_rate_limiter_cache_server:ping()),
      ?_assert(is_map(p13_rate_limiter_cache_server:state()))]
   end}.
