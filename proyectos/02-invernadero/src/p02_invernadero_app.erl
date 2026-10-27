-module(p02_invernadero_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p02_invernadero_sup:start_link().

stop(_State) ->
  ok.
