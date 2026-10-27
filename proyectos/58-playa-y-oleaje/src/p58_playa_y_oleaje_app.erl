-module(p58_playa_y_oleaje_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p58_playa_y_oleaje_sup:start_link().

stop(_State) ->
  ok.
