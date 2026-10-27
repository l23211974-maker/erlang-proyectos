-module(p01_vinedos_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p01_vinedos_sup:start_link().

stop(_State) ->
  ok.
