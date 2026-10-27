-module(p63_reservas_de_hotel_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p63_reservas_de_hotel_sup:start_link().

stop(_State) ->
  ok.
