-module(p49_estacionamiento_del_campus_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p49_estacionamiento_del_campus_sup:start_link().

stop(_State) ->
  ok.
