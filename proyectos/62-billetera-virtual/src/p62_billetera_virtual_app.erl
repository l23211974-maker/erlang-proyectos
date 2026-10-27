-module(p62_billetera_virtual_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p62_billetera_virtual_sup:start_link().

stop(_State) ->
  ok.
