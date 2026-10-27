-module(p54_gestion_de_agua_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p54_gestion_de_agua_sup:start_link().

stop(_State) ->
  ok.
