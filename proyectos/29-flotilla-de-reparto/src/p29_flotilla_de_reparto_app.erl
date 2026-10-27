-module(p29_flotilla_de_reparto_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p29_flotilla_de_reparto_sup:start_link().

stop(_State) ->
  ok.
