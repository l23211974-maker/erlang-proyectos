-module(cowboy_demo_ws_h).
-behaviour(cowboy_websocket).

-export([init/2, websocket_init/1, websocket_handle/2, websocket_info/2]).

-define(GROUP, readings).

init(Req, State) ->
    {cowboy_websocket, Req, State}.

websocket_init(State) ->
    ok = pg:join(?GROUP, self()),
    case cowboy_demo_store:latest() of
        {ok, Reading} -> {[{text, json:encode(Reading)}], State};
        undefined -> {[], State}
    end.

%% A diferencia de SSE, el canal es bidireccional: el cliente puede enviar.
websocket_handle({text, <<"ping">>}, State) ->
    {[{text, <<"pong">>}], State};
websocket_handle({text, _Other}, State) ->
    {[], State};
websocket_handle({binary, _Data}, State) ->
    {[], State};
websocket_handle(ping, State) ->
    {[], State};
websocket_handle(pong, State) ->
    {[], State}.

websocket_info({reading, Reading}, State) ->
    {[{text, json:encode(Reading)}], State}.
