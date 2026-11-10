-module(p29_json).

%% Traduccion del estado del dominio a JSON para /api/*, /eventos (SSE) y la UI.
%% OTP 27 trae el modulo json: este modulo produce unicamente binarios, enteros,
%% reales, true/false y null (el atomo null se codifica como JSON null; undefined
%% se expone como string, por eso se convierte aqui). Los pids nunca se serializan.

-export([entregas/0, entrega/1, vehiculos/0, vehiculo/1, estado/2,
         instantanea/1, tick_hora/1, json/1]).

%% La hora simulada: 08:00 en el tick 0, 10 s reales de GPS por tick.
-define(HORA_INI, 8 * 3600).
-define(SEC_POR_TICK, 10).

%% Destino de presentacion por colonia del despachador (el dominio interno usa
%% la rejilla de colonias; la UI AeroCargo los presenta como redes aereas).
%% MISMA cantidad de entradas que ?COLONIAS de p29_despachador, en el mismo
%% orden: el codigo IATA sale por indice sin tocar el generador determinista.
-define(DESTINOS_CODIGO, [
  <<"MEX">>, <<"GDL">>, <<"CUN">>, <<"MTY">>, <<"TIJ">>, <<"PVR">>,
  <<"SJD">>, <<"QRO">>, <<"MZT">>, <<"LIM">>, <<"BOG">>, <<"SCL">>,
  <<"PTY">>, <<"MGA">>, <<"GUA">>
]).

%% ---- entregas ---------------------------------------------------------------

entregas() ->
  json([entrega(M) || M <- p29_datos:entregas_todas()]).

entrega(M) ->
  {Desde, Hasta} = maps:get(ventana, M, {0, 0}),
  #{<<"id">> => num(maps:get(id, M)),
    <<"estado">> => bin(maps:get(estado, M)),
    <<"colonia">> => bin(maps:get(colonia, M)),
    <<"destino">> => codigo_destino(maps:get(colonia, M)),
    <<"peso">> => num(maps:get(peso, M)),
    <<"urgente">> => maps:get(urgente, M, false),
    <<"ventana_desde">> => tick_hora(Desde),
    <<"ventana_hasta">> => tick_hora(Hasta),
    <<"desde">> => num(Desde),
    <<"hasta">> => num(Hasta),
    <<"vehiculo">> => num(maps:get(vehiculo, M, undefined)),
    <<"tick_asignado">> => num(maps:get(tick_asignado, M, undefined)),
    <<"tick_entregado">> => num(maps:get(tick_entregado, M, undefined)),
    <<"retraso">> => num(maps:get(retraso, M, undefined)),
    <<"motivo">> => motivo(maps:get(motivo, M, undefined))}.

%% ---- vehiculos --------------------------------------------------------------

vehiculos() ->
  Filas = p29_datos:vehiculos_todas(),
  {Cargas, Entregadas} = cargas_por_unidad(),
  json([vehiculo(M, maps:get(Id, Cargas, 0), maps:get(Id, Entregadas, 0))
        || M <- Filas, Id <- [maps:get(id, M)]]).

vehiculo(M) ->
  Id = maps:get(id, M),
  {Cargas, Entregadas} = cargas_por_unidad(),
  json(vehiculo(M, maps:get(Id, Cargas, 0), maps:get(Id, Entregadas, 0))).

vehiculo(M, Carga, Entregadas) ->
  {X, Y} = maps:get(pos, M, {0, 0}),
  Id = maps:get(id, M),
  #{<<"id">> => num(Id),
    %% AeroCargo: cada unidad lleva identificador de vuelo y telemetria
    %% derivada determinista de la pos ( misma entrada -> misma salida,
    %% sin rand: el determinismo del enunciado se conserva).
    <<"vuelo">> => vuelo(Id),
    <<"altitud">> => 30 + (8 * X + 5 * Y) rem 10,
    <<"velocidad">> => 405 + (3 * X + 2 * Y) rem 45,
    <<"estado">> => bin(maps:get(estado, M)),
    <<"x">> => num(X),
    <<"y">> => num(Y),
    <<"ultimo_reporte">> => num(maps:get(ultimo_reporte, M, undefined)),
    <<"capacidad">> => num(maps:get(capacidad, M, undefined)),
    <<"carga">> => Carga,
    <<"entregadas">> => Entregadas}.

%% por unidad: entregas en_ruta (su carga viva) y entregas entregadas del dia.
%% Se recorre la tabla UNA vez para las 15 filas, no una pasada por unidad.
cargas_por_unidad() ->
  Func = fun(M, {Cargas, Entregadas}) ->
             case maps:get(vehiculo, M, undefined) of
               undefined -> {Cargas, Entregadas};
               Vid ->
                 case maps:get(estado, M) of
                   en_ruta -> {maps:update_with(Vid, fun(N) -> N + 1 end, 1, Cargas),
                               Entregadas};
                   entregada -> {Cargas,
                                 maps:update_with(Vid, fun(N) -> N + 1 end, 1, Entregadas)};
                   _ -> {Cargas, Entregadas}
                 end
             end
         end,
  lists:foldl(Func, {#{}, #{}}, p29_datos:entregas_todas()).

%% ---- resumen ----------------------------------------------------------------

%% Consume el mapa de p29_despachador:estado/0. TickReal distingue el endpoint
%% /api/estado (con tick) de la instantanea por tick del mapa.
estado(Estado, TickReal) ->
  #{<<"entregas">> => counters(maps:get(entregas, Estado, #{})),
    <<"vehiculos">> => counters(maps:get(vehiculos, Estado, #{})),
    <<"retraso_medio">> => retraso(maps:get(retraso_medio, Estado, 0)),
    <<"reasignaciones">> => num(maps:get(reasignaciones, Estado, 0)),
    <<"tick">> => num(TickReal)}.

%% Instantanea por tick para /eventos (SSE): liviana, sin invariantes. La
%% lista de unidades va con la llave "unidades" para no hilarla con el
%% conteo "vehiculos" del resumen.
instantanea(N) ->
  Base = estado(p29_despachador:estado(), N),
  json(Base#{<<"unidades">> => lista_vehiculos()}).

lista_vehiculos() ->
  Filas = p29_datos:vehiculos_todas(),
  {Cargas, Entregadas} = cargas_por_unidad(),
  [vehiculo(M, maps:get(maps:get(id, M), Cargas, 0),
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

%% codigo_destino/1: mapea colonia (atom) -> codigo IATA (binario)
%% usa persistent_term para cachear la tabla (se lee una vez por release).
codigo_destino(Colonia) when is_atom(Colonia) ->
  case persistent_term:get({p29_json, destinos}, undefined) of
    undefined ->
      Colonias = p29_despachador:colonias(),
      Tabla = maps:from_list(lists:zip(Colonias, ?DESTINOS_CODIGO)),
      ok = persistent_term:put({p29_json, destinos}, Tabla),
      maps:get(Colonia, Tabla, <<"N/A">>);
    Tabla ->
      maps:get(Colonia, Tabla, <<"N/A">>)
  end;
codigo_destino(_) ->
  <<"N/A">>.
