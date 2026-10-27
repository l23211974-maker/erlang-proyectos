-module(p15_cluster_de_2_3_nodos_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p15_cluster_de_2_3_nodos_sup:start_link().

stop(_State) ->
  ok.
