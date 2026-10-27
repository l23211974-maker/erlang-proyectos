-module(p38_andon_digital_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p38_andon_digital_sup:start_link().

stop(_State) ->
  ok.
