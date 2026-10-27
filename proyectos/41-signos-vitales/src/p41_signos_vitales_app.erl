-module(p41_signos_vitales_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p41_signos_vitales_sup:start_link().

stop(_State) ->
  ok.
