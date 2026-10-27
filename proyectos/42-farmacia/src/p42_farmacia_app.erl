-module(p42_farmacia_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p42_farmacia_sup:start_link().

stop(_State) ->
  ok.
