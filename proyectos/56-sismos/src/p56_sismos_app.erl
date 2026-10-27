-module(p56_sismos_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p56_sismos_sup:start_link().

stop(_State) ->
  ok.
