-module(p67_centro_de_emergencias_911_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p67_centro_de_emergencias_911_sup:start_link().

stop(_State) ->
  ok.
