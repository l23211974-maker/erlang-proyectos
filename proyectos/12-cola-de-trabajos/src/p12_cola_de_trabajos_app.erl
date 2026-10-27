-module(p12_cola_de_trabajos_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p12_cola_de_trabajos_sup:start_link().

stop(_State) ->
  ok.
