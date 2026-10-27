-module(p08_monitor_de_energia_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p08_monitor_de_energia_sup:start_link().

stop(_State) ->
  ok.
