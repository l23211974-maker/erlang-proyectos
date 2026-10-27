-module(p31_control_de_pista_y_rampa_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p31_control_de_pista_y_rampa_sup:start_link().

stop(_State) ->
  ok.
