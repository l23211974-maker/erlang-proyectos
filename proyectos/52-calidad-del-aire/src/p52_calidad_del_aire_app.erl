-module(p52_calidad_del_aire_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p52_calidad_del_aire_sup:start_link().

stop(_State) ->
  ok.
