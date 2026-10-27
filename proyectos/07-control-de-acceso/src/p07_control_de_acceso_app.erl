-module(p07_control_de_acceso_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p07_control_de_acceso_sup:start_link().

stop(_State) ->
  ok.
