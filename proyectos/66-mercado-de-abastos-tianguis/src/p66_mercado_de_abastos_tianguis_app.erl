-module(p66_mercado_de_abastos_tianguis_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p66_mercado_de_abastos_tianguis_sup:start_link().

stop(_State) ->
  ok.
