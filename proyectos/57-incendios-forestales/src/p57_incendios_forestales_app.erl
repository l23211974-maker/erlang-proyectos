-module(p57_incendios_forestales_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p57_incendios_forestales_sup:start_link().

stop(_State) ->
  ok.
