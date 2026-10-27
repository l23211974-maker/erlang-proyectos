-module(p44_banco_de_sangre_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p44_banco_de_sangre_sup:start_link().

stop(_State) ->
  ok.
