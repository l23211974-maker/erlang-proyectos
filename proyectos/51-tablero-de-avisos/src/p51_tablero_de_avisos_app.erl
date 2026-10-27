-module(p51_tablero_de_avisos_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p51_tablero_de_avisos_sup:start_link().

stop(_State) ->
  ok.
