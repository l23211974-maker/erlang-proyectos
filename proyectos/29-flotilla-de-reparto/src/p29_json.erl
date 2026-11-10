-module(p29_json).

%% Traduccion del estado del dominio a JSON para /api/*, /eventos (SSE) y la UI.
%% OTP 27 trae el modulo json: este modulo produce unicamente binarios, enteros,
%% reales, true/false y null (el atomo null se codifica como JSON null; undefined
%% se expone como string, por eso se convierte aqui). Los pids nunca se serializan.

-export([envios/0, envio/1, aeronaves/0, aeronave/1, estado/2,
         instantanea/1, tick_hora/1, json/1]).

%% La hora simulada: 08:00 en el tick 0, 10 s reales de GPS por tick.
-define(HORA_INI, 8 * 3600).
-define(SEC_POR_TICK, 10).

%% ---- envios ---------------------------------------------------------------

envios() ->
  json([envio(M) || M <- p29_datos:envios_todos()]).

envio(M) ->
  {Desde, Hasta} = maps:get(ventana, M, {0, 0}),
  #{<<"id">> => num(maps:get(id, M)),
    <<"estado">> => bin(maps:get(estado, M)),
    <<"origen_iata">> => bin(maps:get(origen_iata, M)),
    <<"destino_iata">> => bin(maps:get(destino_iata, M)),
    <<"peso_kg">> => num(maps:get(peso_kg, M)),
    <<"tipo_carga">> => bin(maps:get(tipo_carga, M)),
    <<"urgente">> => maps:get(urgente, M, false),
    <<"ventana_desde">> => tick_hora(Desde),
    <<"ventana_hasta">> => tick_hora(Hasta),
    <<"desde">> => num(Desde),
    <<"hasta">> => num(Hasta),
    <<"aeronave">> => num(maps:get(aeronave, M, undefined)),
    <<"ruta_id">> => bin(maps:get(ruta_id, M, <<>>)),
    <<"tick_asignado">> => num(maps:get(tick_asignado, M, undefined)),
    <<"tick_entregado">> => num(maps:get(tick_entregado, M, undefined)),
    <<"retraso">> => num(maps:get(retraso, M, undefined)),
    <<"motivo">> => motivo(maps:get(motivo, M, undefined))}.

%% ---- aeronaves --------------------------------------------------------------

aeronaves() ->
  Filas = p29_datos:aeronaves_todas(),
  {Cargas, Entregadas} = cargas_por_aeronave(),
  json([aeronave(M, maps:get(Id, Cargas, 0), maps:get(Id, Entregadas, 0))
        || M <- Filas, Id <- [maps:get(id, M)]]).

aeronave(M) ->
  Id = maps:get(id, M),
  {Cargas, Entregadas} = cargas_por_aeronave(),
  json(aeronave(M, maps:get(Id, Cargas, 0), maps:get(Id, Entregadas, 0))).

aeronave(M, Carga, Entregadas) ->
  Pos = maps:get(pos, M, {0, 0}),
  case Pos of
    undefined -> {Lat, Lon} = {0, 0};
    {Lat, Lon} -> {Lat, Lon}
  end,
  Id = maps:get(id, M),
  Tipo = maps:get(tipo, M),
  FL = val_def(maps:get(fl, M), 0),
  GS = val_def(maps:get(gs, M), 0),
  Estado = maps:get(estado, M, en_tierra),
  UltimoReporte = val_def(maps:get(tick_ultimo_reporte, M), 0),
  Capacidad = val_def(maps:get(capacidad, M), 0),
  Combustible = val_def(maps:get(combustible_pct, M), 100),
  #{<<"id">> => num(Id),
    <<"vuelo">> => vuelo(Id),
    <<"tipo">> => bin(Tipo),
    <<"altitud_ft">> => num(FL * 100),
    <<"velocidad_kts">> => num(GS),
    <<"estado">> => bin(Estado),
    <<"lat">> => num(Lat),
    <<"lon">> => num(Lon),
    <<"ultimo_reporte">> => num(UltimoReporte),
    <<"capacidad_kg">> => num(Capacidad),
    <<"carga_kg">> => Carga,
    <<"entregadas">> => Entregadas,
    <<"combustible_pct">> => num(Combustible)}.

val_def(undefined, Def) -> Def;
val_def(V, _Def) -> V.

%% por aeronave: envios en_ruta (su carga viva) y envios entregados del dia.
%% Se recorre la tabla UNA vez para las 15 filas, no una pasada por unidad.
cargas_por_aeronave() ->
  Func = fun(M, {Cargas, Entregadas}) ->
             case maps:get(aeronave, M, undefined) of
               undefined -> {Cargas, Entregadas};
               Aid ->
                 case maps:get(estado, M) of
                   en_ruta -> {maps:update_with(Aid, fun(N) -> N + maps:get(peso_kg, M, 0) end,
                                                     maps:get(peso_kg, M, 0), Cargas),
                               Entregadas};
                   entregada -> {Cargas,
                                 maps:update_with(Aid, fun(N) -> N + 1 end, 1, Entregadas)};
                   _ -> {Cargas, Entregadas}
                 end
             end
         end,
  lists:foldl(Func, {#{}, #{}}, p29_datos:envios_todos()).

%% ---- resumen ----------------------------------------------------------------

%% Consume el mapa de p29_despachador:estado/0. TickReal distingue el endpoint
%% /api/estado (con tick) de la instantanea por tick del mapa.
estado(Estado, TickReal) ->
  #{<<"envios">> => counters(maps:get(envios, Estado, #{})),
    <<"aeronaves">> => counters(maps:get(aeronaves, Estado, #{})),
    <<"retraso_medio">> => retraso(maps:get(retraso_medio, Estado, 0)),
    <<"reasignaciones">> => num(maps:get(reasignaciones, Estado, 0)),
    <<"transbordos">> => num(maps:get(transbordos, Estado, 0)),
    <<"tick">> => num(TickReal)}.

%% Instantanea por tick para /eventos (SSE): liviana, sin invariantes. La
%% lista de unidades va con la llave "unidades" para no hilarla con el
%% conteo "aeronaves" del resumen.
instantanea(N) ->
  Base = estado(p29_despachador:estado(), N),
  json(Base#{<<"unidades">> => lista_aeronaves()}).

lista_aeronaves() ->
  Filas = p29_datos:aeronaves_todas(),
  {Cargas, Entregadas} = cargas_por_aeronave(),
  [aeronave(M, maps:get(maps:get(id, M), Cargas, 0),
            maps:get(maps:get(id, M), Entregadas, 0)) || M <- Filas].

retraso(R) when is_number(R) -> R;
retraso(_R) -> 0.

%% ---- utilerias JSON ---------------------------------------------------------

json(Terminos) ->
  %% OTP 27 trae json:encode/1 como stdlib; en OTP <= 26 usamos thoas
  case erlang:function_exported(json, encode, 1) of
    true -> json:encode(Terminos);
    false -> thoas:encode(Terminos)
  end.

bin(Valor) when is_atom(Valor) -> atom_to_binary(Valor);
bin(Valor) -> Valor.

num(undefined) -> null;
num(Valor) when is_integer(Valor) -> Valor;
num(Valor) when is_number(Valor) -> round(Valor * 100) / 100.

counters(Conteos) ->
  %% map comprehension de OTP 26+ evitado (y su doble binding tampoco es
  %% sintaxis valida de list comprehension): retrocompatible con OTP 25
  maps:from_list([{bin(Estado), num(maps:get(Estado, Conteos))}
                  || Estado <- maps:keys(Conteos)]).

motivo(undefined) -> null;
motivo(M) when is_atom(M) -> bin(M);
motivo(M) -> M.

%% tick -> "HH:MM" de la jornada simulada (08:00 + 10 s por tick).
tick_hora(Tick) when is_integer(Tick) ->
  Seg = ?HORA_INI + Tick * ?SEC_POR_TICK,
  Horas = Seg div 3600 rem 24,
  Min = Seg rem 3600 div 60,
  iolist_to_binary(io_lib:format("~2..0B:~2..0B", [Horas, Min]));
tick_hora(_) ->
  null.

%% ---- presentacion AeroCargo ---------------------------------------------------

vuelo(Id) when is_integer(Id) ->
  V = 700 + Id,
  <<"AC-", (integer_to_binary(V))/binary>>;  %% AC-701, AC-702, etc.
vuelo(_) ->
  <<"AC-000">>.