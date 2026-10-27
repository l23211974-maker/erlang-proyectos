-module(p73_quiniela_del_mundial_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p73_quiniela_del_mundial_sup:start_link().

stop(_State) ->
  ok.
