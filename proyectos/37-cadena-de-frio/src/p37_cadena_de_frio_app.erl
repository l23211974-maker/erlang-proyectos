-module(p37_cadena_de_frio_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p37_cadena_de_frio_sup:start_link().

stop(_State) ->
  ok.
