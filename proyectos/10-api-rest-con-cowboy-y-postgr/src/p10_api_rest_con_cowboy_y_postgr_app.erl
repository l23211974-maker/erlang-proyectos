-module(p10_api_rest_con_cowboy_y_postgr_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p10_api_rest_con_cowboy_y_postgr_sup:start_link().

stop(_State) ->
  ok.
