-module(p22_torre_de_control_tij_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p22_torre_de_control_tij_sup:start_link().

stop(_State) ->
  ok.
