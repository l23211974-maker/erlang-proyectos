-module(p80_cerveceria_artesanal_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p80_cerveceria_artesanal_sup:start_link().

stop(_State) ->
  ok.
