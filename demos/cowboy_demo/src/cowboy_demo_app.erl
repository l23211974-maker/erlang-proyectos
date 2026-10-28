-module(cowboy_demo_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_Type, _Args) ->
    {ok, Pid} = cowboy_demo_sup:start_link(),
    logger:info("cowboy_demo escuchando", #{port => port()}),
    {ok, Pid}.

stop(_State) ->
    ok.

port() ->
    application:get_env(cowboy_demo, port, 8080).
