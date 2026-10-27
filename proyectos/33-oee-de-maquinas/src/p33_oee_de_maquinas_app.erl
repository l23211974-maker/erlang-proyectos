-module(p33_oee_de_maquinas_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p33_oee_de_maquinas_sup:start_link().

stop(_State) ->
  ok.
