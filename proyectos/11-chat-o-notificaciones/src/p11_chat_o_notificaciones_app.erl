-module(p11_chat_o_notificaciones_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  p11_chat_o_notificaciones_sup:start_link().

stop(_State) ->
  ok.
