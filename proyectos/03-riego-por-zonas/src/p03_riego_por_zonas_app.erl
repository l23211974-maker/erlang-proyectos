-module(p03_riego_por_zonas_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p03_riego_por_zonas_sup:start_link().

stop(_State) ->
  ok.
