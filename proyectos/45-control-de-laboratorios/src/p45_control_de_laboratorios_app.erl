-module(p45_control_de_laboratorios_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p45_control_de_laboratorios_sup:start_link().

stop(_State) ->
  ok.
