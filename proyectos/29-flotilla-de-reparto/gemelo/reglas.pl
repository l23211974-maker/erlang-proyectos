%% reglas.pl ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â reglas del gemelo digital de la flotilla de reparto (#29)
%%
%% Contrato:
%%   decide(+Entregas, -Plan, -Explicacion)
%%   decide_en(+Ahora, +Entregas, -Plan, -Explicacion)
%%   situacion(?Entidad, ?Situacion, -Evidencia)
%%
%% Toda condicion del dominio distingue tres resultados: si, no, no_se_sabe.
%% Ninguna regla usa el reloj del sistema ni aleatoriedad: el "ahora" entra
%% como parametro y el trafico, las averias y los silencios son hechos.
%%
%% Solo bibliotecas estandar de SWI-Prolog.

:- encoding(utf8).
:- use_module(library(heaps)).
:- use_module(library(lists)).

%% Las ventanas se declaran junto a cada entrega y se amplian con el urgente
%% al final del archivo de hechos.
:- discontiguous ventana/3.
:- discontiguous evento/4.

%% ===========================================================================
%% 1. Mapa y tiempos
%% ===========================================================================

arco(A, B, T) :- tramo(A, B, T).
arco(A, B, T) :- tramo(B, A, T).

%% Un tramo lento observado sustituye al tiempo base en ambos sentidos.
tramo_lento(A, B, T) :- evento(_, tramo_lento, tramo(A, B), T).
tramo_lento(A, B, T) :- evento(_, tramo_lento, tramo(B, A), T).

%% El vecino se enumera primero (arco/3 deja A y B ligados) y solo entonces
%% se pregunta si ese tramo concreto esta lento. Al reves, el if-then-else se
%% comprometia con un unico vecino y Dijkstra veia un grafo incompleto.
tiempo_arco(A, B, T) :-
    arco(A, B, T0),
    (   tramo_lento(A, B, TL)
    ->  T = TL
    ;   T = T0
    ).

%% camino_min(+Origen, +Destino, -Minutos, -Camino)
% Dijkstra sobre pocos nodos; el camino reconstruido sirve para la consulta
% inversa "que rutas tocan este tramo".
camino_min(Origen, Destino, Minutos, Camino) :-
    empty_heap(H0),
    add_to_heap(H0, 0, Origen-[], H1),
    buscar_camino(H1, [], Destino, Minutos, Camino).

buscar_camino(H, Visitados, Destino, Minutos, Camino) :-
    get_from_heap(H, Coste, Nodo-Ruta0, H1),
    (   Nodo == Destino
    ->  Minutos = Coste,
        reverse([Nodo|Ruta0], Camino)
    ;   memberchk(Nodo, Visitados)
    ->  buscar_camino(H1, Visitados, Destino, Minutos, Camino)
    ;   findall(C2-(Hijo-[Nodo|Ruta0]),
                (tiempo_arco(Nodo, Hijo, T), C2 is Coste + T),
                Vecinos),
        insertar_vecinos(Vecinos, H1, H2),
        buscar_camino(H2, [Nodo|Visitados], Destino, Minutos, Camino)
    ).

insertar_vecinos([], H, H).
insertar_vecinos([C-V|Resto], H0, H) :-
    add_to_heap(H0, C, V, H1),
    insertar_vecinos(Resto, H1, H).

tiempo_viaje(O, D, T) :- camino_min(O, D, T, _).

%% ===========================================================================
%% 2. Conocimiento en el tiempo (ocurrio vs se supo)
%% ===========================================================================

%% suceso(+Minuto, +Tipo, +Entidad, +Detalle, -ConocidoEn)
%% Por omision un evento se conoce cuando ocurre. Un reporte en lote puede
%% traer hechos viejos: recepcion/5 fija cuando se supo.
suceso(M, Tipo, Entidad, Detalle, C) :-
    evento(M, Tipo, Entidad, Detalle),
    (   recepcion(M, Tipo, Entidad, Detalle, C0)
    ->  C = C0
    ;   C = M
    ).

sabido(Tipo, Entidad, Detalle, M, Ahora) :-
    suceso(M, Tipo, Entidad, Detalle, C),
    C =< Ahora.

entregada_conocida(E, M, Ahora) :- sabido(entregada, E, _, M, Ahora).
fallida_conocida(E, Motivo, M, Ahora) :- sabido(fallida, E, Motivo, M, Ahora).

%% ===========================================================================
%% 3. Estado de unidades y entregas
%% ===========================================================================

unidades(Uds) :- findall(U, unidad(U, _, _), Uds).
unidades_vivas(Ahora, Uds) :-
    findall(U, (unidad(U, _, _), \+ averiada(U, Ahora)), Uds).

averiada(U, Ahora) :- sabido(averia, U, _, _, Ahora).

%% Ultima lectura conocida de la posicion a la altura de Ahora.
ultima_posicion_en(U, Ahora, P, M) :-
    findall(M0-P0, (lectura(U, posicion, P0, M0), M0 =< Ahora), Pares),
    Pares \== [],
    sort(0, @>=, Pares, [M-P|_]).

%% Ultimo instante del que se tiene conocimiento de la unidad (lectura GPS o
%% reporte en lote). Base para decidir si esta en duda y si una ventana
%% cerrada ya no puede cumplirse.
ultimo_conocimiento_en(U, Ahora, M) :-
    findall(M0, (
                   (   lectura(U, _, _, M0), M0 =< Ahora
                   ;   suceso(M0, reporte_lote, U, _, C), C =< Ahora
                   )
               ), Ms),
    Ms \== [],
    max_list(Ms, M).

ultimo_conocimiento(U, M) :- ahora(Ahora), ultimo_conocimiento_en(U, Ahora, M).

en_duda(U, Ahora) :-
    umbral_silencio(Umbral),
    ultimo_conocimiento_en(U, Ahora, M),
    Ahora - M > Umbral,
    \+ averiada(U, Ahora).

estado_entrega(E, entregada, Ahora) :- entregada_conocida(E, _, Ahora), !.
estado_entrega(E, fallida, Ahora) :- fallida_conocida(E, _, _, Ahora), !.
estado_entrega(E, en_ruta, Ahora) :-
    asignacion_vigente_en(E, Ahora, _, _, _),
    \+ entregada_conocida(E, _, Ahora),
    \+ fallida_conocida(E, _, _, Ahora), !.
estado_entrega(E, pendiente, Ahora) :-
    \+ asignacion_vigente_en(E, Ahora, _, _, _),
    \+ entregada_conocida(E, _, Ahora),
    \+ fallida_conocida(E, _, _, Ahora).

%% Una reasignacion posterior sustituye la asignacion original solo cuando ya
%% ocurrio a la altura de Ahora.
asignacion_vigente(E, U, Orden, M) :-
    ahora(Ahora),
    asignacion_vigente_en(E, Ahora, U, Orden, M).

asignacion_vigente_en(E, Ahora, U, Orden, M) :-
    asignacion(E, U0, Orden, M0),
    (   findall(T-U1, (reasignacion(E, _, U1, T), T =< Ahora), Rs),
        Rs \== []
    ->  sort(0, @>=, Rs, [T-U|_]), M = T
    ;   U = U0, M = M0
    ).

%% Paquete que sigue dentro de la unidad: asignado y ni entregado ni
%% descargado. Una entrega fallida cuenta: el paquete no desaparece.
en_bordo(E, U, Ahora) :-
    asignacion_vigente_en(E, Ahora, U, _, _),
    \+ entregada_conocida(E, _, Ahora).

carga(U, Peso, Volumen, Ahora) :-
    findall(P0-V0, (en_bordo(E, U, Ahora), entrega(E, _, P0, V0)), Pares),
    (   Pares == []
    ->  Peso = 0, Volumen = 0
    ;   pairs_keys_values(Pares, Ps, Vs),
        sum_list(Ps, Peso),
        sum_list(Vs, Volumen)
    ).

capacidad_libre(U, Peso, Volumen, Ahora) :-
    unidad(U, CapP, CapV),
    carga(U, P, V, Ahora),
    Peso is CapP - P,
    Volumen is CapV - V.

%% Entregas asignadas y no entregadas, en orden de ruta.
ruta_pendiente(U, Paradas) :-
    ahora(Ahora),
    ruta_pendiente_en(U, Ahora, Paradas).

ruta_pendiente_en(U, Ahora, Paradas) :-
    findall(O-E, (
                  asignacion_vigente_en(E, Ahora, U, O, _),
                  \+ entregada_conocida(E, _, Ahora)
              ), Pares),
    sort(0, @=<, Pares, Ordenadas),
    findall(E, member(_-E, Ordenadas), Paradas).

%% ===========================================================================
%% 4. Situaciones deducidas (consulta en cualquier direccion)
%% ===========================================================================

%% situacion(?Entidad, ?Situacion, -Evidencia)
situacion(U, en_duda, evidencia{unidad: U, ultimo_conocimiento: M, silencio: S})
        :- unidad(U, _, _), ahora(Ahora), en_duda(U, Ahora),
           ultimo_conocimiento_en(U, Ahora, M), umbral_silencio(Um),
           S is Ahora - M, S > Um.

situacion(U, averiada, evidencia{unidad: U, minuto: M})
        :- unidad(U, _, _), ahora(Ahora), averiada(U, Ahora),
           sabido(averia, U, _, M, Ahora).

situacion(E, huerfana, evidencia{entrega: E, punto: P})
        :- entrega(E, P, _, _), ahora(Ahora),
           estado_entrega(E, pendiente, Ahora).

situacion(E, duplicada, evidencia{entrega: E, unidad_original: U1,
                                  unidad_nueva: U2, desde: T, entregada_en: M})
        :- reasignacion(E, U1, U2, T),
           ahora(Ahora),
           entregada_conocida(E, M, Ahora),
           M >= T, U1 \== U2.

situacion(E, no_ubicable, evidencia{entrega: E, motivo: direccion_mala})
        :- ahora(Ahora), fallida_conocida(E, direccion_mala, _, Ahora).

situacion(tramo(A, B), tramo_lento_hoy, evidencia{tramo: tramo(A, B), minutos: T})
        :- tramo_lento(A, B, T), A @=< B.

situacion(tramo(A, B), toca_a, evidencia{tramo: tramo(A, B), unidades: Uds})
        :- tramo_lento(A, B, _), A @=< B,
           findall(U, unidad_usa_tramo(U, A, B), Uds0),
           sort(Uds0, Uds).

%% Unidad cuyo camino pendiente pasa por el tramo A-B.
unidad_usa_tramo(U, A, B) :-
    unidad(U, _, _),
    ahora(Ahora),
    ultima_posicion_en(U, Ahora, P0, _),
    ruta_pendiente_en(U, Ahora, Paradas),
    findall(P, (member(E, Paradas), entrega(E, P, _, _)), Ps),
    recorre([P0|Ps], A, B).

recorre([_], _, _) :- !, fail.
recorre([P, Q|Resto], A, B) :-
    (   camino_min(P, Q, _, Camino),
        (   append(_, [A, B|_], Camino)
        ;   append(_, [B, A|_], Camino)
        )
    ->  true
    ;   recorre([Q|Resto], A, B)
    ).

%% ===========================================================================
%% 5. Verdad de tres valores
%% ===========================================================================

verdad(si).
verdad(no).
verdad(no_se_sabe).

%% ===========================================================================
%% 6. Situacion 3: la unidad que se callo
%% ===========================================================================

%% veredicto_entrega(+Entrega, +Ahora, -Veredicto, -Evidencia)
veredicto_entrega(E, Ahora, se_entrego, evidencia{minuto: M}) :-
    entregada_conocida(E, M, Ahora), !.
veredicto_entrega(E, Ahora, no_se_entrego, evidencia{motivo: Motivo, minuto: M}) :-
    fallida_conocida(E, Motivo, M, Ahora), !.
veredicto_entrega(E, Ahora, no_se_entrego,
                  evidencia{motivo: ventana_cerrada, ventana: H,
                            conocido_hasta: M}) :-
    asignacion_vigente_en(E, Ahora, U, _, _),
    en_duda_o_estuvo(U, Ahora),
    ventana(E, _, H),
    ultimo_conocimiento_en(U, Ahora, M),
    M > H,
    \+ entregada_conocida(E, _, Ahora), !.
veredicto_entrega(E, Ahora, no_se_sabe,
                  evidencia{motivo: sin_reporte, unidad: U}) :-
    asignacion_vigente_en(E, Ahora, U, _, _),
    en_duda_o_estuvo(U, Ahora),
    \+ entregada_conocida(E, _, Ahora),
    \+ fallida_conocida(E, _, _, Ahora).

%% La unidad estuvo en duda en algun momento hasta Ahora (para no perder el
%% caso "ya reporto, pero su reporte deja entregas sin resolver").
en_duda_o_estuvo(U, Ahora) :-
    (   en_duda(U, Ahora)
    ;   suceso(_, silencio, U, _, C), C =< Ahora
    ).

%% Antes y despues del reporte en lote: la misma regla, hechos nuevos.
silencio(U, Ahora, Reporte, Veredictos) :-
    en_duda_o_estuvo(U, Ahora),
    %% Las entregas que la unidad tenia al callarse: si el despachador ya
    %% reasigno alguna, igual hay que darle su veredicto (y senalar que quedo
    %% duplicada por una decision previa).
    findall(E-V-Ed, (
                       asignacion(E, U, _, _),
                       veredicto_entrega(E, Ahora, V, Ed)
                   ), Veredictos),
    (   suceso(M, reporte_lote, U, _, C), C =< Ahora
    ->  Reporte = reporte(M)
    ;   Reporte = sin_reporte
    ).

%% ===========================================================================
%% 7. Situacion 4: llegada estimada con trafico y horas
%% ===========================================================================

%% llegadas_unidad(+Unidad, +Ahora, -Llegadas)
%% Llegadas = [Entrega-(Minimo-Maximo)-Veredicto]
llegadas_unidad(U, Ahora, Llegadas) :-
    ultima_posicion_en(U, Ahora, P0, _),
    ruta_pendiente_en(U, Ahora, Paradas),
    rango(parada, PMin, PMax),
    acumular_llegadas(Paradas, P0, Ahora, PMin, PMax, Llegadas).

punto_paquete(E, P) :- entrega(E, P, _, _).
punto_paquete(E, P) :- urgente(E, P, _, _).

acumular_llegadas([], _, _, _, _, []).
acumular_llegadas([E|Resto], P0, T0, PMin, PMax, [E-(LMin-LMax)-V|Ls]) :-
    punto_paquete(E, P),
    tiempo_viaje(P0, P, Viaje),
    LMin is T0 + Viaje + PMin,
    LMax is T0 + Viaje + PMax,
    ventana(E, _, Hasta),
    (   LMax =< Hasta
    ->  V = en_ventana
    ;   LMin =< Hasta
    ->  V = depende_de_paradas
    ;   V = tarde
    ),
    acumular_llegadas(Resto, P, LMax, PMin, PMax, Ls).

%% Horas de manejo: tres valores segun el intervalo de duracion de paradas.
alcanza_horas(U, Ahora, V, Evidencia) :-
    horas_restantes(U, Restantes),
    ultima_posicion_en(U, Ahora, P0, _),
    ruta_pendiente_en(U, Ahora, Paradas),
    findall(P, (member(E, Paradas), entrega(E, P, _, _)), Ps),
    recorrido_total([P0|Ps], Viaje),
    rango(parada, PMin, PMax),
    length(Ps, N),
    NecesitaMin is Viaje + N * PMin,
    NecesitaMax is Viaje + N * PMax,
    (   NecesitaMax =< Restantes
    ->  V = si
    ;   NecesitaMin > Restantes
    ->  V = no
    ;   V = no_se_sabe
    ),
    Evidencia = evidencia{restantes: Restantes,
                          necesarios: NecesitaMin-NecesitaMax}.

horas_restantes(U, Restantes) :-
    manejado(U, M),
    max_manejo(Tope),
    Restantes is Tope - M.

recorrido_total([_], 0) :- !.
recorrido_total([A, B|Resto], Total) :-
    tiempo_viaje(A, B, T),
    recorrido_total([B|Resto], R),
    Total is T + R.

%% ===========================================================================
%% 8. Situacion 5: entregas fallidas que siguen a bordo
%% ===========================================================================

%% Que hacer con una entrega fallida.
destino_fallida(E, Ahora, Destino, Evidencia) :-
    fallida_conocida(E, Motivo, _, Ahora),
    asignacion_vigente_en(E, Ahora, U, _, _),
    (   Motivo == direccion_mala
    ->  Destino = no_ubicable,
        Evidencia = evidencia{entrega: E, motivo: direccion_mala,
                              nota: 'sin punto de mapa al que ir'}
    ;   findall(U2, (unidad(U2, _, _), U2 \== U,
                     puede_reintentar(U2, E, Ahora)), Candidatas),
        (   Candidatas = [U3|_]
        ->  Destino = reintento_hoy(U3),
            Evidencia = evidencia{entrega: E, motivo: Motivo, unidad: U3}
        ;   Destino = regreso_almacen,
            Evidencia = evidencia{entrega: E, motivo: Motivo,
                                  nota: 'ninguna unidad pasa por el punto sin romper ventanas'}
        )
    ).

%% Una unidad puede reintentar una fallida si pasa por su punto sin romper su
%% ventana (de reintento si existe) y aun le queda capacidad real.
puede_reintentar(U, E, Ahora) :-
    unidad(U, _, _),
    \+ averiada(U, Ahora),
    \+ en_duda(U, Ahora),
    entrega(E, P, Peso, Vol),
    capacidad_libre(U, LP, LV, Ahora),
    Peso =< LP, Vol =< LV,
    ultima_posicion_en(U, Ahora, P0, _),
    tiempo_viaje(P0, P, T),
    (   reintento(E, Desde, Hasta)
    ->  true
    ;   ventana(E, Desde, Hasta)
    ),
    Ahora + T =< Hasta,
    Ahora + T >= Desde.

%% El paquete fallido ocupa bodega: capacidad que "parecia" libre y no lo es.
impacto_fallida(E, Ahora, U, SinContar, Contando) :-
    fallida_conocida(E, _, _, Ahora),
    asignacion_vigente_en(E, Ahora, U, _, _),
    entrega(E, _, P, V),
    capacidad_libre(U, LP, LV, Ahora),
    SinContar = libre(LSP-LSV),
    LSP is LP + P, LSV is LV + V,
    Contando = libre(LP-LV).

%% ===========================================================================
%% 9. Situacion 1: decide/3 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â reparto de las entregas de una unidad averiada
%% ===========================================================================

decide(Entregas, Plan, Explicacion) :-
    ahora(Ahora),
    decide_en(Ahora, Entregas, Plan, Explicacion).

%% decide_en(+Ahora, +Entregas, -Plan, -Explicacion)
%% Plan = plan([Entrega-Unidad-Orden]). Enumeracion: todas las soluciones.
decide_en(Ahora, Entregas, plan(Asignaciones), Explicacion) :-
    unidades_vivas(Ahora, Uds),
    repartir(Entregas, Uds, Asignaciones),
    validar_plan(Asignaciones, Ahora, ok),
    explicar_plan(Asignaciones, Ahora, Explicacion).

repartir([], _, []).
repartir([E|Es], Uds, [E-U|Resto]) :-
    member(U, Uds),
    repartir(Es, Uds, Resto).

%% Un plan es valido si cabe en peso Y volumen, cumple ventanas, respeta las
%% horas de manejo y contempla la recogida en la unidad averiada.
validar_plan(Asignaciones, Ahora, ok) :-
    agrupar_por_unidad(Asignaciones, Grupos),
    forall(member(U-Entregas, Grupos),
           validar_unidad(U, Entregas, Ahora)).

agrupar_por_unidad(Asignaciones, Grupos) :-
    findall(U, member(_-U, Asignaciones), Us0),
    sort(Us0, Us),
    findall(U-Es, (member(U, Us),
                   findall(E, member(E-U, Asignaciones), Es)), Grupos).

validar_unidad(U, Entregas, Ahora) :-
    capacidad_libre(U, LP, LV, Ahora),
    suma_medidas(Entregas, P, V),
    P =< LP, V =< LV,
    punto_recogida(Ahora, PR),
    ultima_posicion_en(U, Ahora, P0, _),
    tiempo_viaje(P0, PR, TRecogida),
    rango(parada, PMin, _),
    T1 is Ahora + TRecogida + PMin,
    validar_ventanas(Entregas, PR, T1, PMin),
    horas_restantes(U, Restantes),
    recorrido_plan(PR, Entregas, Viaje),
    Necesita is TRecogida + Viaje,
    Necesita =< Restantes.

punto_recogida(Ahora, P) :-
    sabido(averia, U, _, _, Ahora),
    ultima_posicion_en(U, Ahora, P, _), !.

suma_medidas(Entregas, P, V) :-
    findall(P0-V0, (member(E, Entregas), entrega(E, _, P0, V0)), Pares),
    (   Pares == []
    ->  P = 0, V = 0
    ;   pairs_keys_values(Pares, Ps, Vs),
        sum_list(Ps, P), sum_list(Vs, V)
    ).

validar_ventanas([], _, _, _).
validar_ventanas([E|Resto], P0, T0, PMin) :-
    entrega(E, P, _, _),
    tiempo_viaje(P0, P, T),
    Llegada is T0 + T,
    ventana(E, _, Hasta),
    Llegada =< Hasta,
    T1 is Llegada + PMin,
    validar_ventanas(Resto, P, T1, PMin).

recorrido_plan(_, [], 0).
recorrido_plan(P0, [E|Resto], Total) :-
    entrega(E, P, _, _),
    tiempo_viaje(P0, P, T),
    recorrido_plan(P, Resto, R),
    Total is T + R.

%% Explicacion: por que cada entrega va a esa unidad.
explicar_plan([], _, []).
explicar_plan([E-U|Resto], Ahora, [E-U-Motivo|Ms]) :-
    entrega(E, P, Peso, Vol),
    capacidad_libre(U, LP, LV, Ahora),
    suma_previa(Resto, U, PPrev, VPrev),
    LibreP is LP - PPrev, LibreV is LV - VPrev,
    actual_posicion(U, Ahora, P0),
    tiempo_viaje(P0, P, T),
    ventana(E, _, Hasta),
    Motivo = porque{cabe: peso_volumen(Peso, Vol, LibreP, LibreV),
                    desde: P0, punto: P,
                    minutos_de_viaje: T,
                    ventana: Hasta},
    explicar_plan(Resto, Ahora, Ms).

suma_previa(Asignaciones, U, P, V) :-
    findall(P0-V0, (member(E-U, Asignaciones), entrega(E, _, P0, V0)), Pares),
    (   Pares == []
    ->  P = 0, V = 0
    ;   pairs_keys_values(Pares, Ps, Vs),
        sum_list(Ps, P), sum_list(Vs, V)
    ).

actual_posicion(U, Ahora, P) :- ultima_posicion_en(U, Ahora, P, _).

%% Por que NO se puede: motivo por entrega y unidad candidata.
rechazo(E, U, Motivo, Ahora) :-
    entrega(E, _, Peso, Vol),
    unidad(U, _, _),
    capacidad_libre(U, LP, LV, Ahora),
    (   averiada(U, Ahora)
    ->  Motivo = averiada
    ;   en_duda(U, Ahora)
    ->  Motivo = en_duda
    ;   Peso > LP
    ->  Motivo = sin_capacidad_peso(LP)
    ;   Vol > LV
    ->  Motivo = sin_capacidad_volumen(LV)
    ;   horas_restantes(U, R), R =< 0
    ->  Motivo = sin_horas(R)
    ;   entrega(E, P, _, _), actual_posicion(U, Ahora, P0),
        tiempo_viaje(P0, P, T), ventana(E, _, H),
        Ahora + T > H
    ->  Motivo = no_llega_a_ventana(H)
    ;   Motivo = ok
    ).

%% Si no hay plan: que entregas quedan sin cubrir y que restriccion lo impide.
sin_plan(Entregas, SinCubrir) :-
    ahora(Ahora),
    sin_plan_en(Ahora, Entregas, SinCubrir).

sin_plan_en(Ahora, Entregas, Diagnostico) :-
    findall(E-rechazos(Candidatos), (
                       member(E, Entregas),
                       findall(U-M, rechazo(E, U, M, Ahora), Candidatos),
                       \+ member(_-ok, Candidatos)
                   ), Individual),
    (   Individual \== []
    ->  Diagnostico = individual(Individual)
    ;   diagnostico_conjunto(Ahora, Entregas, Diagnostico)
    ).

%% Cada entrega cabe en alguna unidad por separado, pero el conjunto no:
%% el plan falla por capacidad total (peso o volumen) o por ventanas/horas.
diagnostico_conjunto(Ahora, Entregas, Diagnostico) :-
    suma_medidas(Entregas, P, V),
    unidades_vivas(Ahora, Uds),
    findall(CP-CV, (member(U, Uds), capacidad_libre(U, CP, CV, Ahora)), Caps),
    pairs_keys_values(Caps, Cps, Cvs),
    sum_list(Cps, CapP),
    sum_list(Cvs, CapV),
    (   P > CapP
    ->  Diagnostico = capacidad_conjunta(peso_excedido(P-CapP))
    ;   V > CapV
    ->  Diagnostico = capacidad_conjunta(volumen_excedido(V-CapV))
    ;   Diagnostico = ventanas_u_horas_en_conflicto
    ).

%% ===========================================================================
%% 10. Situacion 2: pedido urgente y a quien se le falla
%% ===========================================================================

%% prioridad declarada UNA vez; cambiarla cambia todos los veredictos.
prioridad(urgente, 1, minimizar_entregas_tardias).
prioridad(urgente, 2, minimizar_retraso_total).
prioridad(urgente, 3, minimizar_distancia).

%% evaluar_urgente(+Unidad, +Ahora, -Evaluacion)
evaluar_urgente(U, Ahora, Evaluacion) :-
    unidad(U, _, _),
    (   averiada(U, Ahora)
    ->  Evaluacion = no_candidata(U, averiada)
    ;   en_duda(U, Ahora)
    ->  Evaluacion = no_candidata(U, en_duda)
    ;   capacidad_libre(U, LP, LV, Ahora),
        urgente(_, _, Peso, Vol),
        (   Peso > LP
        ->  Evaluacion = no_candidata(U, sin_capacidad_peso(LP))
        ;   Vol > LV
        ->  Evaluacion = no_candidata(U, sin_capacidad_volumen(LV))
        ;   horas_restantes(U, R), R =< 0
        ->  Evaluacion = no_candidata(U, sin_horas(R))
        ;   findall(EvI, evaluar_insercion(U, Ahora, EvI), Candidatas),
            (   Candidatas == []
            ->  Evaluacion = no_candidata(U, sin_insercion_viable)
            ;   member(Evaluacion, Candidatas)
            )
        )
    ).

%% La mejor insercion de una unidad (menos promesas rotas, luego menos
%% retraso total). Se usa para explicar cada candidata en la interfaz.
mejor_evaluacion(U, Ahora, Ev) :-
    findall(C-EvI, ( evaluar_urgente(U, Ahora, EvI),
                     is_dict(EvI),
                     coste_urgente(EvI, C) ), Pares),
    Pares \== [],
    sort(Pares, [_-Ev|_]).

evaluar_insercion(U, Ahora, evaluacion{unidad: U, posicion: Pos,
                                       retrasos: Retrasos, rompe: Rompe}) :-
    ruta_pendiente_en(U, Ahora, Paradas),
    ultima_posicion_en(U, Ahora, P0, _),
    rango(parada, PMin, _),
    llegadas_base(Paradas, P0, Ahora, PMin, Base),
    urgente(UE, _, _, _),
    ventana(UE, _, Plazo),
    length(Paradas, N),
    N1 is N + 1,
    between(1, N1, Pos),
    insertar_en(Pos, UE, Paradas, Ruta),
    %% el conductor tiene que poder terminar la ruta con el urgente dentro
    rango(parada, _, PMax),
    findall(P, (member(E, Ruta), punto_paquete(E, P)), Ps),
    recorrido_total([P0|Ps], Viaje),
    length(Ruta, NParadas),
    NecesitaMax is Viaje + NParadas * PMax,
    horas_restantes(U, Restantes),
    NecesitaMax =< Restantes,
    llegadas_base(Ruta, P0, Ahora, PMin, Nueva),
    findall(E-R, (
                   nth1(I, Ruta, E), I > Pos,
                   member(E-B, Base),
                   member(E-N2, Nueva),
                   R is N2 - B
               ), Retrasos),
    llegada_de(UE, Nueva, Llegada),
    (   Llegada > Plazo
    ->  Rompe = plazo_urgente(Llegada, Plazo)
    ;   findall(E-Exceso, (
                             member(E-_R, Retrasos),
                             ventana(E, _, H),
                             member(E-B, Base), B =< H,      % antes cabia
                             member(E-N2, Nueva), N2 > H,    % ahora no
                             Exceso is N2 - H
                         ), Rotas),
        (   Rotas == []
        ->  Rompe = ninguna
        ;   Rompe = rompe(Rotas)
        )
    ).

llegadas_base([], _, _, _, []).
llegadas_base([E|Resto], P0, T0, PMin, [E-L|Ls]) :-
    punto_paquete(E, P),
    tiempo_viaje(P0, P, T),
    L is T0 + T + PMin,
    llegadas_base(Resto, P, L, PMin, Ls).

llegada_de(E, Lista, L) :- memberchk(E-L, Lista), !.

insertar_en(1, X, L, [X|L]) :- !.
insertar_en(_, X, [], [X]) :- !.
insertar_en(N, X, [H|T], [H|R]) :-
    N1 is N - 1,
    insertar_en(N1, X, T, R).

%% mejor_urgente(-Unidad, -Evaluacion)
%% Ordena TODAS las evaluaciones: primero las que no rompen ninguna promesa,
%% luego el retraso total. Si ninguna se salva, devuelve la menos mala para
%% poder decir a quien se le falla y por cuanto.
mejor_urgente(U, Ev) :-
    ahora(Ahora),
    findall(Coste-U2-Ev2, (
                evaluar_urgente(U2, Ahora, Ev2),
                is_dict(Ev2),
                get_dict(rompe, Ev2, _),
                coste_urgente(Ev2, Coste)
            ), Todas),
    Todas \== [],
    sort(Todas, [_-U-Ev|_]).

coste_urgente(Ev, Coste) :-
    get_dict(retrasos, Ev, Retrasos),
    get_dict(rompe, Ev, Rompe),
    findall(R, member(_-R, Retrasos), Rs),
    sum_list(Rs, Total),
    (   Rompe == ninguna -> Rotas = 0 ; Rotas = 1 ),
    Coste = Rotas-Total.

%% ===========================================================================
%% 11. Que falta para que cambie
%% ===========================================================================

que_falta(urgente_sin_romper, Alternativas) :-
    ahora(Ahora),
    findall(U, (unidad(U, _, _),
                evaluar_urgente(U, Ahora, Ev),
                is_dict(Ev),
                get_dict(rompe, Ev, ninguna)), Uds0),
    sort(Uds0, Uds),
    (   Uds == []
    ->  Alternativas = [subir_capacidad, ampliar_ventanas, aceptar_un_retraso]
    ;   Alternativas = Uds
    ).

que_falta(plan_averia, Alternativas) :-
    ahora(Ahora),
    sabido(averia, U0, _, _, Ahora),
    findall(E, (asignacion_vigente_en(E, Ahora, U0, _, _),
                estado_entrega(E, pendiente, Ahora)), Entregas),
    (   decide_en(Ahora, Entregas, _, _)
    ->  Alternativas = hay_plan
    ;   Alternativas = sin_plan(Entregas)
    ).
