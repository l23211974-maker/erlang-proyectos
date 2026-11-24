%% servidor.pl ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â servidor web del gemelo digital (#29)
%%
%% Arranque:
%%   swipl servidor.pl              (puerto 8089)
%%   $env:GEMELO_PORT=8090; swipl servidor.pl
%%
%% Expone el estado del gemelo y las cinco situaciones como JSON bajo /api/.
%% La interfaz de web/ SOLO consulta y pinta: ninguna regla del dominio vive
%% aqui ni en el JavaScript; este archivo solo traduce terminos de reglas.pl
%% a JSON.
%%
%% Solo bibliotecas estandar de SWI-Prolog.

:- encoding(utf8).

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_files)).
:- use_module(library(http/http_parameters)).
:- use_module(library(lists)).

%% El directorio de web/ se guarda como hecho: nb_setval es por hilo y los
%% handlers corren en hilos del pool de httpd.
:- dynamic(gemelo_web/1).
:- discontiguous manejar/2.

:- prolog_load_context(directory, Dir),
   atomic_list_concat([Dir, '/hechos.pl'], Hechos),
   atomic_list_concat([Dir, '/reglas.pl'], Reglas),
   atomic_list_concat([Dir, '/web'], Web),
   consult(Hechos),
   consult(Reglas),
   use_module(Dir/janus_bridge),
   use_module(Dir/integracion_janus),
   assertz(gemelo_web(Web)).

:- http_handler(root(api/estado),       api(estado),       []).
:- http_handler(root(api/plan),         api(plan),         []).
:- http_handler(root(api/urgente),      api(urgente),      []).
:- http_handler(root(api/silencio),     api(silencio),     []).
:- http_handler(root(api/llegadas),     api(llegadas),     []).
:- http_handler(root(api/fallidas),     api(fallidas),     []).
:- http_handler(root(api/que_falta),    api(que_falta),    []).
:- http_handler(root(api/prioridad),    api(prioridad),    []).
:- http_handler(root(api/extensiones),  api(extensiones),  []).
:- http_handler(root(api/janus),        api(janus),        []).
:- http_handler(root(.),                estaticos,         [prefix]).

%% ---------------------------------------------------------------------------
%% Arranque
%% ---------------------------------------------------------------------------

:- initialization(main, main).

main :-
    puerto(Puerto),
    http_server(http_dispatch, [port(Puerto)]),
    gemelo_web(Web),
    format("gemelo digital #29 en http://127.0.0.1:~w/~n", [Puerto]),
    format("interfaz: ~w/index.html~n", [Web]),
    thread_get_message(_).       % el hilo principal mantiene vivo el server

puerto(P) :-
    current_prolog_flag(argv, Args),
    (   member(A, Args), atom_number(A, N), integer(N)
    ->  P = N
    ;   catch(getenv('GEMELO_PORT', S), _, fail),
        atom_number(S, N2)
    ->  P = N2
    ;   P = 8089
    ).

%% ---------------------------------------------------------------------------
%% Estaticos (web/)
%% ---------------------------------------------------------------------------

%% El handler es de tipo prefijo (ver el registro con [prefix] mas abajo), asi
%% que a / le llega sin path_info y a /style.css le llega path_info('style.css').
estaticos(Request) :-
    gemelo_web(Dir),
    (   memberchk(path_info(PathInfo), Request) -> true
    ;   PathInfo = ''
    ),
    (   PathInfo == ''
    ->  Rel = 'index.html'
    ;   atomic(PathInfo),
        \+ sub_atom(PathInfo, _, _, _, '..'),
        Rel = PathInfo
    ),
    atomic_list_concat([Dir, '/', Rel], Archivo),
    (   exists_file(Archivo)
    ->  http_reply_file(Archivo, [unsafe(true)], Request)
    ;   throw(http_reply(not_found(Rel)))
    ).

%% ---------------------------------------------------------------------------
%% Despacho JSON
%% ---------------------------------------------------------------------------

api(Que, Request) :-
    catch(manejar(Que, Request),
          Error,
          ( format(string(Detalle), "~w", [Error]),
            format(user_error, "api ~w: ~w~n", [Que, Detalle]),
            reply_json_dict(_{error: error_interno, que: Que, detalle: Detalle},
                            [status(500)]) )).



%% ---------------------------------------------------------------------------
%% /api/extensiones - extensiones posibles implementadas
%% ---------------------------------------------------------------------------

extensiones_json(Json) :-
    ahora(Ahora),
    % 1) Ventanas blandas y prioridad por contrato
    findall(_{entrega:E, penalizacion_por_minuto:P}, ventana_blanda(E,P), Blandas),
    findall(_{entrega:E, prioridad:N}, (prioridad_contrato(E,N), N \== normal), Contratos),
    % 2) Autonomia y puntos de carga
    findall(_{unidad:U, autonomia:A, consumo:C, estado:V, evidencia:Ev},
            (unidad(U,_,_), puede_completar_ruta(U,Ahora,V,Ev), autonomia(U,A,C)), Autonomias),
    findall(_{punto:P, recarga_minutos:T}, punto_carga(P,T), PuntosCarga),
    % 3) Transferencias a medio camino
    findall(_{entrega:E, de:U1, a:U2, punto:Pt, minuto:M},
            ( transferencia_viable(E,U1,U2,Pt,Ahora,Det),
              get_dict(minuto, Det, M)
            ), Transferencias),
    findall(_{punto:Pt, u1:U1, u2:U2, minuto:M}, punto_encuentro(Pt,U1,U2,M), Encuentros),
    % 4) Devoluciones y recolecciones
    findall(_{id:R, punto:Pt, peso:P, volumen:V, unidad:U, orden:O, ventana:D-H},
            recoleccion(R,Pt,P,V,U,O,_,D,H), Recolecciones),
    findall(_{entrega:E, unidad:U, punto_devolucion:Pt}, devolucion(E,U,Pt), Devoluciones),
    findall(_{unidad:U, peso:Peso, volumen:Vol, capacidad_ext:libre(LP-LV)},
            (unidad(U,_,_), capacidad_libre_ext(U,LP,LV,Ahora), carga_con_recolecciones(U,Peso,Vol,Ahora)), CapExt),
    % 5) Cierres de calle/cruce
    cierres_activos(CierresA),
    findall(_{evento:futuro, minuto:M, entidad:Ent, detalle:D},
            (evento(M,cierre,Ent,D), \+ cierre_efectivo(M)), CierresFuturos),
    Json = _{ ahora: Ahora,
              ventanas_blandas_prioridad: _{blandas: Blandas, prioridad_contrato: Contratos},
              autonomia_y_carga: _{unidades: Autonomias, puntos_carga: PuntosCarga},
              transferencias: _{permitidas: si, encuentros: Encuentros, viables_ahora: Transferencias},
              devoluciones_recolecciones: _{recolecciones: Recolecciones, devoluciones: Devoluciones, capacidad_efectiva: CapExt},
              cierres: _{activos: CierresA, programados_fuera_jornada: CierresFuturos} }.

%% Traduce cualquier termino del dominio a algo que json_write_dict/1 acepte:
%% dicts y listas se recorren, atomos y numeros se dejan, y un termino
%% compuesto (tramo(c,d), reintento_hoy(u1), peso_volumen(...)) se manda como
%% texto legible en vez de romper la respuesta.
a_json(Var, @(null)) :- var(Var), !.   % valor ausente: null en el JSON, nunca un 500
a_json(D0, D) :- is_dict(D0), !,
    dict_pairs(D0, Etiqueta, Pares0),
    maplist(a_json_par, Pares0, Pares),
    dict_pairs(D, Etiqueta, Pares).
a_json(L0, L) :- is_list(L0), !, maplist(a_json, L0, L).
a_json(A, A) :- atomic(A), !.
a_json(C, Texto) :- compound(C), !,
    format(string(Texto), '~w', [C]).

a_json_par(K0-V0, K-V) :- a_json(K0, K), a_json(V0, V).

responder(D0) :- a_json(D0, D), reply_json_dict(D).

manejar(estado, _)  :- estado_json(Json), responder(Json).
manejar(plan, R)    :- plan_json(R, Json), responder(Json).
manejar(urgente, _) :- urgente_json(Json), responder(Json).
manejar(silencio, R) :- silencio_json(R, Json), responder(Json).
manejar(llegadas, R) :- llegadas_json(R, Json), responder(Json).
manejar(fallidas, _) :-
    findall(F, fallida_json(F), Fallidas),
    responder(_{fallidas: Fallidas}).

manejar(que_falta, R) :-
    param(R, 'objetivo', "urgente_sin_romper", Objetivo0),
    atom_string(Objetivo, Objetivo0),
    (   que_falta(Objetivo, Alternativas)
    ->  responder(_{objetivo: Objetivo, alternativas: Alternativas})
    ;   responder(_{objetivo: Objetivo,
                          alternativas: [sin_respuesta_para_ese_objetivo]})
    ).

manejar(prioridad, _) :-
    findall(_{orden: O, criterio: C}, prioridad(urgente, O, C), P),
    responder(_{prioridad: P}).

%% Lee un parametro de la URL sin declarar atributos (la forma de 3 argumentos
%% de http_parameters no exige declaracion).
param(Request, Nombre, Defecto, Valor) :-
    Espec =.. [Nombre, V0, [default(Defecto), optional(true)]],
    catch(http_parameters(Request, [Espec]), _, fail),
    !,
    (   V0 == ''
    ->  Valor = Defecto
    ;   Valor = V0
    ).
param(_, _, Defecto, Defecto).



%% ---------------------------------------------------------------------------
%% /api/janus - integración Python desde Prolog (Janus/puente py_call)
%% ---------------------------------------------------------------------------

manejar(janus, Request) :-
    param(Request, 'accion',  estado, Accion0),
    atom_string(Accion, Accion0),
    manejar_janus(Accion, Request).

manejar_janus(estado, _) :-
    janus_estado(E), responder(E).
manejar_janus(ping, _) :-
    janus_ping(I), responder(_{accion: ping, resultado: I}).
manejar_janus(lecturas, Request) :-
    param(Request, 'cantidad', 8, C0),
    ( catch(atom_number(C0, C), _, fail) -> Cant = C ; Cant = 8 ),
    ( ahora(A) -> Ahora = A ; Ahora = 300 ),
    lecturas_simuladas_janus(Ahora, Cant, 29, Lecturas),
    responder(_{accion: lecturas, ahora: Ahora, cantidad: Cant, lecturas: Lecturas}).
manejar_janus(resumen, _) :-
    resumen_flota_janus(R), responder(_{accion: resumen, resultado: R}).
manejar_janus(graficar, _) :-
    graficar_entregas_janus(R), responder(_{accion: graficar_entregas, resultado: R}).
manejar_janus(graficar_llegadas, Request) :-
    param(Request, 'unidad', u1, U0),
    atom_string(U, U0),
    graficar_llegadas_janus(U, R),
    responder(_{accion: graficar_llegadas, unidad: U, resultado: R}).
manejar_janus(Otra, _) :-
    responder(_{error: accion_desconocida, accion: Otra,
                acciones: [estado, ping, lecturas, resumen, graficar, graficar_llegadas]}).

manejar(extensiones, _) :- extensiones_json(Json), responder(Json).

%% ---------------------------------------------------------------------------
%% /api/estado
%% ---------------------------------------------------------------------------

estado_json(Json) :-
    ahora(Ahora),
    jornada_inicio(Ini),
    jornada_fin(Fin),
    findall(U, unidad_json(Ahora, U), Unidades),
    findall(P, punto_json(P), Puntos),
    findall(T, tramo_json(T), Tramos),
    findall(E, entrega_json(Ahora, E), Entregas),
    findall(S, situacion_json(S), Situaciones),
    umbral_silencio(Umbral),
    max_manejo(MaxHoras),
    Json = _{ ahora: Ahora,
                     jornada: _{inicio: Ini, fin: Fin},
                     umbral_silencio: Umbral,
                     max_manejo: MaxHoras,
                     unidades: Unidades,
                     puntos: Puntos,
                     tramos: Tramos,
                     entregas: Entregas,
                     situaciones: Situaciones }.

unidad_json(Ahora, D) :-
    unidad(U, CapP, CapV),
    capacidad_libre(U, LibreP, LibreV, Ahora),
    carga(U, CargaP, CargaV, Ahora),
    (   ultima_posicion_en(U, Ahora, Pos, Min) -> true
    ;   Pos = null, Min = null
    ),
    (   averiada(U, Ahora) -> Estado = averiada
    ;   en_duda(U, Ahora) -> Estado = en_duda
    ;   Estado = ok
    ),
    horas_restantes(U, Restantes),
    manejado(U, Manejado),
    (   conductor(U, Conductor) -> true ; Conductor = '' ),
    (   ultimo_conocimiento_en(U, Ahora, UltimoConocimiento) -> true
    ;   UltimoConocimiento = null ),
    (   en_duda_o_estuvo(U, Ahora) -> EstuvoEnDuda = true
    ;   EstuvoEnDuda = false ),
    ruta_json(Ahora, U, Ruta),
    D = _{ id: U,
           conductor: Conductor,
           capacidad: _{peso: CapP, volumen: CapV},
           carga: _{peso: CargaP, volumen: CargaV},
           libre: _{peso: LibreP, volumen: LibreV},
           posicion: _{punto: Pos, minuto: Min},
           estado: Estado,
           silencio: _{estuvo_en_duda: EstuvoEnDuda,
                       ultimo_conocimiento: UltimoConocimiento},
           manejado: Manejado,
           horas_restantes: Restantes,
           ruta: Ruta }.

%% Ruta pendiente: paradas en orden con su punto y su ventana.
ruta_json(Ahora, U, Paradas) :-
    ruta_pendiente_en(U, Ahora, Entregas),
    findall(_{entrega: E, punto: P, hasta: H},
            ( member(E, Entregas), entrega(E, P, _, _), ventana(E, _, H) ),
            Paradas).

punto_json(D) :-
    punto(P, Nombre, X, Y),
    D = _{id: P, nombre: Nombre, x: X, y: Y}.

tramo_json(D) :-
    tramo(A, B, Base),
    (   tramo_lento(A, B, Lento) -> true ; Lento = null ),
    (   Lento == null -> Minutos = Base ; Minutos = Lento ),
    D = _{origen: A, destino: B, minutos_base: Base,
          minutos: Minutos, lento: Lento}.

entrega_json(Ahora, D) :-
    entrega(E, P, Peso, Vol),
    ventana(E, Desde, Hasta),
    estado_entrega(E, Estado, Ahora),
    (   asignacion_vigente_en(E, Ahora, U, Orden, _) -> true
    ;   U = null, Orden = null
    ),
    D = _{ id: E, punto: P, peso: Peso, volumen: Vol,
           desde: Desde, hasta: Hasta, estado: Estado,
           unidad: U, orden: Orden }.

situacion_json(_{entidad: X, tipo: S, evidencia: Ev}) :-
    situacion(X, S, Ev).

%% ---------------------------------------------------------------------------
%% /api/plan ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â situacion 1 (y cualquier conjunto de entregas)
%% ---------------------------------------------------------------------------

plan_json(Request, Json) :-
    param(Request, 'entregas', "todas", Valor0),
    (   Valor0 == "todas"
    ->  entregas_por_defecto(Entregas)
    ;   split_string(Valor0, ",", " ", Partes),
        maplist(atom_string, Entregas, Partes)
    ),
    ahora(Ahora),
    findall(P, plan_dict(P, Entregas, Ahora), Planes),
    (   Planes == []
    ->  (   sin_plan_en(Ahora, Entregas, Diagnostico)
        ->  PlanesJson = [],
            SinPlan = Diagnostico
        ;   SinPlan = null )
    ;   PlanesJson = Planes,
        SinPlan = null
    ),
    findall(_{entrega: E, unidad: U, orden: O},
            ( asignacion_vigente_en(E, Ahora, U, O, _),
              \+ memberchk(E, Entregas) ),
            NoCambia),
    Json = _{ entregas: Entregas,
                   ahora: Ahora,
                   planes: PlanesJson,
                   sin_plan: SinPlan,
                   no_cambia: NoCambia }.

%% Por defecto, las entregas de la unidad averiada que aun no tienen veredicto.
entregas_por_defecto(Entregas) :-
    ahora(Ahora),
    (   sabido(averia, U, _, _, Ahora)
    ->  findall(E, ( asignacion_vigente_en(E, Ahora, U, _, _),
                     \+ entregada_conocida(E, _, Ahora),
                     \+ fallida_conocida(E, _, _, Ahora) ), Entregas)
    ;   findall(E, entrega(E, _, _, _), Entregas)
    ).

plan_dict(PlanDict, Entregas, Ahora) :-
    decide_en(Ahora, Entregas, plan(Asignaciones), Explicacion),
    findall(_{entrega: E, unidad: U, orden: N},
            nth1(N, Asignaciones, E-U), AsignacionesJson),
    findall(_{entrega: E, unidad: U, porque: Motivo},
            member(E-U-Motivo, Explicacion), ExplicacionJson),
    PlanDict = _{ asignaciones: AsignacionesJson,
                  explicacion: ExplicacionJson }.

%% ---------------------------------------------------------------------------
%% /api/urgente ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â situacion 2
%% ---------------------------------------------------------------------------

urgente_json(Json) :-
    ahora(Ahora),
    (   mejor_urgente(U, Ev0) -> eval_json(Ev0, Ev), Elegida = _{unidad: U, evaluacion: Ev}
    ;   Elegida = null ),
    urgente(UE, Punto, Peso, Vol),
    ventana(UE, Desde, Hasta),
    findall(C, candidata_json(Ahora, C), Candidatas),
    (   que_falta(urgente_sin_romper, Alt) -> QueFalta = Alt ; QueFalta = [] ),
    findall(_{orden: O, criterio: C}, prioridad(urgente, O, C), Prio),
    Json = _{ ahora: Ahora,
                      pedido: _{id: UE, punto: Punto, peso: Peso,
                                volumen: Vol, desde: Desde, hasta: Hasta},
                      elegida: Elegida,
                      candidatas: Candidatas,
                      prioridad: Prio,
                      que_falta: QueFalta }.

candidata_json(Ahora, D) :-
    unidad(U, _, _),
    (   mejor_evaluacion(U, Ahora, Ev0)
    ->  eval_json(Ev0, Ev),
        D = _{unidad: U, evaluacion: Ev}
    ;   catch(once(evaluar_urgente(U, Ahora, EvR)), _, fail)
    ->  eval_json(EvR, Ev2),
        D = _{unidad: U, evaluacion: Ev2}
    ;   D = _{unidad: U, evaluacion: null}
    ).

%% Una evaluacion trae pares Entrega-Minutos y rompe([Entrega-Exceso]); se
%% convierten en listas de objetos para que la interfaz no los parta a mano.
eval_json(Ev0, Ev) :-
    is_dict(Ev0), !,
    dict_pairs(Ev0, Etiqueta, Pares0),
    maplist(eval_par_json, Pares0, Pares),
    dict_pairs(Ev, Etiqueta, Pares).
eval_json(Ev, Ev).

eval_par_json(retrasos-L, retrasos-Json) :- !,
    findall(_{entrega: E, minutos: R}, member(E-R, L), Json).
eval_par_json(rompe-rompe(Pares), rompe-Json) :- !,
    findall(_{entrega: E, exceso: X}, member(E-X, Pares), Json).
eval_par_json(K-V0, K-V) :- a_json(V0, V).

%% ---------------------------------------------------------------------------
%% /api/silencio ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â situacion 3
%% ---------------------------------------------------------------------------

silencio_json(Request, Json) :-
    param(Request, 'unidad', "u2", Valor0),
    atom_string(U, Valor0),
    ahora(Ahora),
    (   silencio(U, Ahora, Reporte, Veredictos)
    ->  EnDuda = true,
        findall(_{entrega: E, veredicto: V, evidencia: Ev},
                member(E-V-Ev, Veredictos), VeredictosJson),
        findall(_{entrega: E, original: U1, nueva: U2, desde: T},
                ( reasignacion(E, U1, U2, T), ahora(A) , T =< A ), Reasignadas),
        findall(_{entrega: E, punto: P},
                ( entrega(E, P, _, _), estado_entrega(E, pendiente, Ahora) ), Huerfanas),
        (   Reporte == sin_reporte
        ->  ReporteJson = null
        ;   Reporte = reporte(Minuto)
        ->  ReporteJson = _{minuto: Minuto}
        ;   ReporteJson = Reporte
        )
    ;   EnDuda = false,
        ReporteJson = null,
        VeredictosJson = [],
        Reasignadas = [],
        Huerfanas = []
    ),
    Json = _{ unidad: U,
                       ahora: Ahora,
                       en_duda: EnDuda,
                       reporte: ReporteJson,
                       veredictos: VeredictosJson,
                       reasignadas: Reasignadas,
                       huerfanas: Huerfanas }.

%% ---------------------------------------------------------------------------
%% /api/llegadas ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â situacion 4
%% ---------------------------------------------------------------------------

llegadas_json(Request, Json) :-
    param(Request, 'unidad',  u1, Valor0),
    atom_string(U, Valor0),
    ahora(Ahora),
    (   catch(llegadas_unidad_detalle(U, Ahora, Detalles), _, fail)
    ->  true ; Detalles = [] ),
    findall(_{entrega: E, minimo: Min, maximo: Max, veredicto: V,
              motivo: Motivo, tramos_lentos: TL, alterna: Alt},
            ( member(D, Detalles),
              E = D.entrega, Min = D.minimo, Max = D.maximo, V = D.veredicto,
              get_dict(motivo, D, Motivo),
              get_dict(tramos_lentos, D, TL),
              get_dict(alterna, D, Alt) ),
            LlegadasJson),
    (   alcanza_horas(U, Ahora, HorasV, HorasEv)
    ->  Horas = _{veredicto: HorasV, evidencia: HorasEv}
    ;   Horas = null ),
    (   averiada(U, Ahora) -> Averiada = true ; Averiada = false ),
    findall(_{tramo: _{origen: A, destino: B}, minutos: T, unidades: Uds},
            ( tramo_lento(A, B, T), A @=< B,
              findall(U2, unidad_usa_tramo(U2, A, B), Uds) ), Lentos),
    Json = _{ unidad: U, ahora: Ahora,
                       averiada: Averiada,
                       llegadas: LlegadasJson,
                       horas: Horas,
                       tramos_lentos: Lentos }.

%% ---------------------------------------------------------------------------
%% /api/fallidas ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â situacion 5
%% ---------------------------------------------------------------------------

fallida_json(D) :-
    ahora(Ahora),
    fallida_conocida(E, Motivo, _, Ahora),
    (   destino_fallida(E, Ahora, Destino, Ev) -> true
    ;   Destino = null, Ev = null ),
    (   impacto_fallida(E, Ahora, U, SinContar, Contando)
    ->  Impacto = _{unidad: U, sin_contar: SinContar, contando: Contando}
    ;   Impacto = null ),
    (   catch(impacto_decisiones_fallida(E, Ahora, ImpactoDec), _, fail)
    ->  ImpactoDecisiones = ImpactoDec
    ;   ImpactoDecisiones = null ),
    entrega(E, P, Peso, Vol),
    D = _{ entrega: E, motivo: Motivo, punto: P,
           peso: Peso, volumen: Vol,
           destino: Destino, evidencia: Ev, impacto: Impacto,
           impacto_decisiones: ImpactoDecisiones }.
