-module(cowboy_demo_readings_h).
-behaviour(cowboy_handler).

-export([init/2]).

%% Solo GET; cualquier otro metodo recibe 405 en vez de caer en un catch-all.
init(Req0, State) ->
    Req = case cowboy_req:method(Req0) of
        <<"GET">> ->
            cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>},
                             json:encode(cowboy_demo_store:history()), Req0);
        _Other ->
            cowboy_req:reply(405, #{<<"allow">> => <<"GET">>}, Req0)
    end,
    {ok, Req, State}.
