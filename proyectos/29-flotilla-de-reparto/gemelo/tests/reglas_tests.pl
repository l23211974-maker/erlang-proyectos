%% reglas_tests.pl â€” pruebas plunit del gemelo digital (#29)
%%
%% Ejecutar desde gemelo/:
%%   swipl -g run_tests -t halt tests/reglas_tests.pl
%%
%% Al menos una prueba por situacion de PROBLEMA.md, mas las del contrato
%% (tres valores, explicacion, todas las soluciones, consulta inversa).

:- encoding(utf8).

%% Las pruebas de consulta inversa insertan hechos nuevos, asi que estos
%% predicados tienen que ser dinamicos ANTES de cargar hechos.pl.
:- dynamic(entrega/4).
:- dynamic(ventana/3).

:- prolog_load_context(directory, Dir),
   atomic_list_concat([Dir, '/../hechos.pl'], Hechos),
   atomic_list_concat([Dir, '/../reglas.pl'], Reglas),
   consult(Hechos),
   consult(Reglas).

%% Helpers de alta/baja de hechos temporales. Se declaran aqui (modulo user)
%% porque el cuerpo de un test plunit corre en el modulo del bloque y un
%% assertz/1 alli dentro crearia contrato:entrega/4 en vez del user:entrega/4
%% que consultan las reglas.
alta_entrega_temporal(E, P, W, V, Hasta) :-
    assertz(entrega(E, P, W, V)),
    assertz(ventana(E, 300, Hasta)).

baja_entrega_temporal(E) :-
    retract(entrega(E, _, _, _)),
    retract(ventana(E, _, _)).

:- begin_tests(averia).

%% Situacion 1: la unidad averiada (u3) y sus cuatro entregas pendientes.
entregas_averia([e4, e7, e10, e12]).

test(decide_cubre_cada_entrega_exactamente_una_vez, [nondet]) :-
    entregas_averia(Es),
    decide_en(180, Es, plan(Asigs), _),
    msort(Es, Ordenadas),
    findall(E, member(E-_, Asigs), Cubiertas0),
    msort(Cubiertas0, Cubiertas),
    Cubiertas == Ordenadas.

test(todos_los_planes_validos) :-
    entregas_averia(Es),
    findall(P, decide_en(180, Es, P, _), Planes),
    length(Planes, N),
    N > 1.

test(respeta_capacidad_en_peso_y_volumen, [nondet]) :-
    entregas_averia(Es),
    decide_en(180, Es, plan(Asigs), _),
    agrupar_por_unidad(Asigs, Grupos),
    forall(member(U-G, Grupos),
           ( capacidad_libre(U, LP, LV, 180),
             suma_medidas(G, P, V),
             P =< LP, V =< LV )).

test(no_deja_huerfanas_ni_duplicadas, [nondet]) :-
    entregas_averia(Es),
    decide_en(180, Es, plan(Asigs), _),
    forall(member(E, Es),
           ( findall(U, member(E-U, Asigs), Us),
             Us = [_] )).

test(no_mueve_lo_que_no_hacia_falta, [nondet]) :-
    entregas_averia(Es),
    decide_en(180, Es, plan(_), _),
    %% las asignaciones de u1 que no estaban en juego siguen intactas
    asignacion_vigente_en(e1, 180, u1, 1, _),
    asignacion_vigente_en(e2, 180, u1, 2, _),
    asignacion_vigente_en(e9, 180, u1, 3, _).

test(explica_por_que_a_cada_unidad, [nondet]) :-
    entregas_averia(Es),
    decide_en(180, Es, _, Explicacion),
    length(Explicacion, N),
    length(Es, N),
    forall(member(_E-_U-Motivo, Explicacion), is_dict(Motivo)).

test(sin_plan_dice_que_restriccion_lo_impide) :-
    %% siete entregas que por separado caben, pero juntas exceden el volumen
    Imp = [e1, e2, e3, e4, e7, e10, e12],
    \+ decide_en(180, Imp, _, _),
    sin_plan_en(180, Imp, capacidad_conjunta(volumen_excedido(Falta))),
    Falta > 0.

:- end_tests(averia).

:- begin_tests(urgente).

%% Situacion 2: entra un urgente y hay que decidir a quien se le falla.
test(no_elige_la_unidad_mas_cercana_por_ser_la_mas_cercana) :-
    mejor_urgente(U, _),
    ultima_posicion_en(u1, 300, P1, _),
    ultima_posicion_en(U, 300, PU, _),
    urgente(ue1, Punto, _, _),
    tiempo_viaje(P1, Punto, T1),
    tiempo_viaje(PU, Punto, TU),
    %% u1 esta mas cerca y aun asi no es la elegida
    U \== u1,
    T1 < TU.

test(explica_por_candidata_que_retrasa_y_cuanto, [nondet]) :-
    evaluar_urgente(u1, 300, Ev1),
    get_dict(retrasos, Ev1, R1),
    R1 \== [],
    evaluar_urgente(u4, 300, Ev4),
    get_dict(retrasos, Ev4, R4),
    R4 \== [].

test(la_prioridad_vive_en_un_solo_lugar) :-
    findall(P, prioridad(urgente, _, P), Ps),
    length(Ps, 3).

:- end_tests(urgente).

:- begin_tests(silencio).

%% Situacion 3: u2 pasa una hora sin senal y luego reporta en lote.
test(antes_del_reporte_todo_es_no_se_sabe) :-
    forall(asignacion_vigente_en(E, 280, u2, _, _),
           veredicto_entrega(E, 280, no_se_sabe, _)).

test(el_reporte_cambia_el_pasado) :-
    once(veredicto_entrega(e5, 280, no_se_sabe, _)),
    once(veredicto_entrega(e5, 300, se_entrego, evidencia{minuto: 275})).

%% Las cuatro entregas originales de u2 (incluida e5, que el despachador
%% reasigno a u1 durante el silencio): cada una con su veredicto propio.
test(cada_entrega_recibe_su_propio_veredicto) :-
    findall(V, (asignacion(E, u2, _, _),
                veredicto_entrega(E, 300, V, _)), Vs),
    sort(Vs, Estados),
    Estados == [no_se_entrego, no_se_sabe, se_entrego].

test(lo_dudoso_no_se_trata_como_hecho) :-
    %% e14 sigue en ventana: no se puede afirmar ni negar
    veredicto_entrega(e14, 300, no_se_sabe, _).

test(detecta_duplicada_por_una_decision_previa) :-
    once(situacion(e5, duplicada, Ev)),
    get_dict(unidad_original, Ev, u2),
    get_dict(unidad_nueva, Ev, u1).

:- end_tests(silencio).

:- begin_tests(llegada).

%% Situacion 4: llegada estimada encadenando tramos y paradas.
test(encadena_tramos_y_paradas) :-
    once(llegadas_unidad(u1, 300, Llegadas)),
    memberchk(e1-(Min-Max)-en_ventana, Llegadas),
    Min < Max.

test(tres_veredictos_posibles) :-
    findall(V, (member(U, [u1, u2, u4]),
                llegadas_unidad(U, 300, L),
                member(_-(_-_)-V, L)), Vs),
    sort(Vs, Unicos),
    Unicos == [depende_de_paradas, en_ventana, tarde].

test(un_tramo_lento_marca_las_rutas_que_lo_tocan) :-
    once(situacion(tramo(c_centro, d_sur), toca_a, Ev)),
    get_dict(unidades, Ev, Uds),
    memberchk(u1, Uds).

test(la_consulta_inversa_usa_las_mismas_reglas) :-
    %% la ruta de u1 toca el tramo lento, y no al reves
    unidad_usa_tramo(u1, c_centro, d_sur),
    \+ unidad_usa_tramo(u2, c_centro, d_sur).

test(detecta_al_conductor_sin_horas) :-
    alcanza_horas(u2, 300, no, _),
    alcanza_horas(u1, 300, si, _).

:- end_tests(llegada).

:- begin_tests(fallida).

%% Situacion 5: la entrega fallida sigue a bordo y ocupa bodega.
test(direccion_mala_es_no_ubicable) :-
    once(destino_fallida(e11, 300, no_ubicable, _)).

test(el_paquete_fallido_cuenta_contra_la_capacidad) :-
    impacto_fallida(e8, 300, u4, SinContar, Contando),
    SinContar == libre(49-5),
    Contando == libre(37-4).

test(reintento_hoy_si_una_unidad_pasa_por_el_punto) :-
    destino_fallida(e8, 300, reintento_hoy(u1), _).

test(situacion_no_ubicable_se_consulta_al_reves) :-
    findall(E, situacion(E, no_ubicable, _), Es),
    Es == [e11].

:- end_tests(fallida).

:- begin_tests(contrato).

test(la_verdad_tiene_tres_valores) :-
    findall(V, verdad(V), Vs),
    Vs == [si, no, no_se_sabe].

test(una_entrega_suelta_tambien_se_planea) :-
    once(decide_en(180, [e4], plan([e4-U|_]), _)),
    memberchk(U, [u1, u2, u4]).

test(huerfana_se_deduce_de_los_hechos) :-
    setup_call_cleanup(
        alta_entrega_temporal(e15, f_oeste, 7, 1, 360),
        once(situacion(e15, huerfana, Ev)),
        baja_entrega_temporal(e15)),
    get_dict(entrega, Ev, e15).

test(situacion_es_consultable_en_cualquier_direccion) :-
    findall(X-S, situacion(X, S, _), Pares),
    memberchk(u3-averiada, Pares),
    memberchk(e11-no_ubicable, Pares),
    memberchk(tramo(c_centro, d_sur)-tramo_lento_hoy, Pares).

:- end_tests(contrato).
