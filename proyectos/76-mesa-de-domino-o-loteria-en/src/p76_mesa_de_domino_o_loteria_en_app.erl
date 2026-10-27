-module(p76_mesa_de_domino_o_loteria_en_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p76_mesa_de_domino_o_loteria_en_sup:start_link().

stop(_State) ->
  ok.
