-module(p30_bicicletas_o_scooters_compar_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p30_bicicletas_o_scooters_compar_sup:start_link().

stop(_State) ->
  ok.
