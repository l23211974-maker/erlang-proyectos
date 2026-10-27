-module(p04_apiario_o_ganado_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p04_apiario_o_ganado_sup:start_link().

stop(_State) ->
  ok.
