-module(p21_pruebas_de_caos_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p21_pruebas_de_caos_sup:start_link().

stop(_State) ->
  ok.
