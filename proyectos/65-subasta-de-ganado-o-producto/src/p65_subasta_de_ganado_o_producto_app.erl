-module(p65_subasta_de_ganado_o_producto_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p65_subasta_de_ganado_o_producto_sup:start_link().

stop(_State) ->
  ok.
