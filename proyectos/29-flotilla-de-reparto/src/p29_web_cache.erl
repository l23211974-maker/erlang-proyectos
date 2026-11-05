-module(p29_web_cache).
-behaviour(cowboy_middleware).

%% Middleware del listener: instala Cache-Control: no-cache en TODA respuesta
%% (estaticos, /api/*, /eventos, /metrics). Sin esta cabecera los navegadores
%% aplican cacheo heuristico y pueden pintar una mezcla de HTML/JS de epocas
%% distintas del proyecto; con ello los botones de la UI asumian handlers
%% inexistentes y "no hacian nada" (bug observado en Brave). Con no-cache el
%% navegador revalida via ETag en cada recarga (respuesta 304 rapida) y la UI
%% siempre llega coherente con el codigo en produccion.

-export([execute/2]).

execute(Req0, Env) ->
  Req = cowboy_req:set_resp_headers(
          #{<<"cache-control">> => <<"no-cache, must-revalidate">>}, Req0),
  {ok, Req, Env}.
