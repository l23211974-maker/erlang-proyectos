-module(p29_flotilla_ct_SUITE).
-behaviour(ct_suite).
-moduledoc(false).

%% Integracion end-to-end contra la APLICACION completa (arranque real de la
%% app, no del supervisor suelto como en eunit). Cubre lo que eunit no toca:
%% los estaticos del dashboard y, sobre todo, la regresion del crash de
%% /eventos (SSE): devolver {cowboy_loop, Estado, Timeout} en vez de
%% {cowboy_loop, Req, Estado, Timeout} mataba el request process en cuanto
%% llegaba el primer mensaje del broadcaster y el mapa del dashboard nunca
%% actualizaba en vivo (function_clause en cowboy_loop:loop).

-include_lib("stdlib/include/assert.hrl").
-compile([export_all, nowarn_export_all]).

-define(APP, p29_flotilla_de_reparto).

%% ---- mapa de la suite --------------------------------------------------------

all() -> [api_flujo_completo, estaticos_del_dashboard, sse_regresion_y_vivos].

init_per_suite(Config) ->
    lists:foreach(
      fun({K, V}) -> application:set_env(?APP, K, V) end,
      [{web_port, 0},                       %% puerto efimero, como eunit
       {vehiculos, 3}, {entregas, 40},      %% flota y carga chicos y contables
       {reloj_auto, true}, {tick_interval_ms, 100},
       {ticks_jornada, 500000},             %% la jornada no cierra en la suite
       {ticks_por_parada, 999999},          %% nada se entrega a medio test
       {sin_senal_ticks, 60}, {prob_fallida, 0.0},
       {capacidad_kg, 2500}, {asignar_al_inicio, true}]),
    {ok, _} = application:ensure_all_started(?APP),
    Puerto = ranch:get_port(p29_web_http),
    inets:start(),
    %% la asignacion greedy es asincrona: espera la pasada inicial completa
    esperar(fun() ->
                    #{entregas := #{en_ruta := 40}} = p29_despachador:estado(),
                    ok
            end, 10000),
    [{puerto, Puerto} | Config].

end_per_suite(_Config) ->
    _ = application:stop(?APP),
    %% p29_web detiene su listener en terminate; no falla si tarda: se mata
    recuperar_web(),
    ok.

recuperar_web() ->
    timer:sleep(300),
    case whereis(p29_web) of
        undefined -> ok;
        PidVivo -> exit(PidVivo, kill)
    end,
    timer:sleep(100),
    ok.

%% ---- 1. API: estado + caos por HTTP sobre la app completa --------------------

api_flujo_completo(Config) ->
    {200, Cuerpo0} = pedir(Config, get, <<"/api/estado">>),
    Estado = json:decode(Cuerpo0),
    ?assertEqual(<<"ok">>, maps:get(<<"invariantes">>, Estado)),
    %% los contadores omiten las llaves en cero: usa get con default
    Entregas0 = maps:get(<<"entregas">>, Estado),
    ?assertEqual(40, maps:get(<<"en_ruta">>, Entregas0, 0)),
    ?assertEqual(0, maps:get(<<"pendiente">>, Entregas0, 0)),
    ?assertEqual(3, maps:get(<<"en_ruta">>, maps:get(<<"vehiculos">>, Estado))),

    %% caos por HTTP: averiar la unidad 1 reasigna su carga
    {200, Cuerpo1} = pedir(Config, post, <<"/api/averiar">>,
                           <<"{\"unidad\":1}">>),
    ?assertMatch(#{<<"ok">> := true, <<"unidad">> := 1},
                 json:decode(Cuerpo1)),
    {200, Cuerpo2} = pedir(Config, get, <<"/api/estado">>),
    Estado2 = json:decode(Cuerpo2),
    ?assertEqual(<<"ok">>, maps:get(<<"invariantes">>, Estado2)),
    ?assert(maps:get(<<"reasignaciones">>, Estado2, 0) >= 1),

    %% unidad inexistente: 404 con JSON, nunca crash
    {404, Cuerpo3} = pedir(Config, post, <<"/api/averiar">>,
                           <<"{\"unidad\":99}">>),
    ?assertMatch(#{<<"ok">> := false}, json:decode(Cuerpo3)).

%% ---- 2. estaticos: el dashboard se sirve completo ------------------------------

estaticos_del_dashboard(Config) ->
    {200, Cuerpo1} = pedir(Config, get, <<"/">>),
    ct:pal("cuerpo de /: ~ts", [Cuerpo1]),
    %% NOTE: en esta OTP binary:match/2 devuelve nomatch | {Begin, Largo}
    ?assertMatch({_Inicio, _Largo},
                 binary:match(Cuerpo1, <<"Flotilla de Reparto">>)),
    {200, _} = pedir(Config, get, <<"/unidad.html">>),
    {200, _} = pedir(Config, get, <<"/historial.html">>),
    {200, _} = pedir(Config, get, <<"/app.css">>),
    ok.

%% ---- 3. regresion SSE: el handler sobrevive a los mensajes del broadcaster ------

sse_regresion_y_vivos(Config) ->
    Puerto = proplists:get_value(puerto, Config),
    {ok, Sock} =
        gen_tcp:connect("127.0.0.1", Puerto,
                        [binary, {active, false}, {packet, raw}]),
    ok = gen_tcp:send(
           Sock,
           <<"GET /eventos HTTP/1.1\r\n"
             "Host: localhost\r\n"
             "Accept: text/event-stream\r\n\r\n">>),
    %% primera respuesta: cabecera 200 + instantanea inicial `event: estado`
    Primero = leer_hasta(Sock, <<"event: estado\n">>, <<>>, 20),
    ?assert(is_binary(Primero)),
    ?assertMatch({_Inicio, _Largo},
                 binary:match(Primero, <<"event: estado\n">>)),
    ?assertMatch({_Inicio, _Largo}, binary:match(Primero, <<"data: ">>)),
    %% advertencia: si el handler muriera en su primer mensaje del
    %% broadcaster, el socket quedaria cerrado aca y esta lectura
    %% devolveria {error, closed}. Con el fix, los eventos por tick
    %% siguen llegando sin cortarse; se reunen con reintentos cortos
    %% para no depender del timing del tick en el hardware lento.
    Segundo = leer_hasta(Sock, <<"data: ">>, <<>>, 20, 800),
    ?assertMatch({_Inicio, _Largo}, binary:match(Segundo, <<"data: ">>)),
    gen_tcp:close(Sock),
    ok.

%% ---- helpers ------------------------------------------------------------------

url(Config, Ruta) ->
    Puerto = proplists:get_value(puerto, Config),
    "http://127.0.0.1:" ++ integer_to_list(Puerto) ++ binary_to_list(Ruta).

pedir(Config, Verbo, Ruta) -> pedir(Config, Verbo, Ruta, []).

pedir(Config, Verbo, Ruta, Cuerpo) when is_atom(Verbo) ->
    Peticion =
        case Cuerpo of
            [] -> {url(Config, Ruta), []};
            _ -> {url(Config, Ruta), [], "application/json", Cuerpo}
        end,
    {ok, Respuesta} =
        httpc:request(Verbo, Peticion,
                      [{timeout, 5000}], [{body_format, binary}]),
    {{_, Codigo, _}, _Cabezera, Body} = Respuesta,
    {Codigo, Body}.

%% acumulacion de fragmentos hasta encontrar el patron (los entregados por
%% tcp pueden llegar repartidos en pedazos cualquiera)
leer_hasta(_Sock, _Patron, Buf, Intentos) when Intentos =< 0 -> Buf;
leer_hasta(Sock, Patron, Buf, Intentos) ->
    leer_hasta(Sock, Patron, Buf, Intentos, 5000).
leer_hasta(_Sock, _Patron, Buf, Intentos, _Milis) when Intentos =< 0 -> Buf;
leer_hasta(Sock, Patron, Buf, Intentos, Milis) ->
    case gen_tcp:recv(Sock, 0, Milis) of
        {ok, Datos} ->
            Buf2 = <<Buf/binary, Datos/binary>>,
            case binary:match(Buf2, Patron) of
                nomatch -> leer_hasta(Sock, Patron, Buf2, Intentos - 1, Milis);
                {_Inicio, _Largo} -> Buf2
            end;
        {error, closed} -> erlang:error({tcp_cerrado, closed, Buf});
        {error, _Otro} when Intentos > 1 ->
            leer_hasta(Sock, Patron, Buf, Intentos - 1, Milis);
        {error, Razon} -> erlang:error({tcp_cerrado, Razon, Buf})
    end.

esperar(Fun) -> esperar(Fun, 10000).
esperar(_Fun, Restante) when Restante =< 0 ->
    error({timeout_esperando});
esperar(Fun, Restante) ->
    case catch Fun() of
        ok ->
            ok;
        _ ->
            timer:sleep(50),
            esperar(Fun, Restante - 50)
    end.
