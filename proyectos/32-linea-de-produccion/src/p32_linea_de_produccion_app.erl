-module(p32_linea_de_produccion_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p32_linea_de_produccion_sup:start_link().

stop(_State) ->
  ok.
