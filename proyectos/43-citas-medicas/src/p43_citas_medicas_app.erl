-module(p43_citas_medicas_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p43_citas_medicas_sup:start_link().

stop(_State) ->
  ok.
