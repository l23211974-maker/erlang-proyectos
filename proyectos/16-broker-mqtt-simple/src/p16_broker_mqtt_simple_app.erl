-module(p16_broker_mqtt_simple_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p16_broker_mqtt_simple_sup:start_link().

stop(_State) ->
  ok.
