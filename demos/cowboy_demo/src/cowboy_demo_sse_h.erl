-module(cowboy_demo_sse_h).
-behaviour(cowboy_loop).

-export([init/2, info/3]).

-define(GROUP, readings).

init(Req0, State) ->
    Req = cowboy_req:stream_reply(200, #{
        <<"content-type">> => <<"text/event-stream">>,
        <<"cache-control">> => <<"no-cache">>
    }, Req0),
    %% pg saca al proceso del grupo cuando muere; no hace falta leave/terminate.
    ok = pg:join(?GROUP, self()),
    case cowboy_demo_store:latest() of
        {ok, Reading} -> send(Reading, Req);
        undefined -> ok
    end,
    {cowboy_loop, Req, State}.

info({reading, Reading}, Req, State) ->
    send(Reading, Req),
    {ok, Req, State}.

send(Reading, Req) ->
    cowboy_req:stream_body(["data: ", json:encode(Reading), "\n\n"], nofin, Req).
