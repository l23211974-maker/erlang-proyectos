-module(p79_acuacultura_atun_ostion_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p79_acuacultura_atun_ostion_sup:start_link().

stop(_State) ->
  ok.
