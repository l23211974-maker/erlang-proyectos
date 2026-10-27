-module(p74_radio_o_streaming_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p74_radio_o_streaming_sup:start_link().

stop(_State) ->
  ok.
