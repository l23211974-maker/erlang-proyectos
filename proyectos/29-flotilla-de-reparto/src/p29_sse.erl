-module(p29_sse).
-behaviour(cowboy_loop).
-moduledoc(false).

%% Server-Sent Events del mapa: text/event-stream con un evento "estado" por
%% tick y un latido ":" cada 15 s para que proxies y navegadores no corten la
%% conexion. El handler se suscribe al broadcaster (con monitor) y en
%% terminate se desuscribe; el primer payload de la instantanea sale al
%% conectar para que la UI pinte algo antes del siguiente tick.

-export([init/2, info/3, terminate/3]).

init(Req0, _Estado) ->
  ok = p29_broadcaster:subscribe(self()),
  Req = cowboy_req:stream_reply(
          200,
          #{<<"content-type">> => <<"text/event-stream">>,
            <<"cache-control">> => <<"no-cache">>,
            <<"x-accel-buffering">> => <<"no">>},
          Req0),
  Tick = case whereis(p29_reloj) of
           undefined -> 0;
           _ -> p29_reloj:tick_actual()
         end,
  Body = evento(p29_json:instantanea(Tick)),
  _ = cowboy_req:stream_body(Body, nofin, Req),
  {cowboy_loop, [], 15000}.

info({p29_estado, _N, JSON}, Req, Estado) ->
  _ = cowboy_req:stream_body(evento(JSON), nofin, Req),
  {ok, Req, Estado};
info(timeout, Req, Estado) ->
  _ = cowboy_req:stream_body(<<": latido\n\n">>, nofin, Req),
  {ok, Req, Estado};
info(_Otro, Req, Estado) ->
  {ok, Req, Estado}.

terminate(_Razon, _Req, _Estado) ->
  p29_broadcaster:desuscribir(self()),
  ok.

evento(JSON) ->
  [<<"event: estado\ndata: ">>, JSON, <<"\n\n">>].
