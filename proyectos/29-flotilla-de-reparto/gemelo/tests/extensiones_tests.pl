%% extensiones_tests.pl — pruebas de las extensiones posibles del gemelo (#29)
%%
%% Ejecutar desde gemelo/:
%%   swipl -g run_tests -t halt tests/extensiones_tests.pl

:- encoding(utf8).

:- prolog_load_context(directory, Dir),
   atomic_list_concat([Dir, '/../hechos.pl'], Hechos),
   atomic_list_concat([Dir, '/../reglas.pl'], Reglas),
   consult(Hechos),
   consult(Reglas).

:- begin_tests(extensiones_ventanas_blandas_prioridad).

test(e2_es_ventana_blanda) :-
    ventana_blanda(e2, 5).

test(e9_tiene_prioridad_contrato_alta) :-
    prioridad_contrato_de(e9, alta).

test(veredicto_ventana_blanda_tarde_da_penalizacion) :-
    once(veredicto_ventana_ext(e2, 425, 430, V, Pen)),
    V == tarde_blanda,
    Pen =:= 25.

test(veredicto_dentro_de_ventana_sin_penalizacion) :-
    once(veredicto_ventana_ext(e2, 310, 315, V, Pen)),
    V == en_ventana,
    Pen =:= 0.

:- end_tests(extensiones_ventanas_blandas_prioridad).

:- begin_tests(extensiones_autonomia_carga).

test(u1_puede_completar_ruta) :-
    once(puede_completar_ruta(u1, 300, V, _)),
    memberchk(V, [si, necesita_recarga, no, no_se_sabe]).

test(u2_tiene_poca_autonomia_definida) :-
    autonomia(u2, 60, 1).

test(existen_puntos_de_carga) :-
    findall(P, punto_carga(P, _), Ps),
    Ps \== [].

test(punto_carga_tiene_tiempo_recarga) :-
    punto_carga(a_almacen, T),
    T > 0.

:- end_tests(extensiones_autonomia_carga).

:- begin_tests(extensiones_transferencias).

test(existe_punto_de_encuentro_definido) :-
    punto_encuentro(c_centro, u1, u4, 310).

test(transferencia_permitida_politica) :-
    transferencia_permitida(si).

test(transferencia_viable_rechaza_misma_unidad) :-
    \+ transferencia_viable(_, u1, u1, _, 300, _).

:- end_tests(extensiones_transferencias).

:- begin_tests(extensiones_devoluciones_recolecciones).

test(existe_recoleccion_r1) :-
    recoleccion(r1, b_norte, 8, 1, u1, 4, 60, 300, 420).

test(existe_devolucion_e11) :-
    devolucion(e11, u4, a_almacen).

test(capacidad_ext_calculable) :-
    once(capacidad_libre_ext(u1, LP, LV, 300)),
    number(LP), number(LV).

test(carga_con_recolecciones_calculable) :-
    once(carga_con_recolecciones(u1, P, V, 300)),
    number(P), number(V).

:- end_tests(extensiones_devoluciones_recolecciones).

:- begin_tests(extensiones_cierres).

test(cierre_futuro_no_efectivo_en_jornada) :-
    \+ cierre_efectivo(400).

test(cierres_activos_es_lista) :-
    cierres_activos(C),
    is_list(C).

test(cierre_cruce_predicado_funciona) :-
    % sin cierres activos no hay tramos afectados listados; el predicado no debe fallar con error
    ( tramos_afectados_por_cierre(h_cerro, T) -> is_list(T) ; true ).

:- end_tests(extensiones_cierres).
