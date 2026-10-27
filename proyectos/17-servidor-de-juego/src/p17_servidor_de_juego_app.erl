-module(p17_servidor_de_juego_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p17_servidor_de_juego_sup:start_link().

stop(_State) ->
  ok.
