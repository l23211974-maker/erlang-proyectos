-module(p78_cultivo_de_fresa_o_tomate_sa_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p78_cultivo_de_fresa_o_tomate_sa_sup:start_link().

stop(_State) ->
  ok.
