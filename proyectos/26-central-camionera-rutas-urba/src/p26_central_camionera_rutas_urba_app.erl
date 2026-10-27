-module(p26_central_camionera_rutas_urba_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p26_central_camionera_rutas_urba_sup:start_link().

stop(_State) ->
  ok.
