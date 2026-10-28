-module(cowboy_demo_health_h).
-behaviour(cowboy_handler).

-export([init/2]).

init(Req0, State) ->
    Body = json:encode(#{status => <<"ok">>,
                         otp => list_to_binary(erlang:system_info(otp_release)),
                         schedulers => erlang:system_info(schedulers_online)}),
    Req = cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>},
                           Body, Req0),
    {ok, Req, State}.
