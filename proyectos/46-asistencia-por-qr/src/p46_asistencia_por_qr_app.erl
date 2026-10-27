-module(p46_asistencia_por_qr_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p46_asistencia_por_qr_sup:start_link().

stop(_State) ->
  ok.
