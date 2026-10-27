-module(p14_acortador_de_urls_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p14_acortador_de_urls_sup:start_link().

stop(_State) ->
  ok.
