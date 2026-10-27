-module(p39_sala_de_urgencias_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p39_sala_de_urgencias_sup:start_link().

stop(_State) ->
  ok.
