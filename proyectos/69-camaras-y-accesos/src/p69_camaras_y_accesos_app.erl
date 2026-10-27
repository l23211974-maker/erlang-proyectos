-module(p69_camaras_y_accesos_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p69_camaras_y_accesos_sup:start_link().

stop(_State) ->
  ok.
