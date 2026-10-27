-module(p24_cruce_cbx_puente_peatonal_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p24_cruce_cbx_puente_peatonal_sup:start_link().

stop(_State) ->
  ok.
