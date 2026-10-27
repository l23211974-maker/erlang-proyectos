-module(p71_proteccion_civil_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p71_proteccion_civil_sup:start_link().

stop(_State) ->
  ok.
