-module(p60_restaurante_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p60_restaurante_sup:start_link().

stop(_State) ->
  ok.
