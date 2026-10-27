-module(p06_estacionamiento_inteligente_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p06_estacionamiento_inteligente_sup:start_link().

stop(_State) ->
  ok.
