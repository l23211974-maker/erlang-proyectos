-module(p25_garitas_san_ysidro_y_otay_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p25_garitas_san_ysidro_y_otay_sup:start_link().

stop(_State) ->
  ok.
