-module(p68_alarmas_de_domicilio_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p68_alarmas_de_domicilio_sup:start_link().

stop(_State) ->
  ok.
