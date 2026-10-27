-module(p81_gestion_de_ganado_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p81_gestion_de_ganado_sup:start_link().

stop(_State) ->
  ok.
