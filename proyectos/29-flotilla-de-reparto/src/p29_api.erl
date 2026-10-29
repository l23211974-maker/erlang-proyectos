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
      entregas ->
        json(Req0, 200, p29_json:entregas());
      vehiculos ->
        json(Req0, 200, p29_json:vehiculos());
      estado ->
        con_invariantes(Req0);
      averiar ->
        averiar(Req0);
      urgente ->
        urgente(Req0)
    end,
  {ok, Req, []}.

%% POST de caos: averiar una unidad explicita. Al matar la unidad, el
%% despachador devuelve sus cargas y el supervisor la relanza vacia.
averiar(Req0) ->
  case cuerpo(Req0) of
    {ok, #{<<"unidad">> := Unidad}} when is_integer(Unidad) ->
      case p29_despachador:averiar(Unidad) of
        ok ->
          json(Req0, 200, json:encode(#{<<"ok">> => true, <<"unidad">> => Unidad}));
        {error, no_existe} ->
          json(Req0, 404, json:encode(#{<<"ok">> => false,
                                        <<"error">> => <<"unidad_inexistente">>,
                                        <<"unidad">> => Unidad}))
      end;
    _ ->
      json(Req0, 400, json:encode(#{<<"ok">> => false,
                                    <<"error">> => <<"se_espera_unidad_entera">>}))
  end.

%% urgente: crear un pedido fuera del lote; el greedy lo asigna primero.
urgente(Req0) ->
  Parcial = case cuerpo(Req0) of
              {ok, Map} when is_map(Map) -> maps:with([<<"peso">>, <<"colonia">>], Map);
              _ -> #{}
            end,
  Id = p29_despachador:urgente(Parcial),
  json(Req0, 200, json:encode(#{<<"ok">> => true, <<"entrega">> => Id})).

con_invariantes(Req0) ->
  Estado = p29_despachador:estado(),
  Tick = tick_actual(),
  Base = p29_json:estado(Estado, Tick),
  case p29_despachador:invariantes() of
    ok ->
      json(Req0, 200, json:encode(Base#{<<"invariantes">> => <<"ok">>}));
    {error, _Lista} ->
      json(Req0, 200, json:encode(Base#{<<"invariantes">> => <<"violadas">>}))
  end.

%% ---- utilerias ---------------------------------------------------------------

%% cuerpo JSON del POST: vacio, binario no-JSON o array -> {error, vacio};
%% nunca dejamos que un cliente raro tumbe el handler (seria un 500 falso)
cuerpo(Req0) ->
  case cowboy_req:read_body(Req0) of
    {ok, Bin, _Req} when byte_size(Bin) > 0 ->
      try json:decode(Bin) of
        Map when is_map(Map) -> {ok, Map};
        _ -> {error, vacio}
      catch
        _:_ -> {error, vacio}
      end;
    _ ->
      {error, vacio}
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
