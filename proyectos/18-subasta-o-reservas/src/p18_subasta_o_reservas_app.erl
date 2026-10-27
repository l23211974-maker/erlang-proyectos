-module(p18_subasta_o_reservas_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p18_subasta_o_reservas_sup:start_link().

stop(_State) ->
  ok.
