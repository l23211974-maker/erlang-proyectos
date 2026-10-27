-module(p64_taquilla_de_eventos_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p64_taquilla_de_eventos_sup:start_link().

stop(_State) ->
  ok.
