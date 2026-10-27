-module(p61_cotizador_de_divisas_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p61_cotizador_de_divisas_sup:start_link().

stop(_State) ->
  ok.
