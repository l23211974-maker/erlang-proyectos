-module(p70_alumbrado_publico_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p70_alumbrado_publico_sup:start_link().

stop(_State) ->
  ok.
