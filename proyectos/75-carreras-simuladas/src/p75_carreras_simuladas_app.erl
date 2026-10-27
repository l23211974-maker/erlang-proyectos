-module(p75_carreras_simuladas_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p75_carreras_simuladas_sup:start_link().

stop(_State) ->
  ok.
