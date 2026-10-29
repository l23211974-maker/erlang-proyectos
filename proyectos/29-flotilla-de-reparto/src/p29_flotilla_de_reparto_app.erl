-module(p29_flotilla_de_reparto_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
  iniciar_json(),
  p29_flotilla_de_reparto_sup:start_link().

stop(_State) ->
  ok.

%% json es una aplicacion aparte en OTP 27 (el Pi) pero vive como modulo
%% dentro de stdlib en otras instalaciones: arrancarla si existe como app;
%% si no, el modulo ya es cargable y no hay nada que hacer.
iniciar_json() ->
  case code:lib_dir(json) of
    {ok, _Dir} ->
      {ok, _} = application:ensure_all_started(json),
      ok;
    {error, _} ->
      ok
  end.
