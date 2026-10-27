-module(p36_mantenimiento_predictivo_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p36_mantenimiento_predictivo_sup:start_link().

stop(_State) ->
  ok.
