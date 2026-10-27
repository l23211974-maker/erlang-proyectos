-module(p27_taxis_o_rides_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p27_taxis_o_rides_sup:start_link().

stop(_State) ->
  ok.
