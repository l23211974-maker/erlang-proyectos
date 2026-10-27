-module(p53_paneles_solares_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p53_paneles_solares_sup:start_link().

stop(_State) ->
  ok.
