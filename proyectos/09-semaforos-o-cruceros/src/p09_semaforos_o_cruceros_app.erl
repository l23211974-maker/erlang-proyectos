-module(p09_semaforos_o_cruceros_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p09_semaforos_o_cruceros_sup:start_link().

stop(_State) ->
  ok.
