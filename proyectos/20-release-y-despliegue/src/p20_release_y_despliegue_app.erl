-module(p20_release_y_despliegue_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p20_release_y_despliegue_sup:start_link().

stop(_State) ->
  ok.
