%% janus_tests.pl — pruebas de la integración Janus (Python desde Prolog) #29
%%
%% Ejecutar desde gemelo/:
%%   swipl -g run_tests -t halt tests/janus_tests.pl

:- encoding(utf8).

:- prolog_load_context(directory, Dir),
   atomic_list_concat([Dir, '/../hechos.pl'], Hechos),
   atomic_list_concat([Dir, '/../reglas.pl'], Reglas),
   consult(Hechos),
   consult(Reglas).

:- use_module('../janus_bridge').
:- use_module('../integracion_janus').

:- begin_tests(janus_integracion).

test(janus_disponible_devuelve_modo) :-
    janus_disponible(Modo),
    memberchk(Modo, [nativo, puente]).

test(janus_ping_ok) :-
    once(janus_ping(Info)),
    get_dict(ok, Info, true).

test(lecturas_simuladas_generan_lista) :-
    once(lecturas_simuladas_janus(300, 4, 29, Lecturas)),
    is_list(Lecturas),
    length(Lecturas, 4),
    Lecturas = [Primera|_],
    get_dict(unidad, Primera, _),
    get_dict(minuto, Primera, _),
    get_dict(fuente, Primera, Fuente),
    ( Fuente == "janus_python" ; Fuente == 'janus_python' ).

test(resumen_flota_janus_calcula_en_python) :-
    once(resumen_flota_janus(Resumen)),
    get_dict(generado_por, Resumen, Gen),
    ( Gen == "python_via_janus" ; Gen == 'python_via_janus' ),
    get_dict(total_entregas, Resumen, Total),
    number(Total),
    Total > 0.

test(graficar_entregas_janus_genera_svg) :-
    once(graficar_entregas_janus(R)),
    get_dict(generado_por, R, Gen),
    ( Gen == "python_via_janus" ; Gen == 'python_via_janus' ),
    get_dict(formato, R, Fmt),
    ( Fmt == "svg" ; Fmt == 'svg' ),
    get_dict(archivo, R, Archivo),
    ( atom(Archivo) -> ArchivoAtom = Archivo ; atom_string(ArchivoAtom, Archivo) ),
    exists_file(ArchivoAtom).

test(graficar_llegadas_janus_genera_svg) :-
    once(graficar_llegadas_janus(u1, R)),
    get_dict(formato, R, Fmt),
    ( Fmt == "svg" ; Fmt == 'svg' ),
    get_dict(archivo, R, Archivo),
    ( atom(Archivo) -> ArchivoAtom = Archivo ; atom_string(ArchivoAtom, Archivo) ),
    exists_file(ArchivoAtom).

:- end_tests(janus_integracion).
