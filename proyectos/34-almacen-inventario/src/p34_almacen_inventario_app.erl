-module(p34_almacen_inventario_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p34_almacen_inventario_sup:start_link().

stop(_State) ->
  ok.
