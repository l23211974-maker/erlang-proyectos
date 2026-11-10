-module(p29_api).
-moduledoc(false).

%% Handlers JSON de la API: un mismo modulo, la ruta le dice que accion es
%% (el tercer elemento de la ruta cowboy llega aqui como Accion). Respuestas
%% siempre application/json; charset=utf-8. Las acciones de caos (averiar,
%% urgente) pasan por la API del despachador: nadie escribe ETS fuera de su
%% proceso dueno (ver AGENTS.md).

-export([init/2]).

init(Req0, Accion) ->
  Req =
    case Accion of
      envios ->
        json(Req0, 200, p29_json:envios());
      aeronaves ->
        json(Req0, 200, p29_json:aeronaves());
      %% Backward compat (old ground fleet terminology)
      entregas ->
        json(Req0, 200, p29_json:envios());
      vehiculos ->
        json(Req0, 200, p29_json:aeronaves());
      estado ->
        con_invariantes(Req0);
      averiar ->
        averiar(Req0);
      urgente ->
        urgente(Req0)
    end,
  {ok, Req, []}.

%% POST de caos: averiar una aeronave/unidad explicita.
%% Acepta tanto "aeronave" (nuevo termino) como "unidad" (compatibilidad).
averiar(Req0) ->
  case cuerpo(Req0) of
    {ok, #{<<"aeronave">> := Unidad}} when is_integer(Unidad) ->
      procesar_averia(Unidad, Req0);
    {ok, #{<<"unidad">> := Unidad}} when is_integer(Unidad) ->
      procesar_averia(Unidad, Req0);
    _ ->
      json(Req0, 400, p29_json:json(#{<<"ok">> => false,
                                    <<"error">> => <<"se_espera_aeronave_unidad_entera">>}))
  end.

procesar_averia(Unidad, Req0) ->
  case p29_despachador:averiar(Unidad) of
    ok ->
      json(Req0, 200, p29_json:json(#{<<"ok">> => true, <<"aeronave">> => Unidad,
                                     <<"unidad">> => Unidad}));
    {error, no_existe} ->
      json(Req0, 404, p29_json:json(#{<<"ok">> => false,
                                    <<"error">> => <<"aeronave_inexistente">>,
                                    <<"aeronave">> => Unidad,
                                    <<"unidad">> => Unidad}))
  end.

%% urgente: crear un envio AOG fuera del lote; el greedy lo asigna primero.
%% Acepta terminologia AeroCargo (peso_kg, origen_iata, destino_iata) y
%% compatibilidad hacia atras (peso, colonia).
urgente(Req0) ->
  Parcial = case cuerpo(Req0) of
              {ok, Map} when is_map(Map) ->
                maps:with([<<"peso_kg">>, <<"origen_iata">>, <<"destino_iata">>,
                           <<"peso">>, <<"colonia">>], Map);
              _ -> #{}
            end,
  Id = p29_despachador:urgente(Parcial),
  json(Req0, 200, p29_json:json(#{<<"ok">> => true, <<"envio">> => Id,
                                     <<"entrega">> => Id})).  %% backward compat

con_invariantes(Req0) ->
  Estado = p29_despachador:estado(),
  Tick = tick_actual(),
  Base = p29_json:estado(Estado, Tick),
  case p29_despachador:invariantes() of
    ok ->
      json(Req0, 200, p29_json:json(Base#{<<"invariantes">> => <<"ok">>}));
    {error, _Lista} ->
      json(Req0, 200, p29_json:json(Base#{<<"invariantes">> => <<"violadas">>}))
  end.

%% ---- utilerias ---------------------------------------------------------------

%% cuerpo JSON del POST: vacio, binario no-JSON o array -> {error, vacio};
%% nunca dejamos que un cliente raro tumbe el handler (seria un 500 falso)
cuerpo(Req0) ->
  case cowboy_req:read_body(Req0) of
    {ok, Bin, _Req} when byte_size(Bin) > 0 ->
      try json_decodificar(Bin) of
        Map when is_map(Map) -> {ok, Map};
        _ -> {error, vacio}
      catch
        _:_ -> {error, vacio}
      end;
    _ ->
      {error, vacio}
  end.

%% json:decode/1 unicamente existe en OTP 27+; en OTP <= 26 usa thoas,
%% y se desenvuelve {ok, Termino} para que el resultado sea identico.
json_decodificar(Bin) ->
  case erlang:function_exported(json, decode, 1) of
    true -> json:decode(Bin);
    false ->
      case thoas:decode(Bin) of
        {ok, Termino} -> Termino
      end
  end.

json(Req0, Codigo, Binario) ->
  cowboy_req:reply(Codigo,
                   #{<<"content-type">> => <<"application/json; charset=utf-8">>},
                   Binario, Req0).

tick_actual() ->
  case whereis(p29_reloj) of
    undefined -> 0;
    _ -> p29_reloj:tick_actual()
  end.
