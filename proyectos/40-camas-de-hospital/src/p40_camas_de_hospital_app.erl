-module(p40_camas_de_hospital_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p40_camas_de_hospital_sup:start_link().

stop(_State) ->
  ok.
