-module(p29_metrics).
-moduledoc(false).

%% Handler de /metrics (exposicion Prometheus text format v0.0.4). No hay
%% procesos escribiendo por turno: al momento del scrape se vuelcan los
%% contadores vivos del dominio a gauges prometheus.erl y
%% prometheus_text_format los serializa junto a los recolectores de VM.
%% Un scrape recorre la tabla ETS de conteos nada mas (barato).

-export([init/2]).

init(Req0, _Estado) ->
  try actualizar() of
    ok ->
      Cuerpo = prometheus_text_format:format(),
      Req = cowboy_req:reply(
              200,
              #{<<"content-type">> => <<"text/plain; version=0.0.4; charset=utf-8">>},
              Cuerpo, Req0),
      {ok, Req, []}
  catch
    Clase:Razon:Pila ->
      %% el scrape puede fallar apagado, pero jamas debe tumbar al nodo HTTP
      logger:error("metrics fallo: ~p:~p (pila: ~s)",
                   [Clase, Razon,
                    iolist_to_binary(io_lib:format("~p", [Pila]))],
                   #{dominio => flotilla}),
      Req = cowboy_req:reply(500, #{}, <<>>, Req0),
      {ok, Req, []}
  end.

%% Declaracion idempotente (declare es no-op si ya existe) + set del valor
%% vivo del dominio cada scrape.
actualizar() ->
  prometheus:start(),
  declarar(),
  #{entregas := Entregas, vehiculos := Vehiculos,
    retraso_medio := Retraso, reasignaciones := Reasignaciones} =
    p29_despachador:estado(),
  set_familia(p29_flotilla_entregas, Entregas),
  set_familia(p29_flotilla_vehiculos, Vehiculos),
  prometheus_gauge:set(p29_flotilla_retraso_medio, Retraso),
  prometheus_gauge:set(p29_flotilla_reasignaciones_total, Reasignaciones),
  prometheus_gauge:set(p29_flotilla_tick, tick_actual()),
  prometheus_gauge:set(p29_flotilla_invariantes_ok, invariantes_ok()),
  ok.

set_familia(Nombre, Conteos) when is_map(Conteos) ->
  [prometheus_gauge:set(Nombre, [bin(Estado)], Conteo)
   || {Estado, Conteo} <- maps:to_list(Conteos)],
  ok.

%% 1 => ok; 0 => {error, Lista}. La UI de despacho nunca tiene que adivinar:
%% invariantes de negocio siempre visibles para Prometheus.
invariantes_ok() ->
  case p29_despachador:invariantes() of
    ok -> 1;
    {error, _} -> 0
  end.

declarar() ->
  prometheus_gauge:declare(#{name => p29_flotilla_entregas,
                             help => "entregas por estado",
                             labels => [estado]}),
  prometheus_gauge:declare(#{name => p29_flotilla_vehiculos,
                             help => "vehiculos por estado",
                             labels => [estado]}),
  prometheus_gauge:declare(#{name => p29_flotilla_retraso_medio,
                             help => "retraso medio sobre la ventana (ticks)"}),
  prometheus_gauge:declare(#{name => p29_flotilla_reasignaciones_total,
                             help => "reasignaciones acumuladas de la jornada"}),
  prometheus_gauge:declare(#{name => p29_flotilla_tick,
                             help => "tick actual del reloj simulado"}),
  prometheus_gauge:declare(#{name => p29_flotilla_invariantes_ok,
                             help => "invariantes de negocio (1 ok, 0 violadas)"}),
  ok.

%% ---- utilerias ---------------------------------------------------------------

tick_actual() ->
  case whereis(p29_reloj) of
    undefined -> 0;
    _ -> p29_reloj:tick_actual()
  end.

bin(Valor) when is_atom(Valor) -> atom_to_binary(Valor);
bin(Valor) -> Valor.
