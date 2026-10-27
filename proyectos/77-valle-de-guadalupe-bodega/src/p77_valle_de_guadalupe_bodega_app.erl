-module(p77_valle_de_guadalupe_bodega_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p77_valle_de_guadalupe_bodega_sup:start_link().

stop(_State) ->
  ok.
