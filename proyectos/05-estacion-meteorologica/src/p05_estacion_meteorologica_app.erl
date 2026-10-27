-module(p05_estacion_meteorologica_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p05_estacion_meteorologica_sup:start_link().

stop(_State) ->
  ok.
