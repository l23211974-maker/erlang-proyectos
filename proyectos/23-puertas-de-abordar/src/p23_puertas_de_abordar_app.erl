-module(p23_puertas_de_abordar_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p23_puertas_de_abordar_sup:start_link().

stop(_State) ->
  ok.
