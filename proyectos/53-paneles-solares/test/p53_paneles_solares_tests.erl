-module(p53_paneles_solares_tests).
-include_lib("eunit/include/eunit.hrl").

arbol_de_supervision_test_() ->
  {setup,
   fun() -> {ok, Pid} = p53_paneles_solares_sup:start_link(), Pid end,
   fun(Pid) ->
     unlink(Pid),
     exit(Pid, shutdown)
   end,
   fun(_) ->
     [?_assertEqual(pong, p53_paneles_solares_server:ping()),
      ?_assert(is_map(p53_paneles_solares_server:state()))]
   end}.
