-module(p28_puerto_de_ensenada_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p28_puerto_de_ensenada_sup:start_link().

stop(_State) ->
  ok.
