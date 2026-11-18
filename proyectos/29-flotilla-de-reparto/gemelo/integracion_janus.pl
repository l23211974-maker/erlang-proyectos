%% integracion_janus.pl — casos de uso de Janus (Python desde Prolog) para gemelo #29
%%
%% Implementa la extensión opcional: llamar a Python desde Prolog (Janus)
%% para generar lecturas simuladas y graficar.
%%
%% Predicados principales:
%%   janus_ping(-Info)
%%   lecturas_simuladas_janus(+Ahora, +Cantidad, +Semilla, -Lecturas)
%%   resumen_flota_janus(-Resumen)
%%   graficar_entregas_janus(-Resultado)
%%   graficar_llegadas_janus(+Unidad, -Resultado)
%%   janus_estado(-Estado)

:- module(integracion_janus, [
    janus_ping/1,
    lecturas_simuladas_janus/4,
    lecturas_simuladas_janus/1,
    resumen_flota_janus/1,
    graficar_entregas_janus/1,
    graficar_llegadas_janus/2,
    graficar_llegadas_janus/1,
    janus_estado/1
]).

:- encoding(utf8).

:- use_module(janus_bridge).
:- use_module(library(http/json)).

%% janus_estado(-Estado) : información sobre la integración Janus disponible.
janus_estado(Estado) :-
    janus_disponible(Modo),
    janus_python(Py),
    janus_dir(Dir),
    Estado = _{ disponible: true,
                modo: Modo,
                python: Py,
                directorio: Dir,
                nota: "Llamadas a Python desde Prolog via py_call/2 (Janus o puente compatible)." }.

%% janus_ping(-Info) : prueba de llamada Python desde Prolog.
janus_ping(Info) :-
    py_call(janus_sim:ping, Info0),
    janus_disponible(Modo),
    Info = Info0.put(modo_janus, Modo).

%% lecturas_simuladas_janus(+Ahora, +Cantidad, +Semilla, -Lecturas)
%  Genera lecturas GPS/sensor simuladas llamando a Python (Janus).
lecturas_simuladas_janus(Ahora, Cantidad, Semilla, Lecturas) :-
    py_call(janus_sim:lecturas_simuladas(Ahora, Cantidad, Semilla), Lecturas).

%% lecturas_simuladas_janus(-Lecturas) : usa el ahora actual del modelo.
lecturas_simuladas_janus(Lecturas) :-
    ( current_predicate(ahora/1), ahora(A) -> Ahora = A ; Ahora = 300 ),
    lecturas_simuladas_janus(Ahora, 8, 29, Lecturas).

%% resumen_flota_janus(-Resumen)
%  Envía el estado del gemelo a Python y obtiene un resumen calculado allí.
resumen_flota_janus(Resumen) :-
    estado_dict_para_janus(Estado),
    with_output_to(string(JsonStr), json_write_dict(current_output, Estado, [])),
    py_call(janus_sim:resumen_flota(JsonStr), Resumen).

%% graficar_entregas_janus(-Resultado)
%  Genera una gráfica SVG (entregas por estado) con Python via Janus.
graficar_entregas_janus(Resultado) :-
    estado_dict_para_janus(Estado),
    with_output_to(string(JsonStr), json_write_dict(current_output, Estado, [])),
    py_call(janus_sim:graficar_entregas(JsonStr, "web/grafica_janus.svg"), Resultado).

%% graficar_llegadas_janus(+Unidad, -Resultado)
%  Genera gráfica SVG de llegadas máximas estimadas para una unidad.
graficar_llegadas_janus(Unidad, Resultado) :-
    ( atom(Unidad) -> U = Unidad ; atom_string(U, Unidad) ),
    ( current_predicate(ahora/1), ahora(A) -> Ahora = A ; Ahora = 300 ),
    ( current_predicate(llegadas_unidad_detalle/3)
    -> ( catch(llegadas_unidad_detalle(U, Ahora, Detalles), _, fail) -> Ds = Detalles ; Ds = [] )
    ;  ( current_predicate(llegadas_unidad/3)
       -> ( catch(llegadas_unidad(U, Ahora, Ls), _, fail)
          -> findall(_{entrega:E,minimo:Min,maximo:Max,veredicto:V},
                     (member(E-Min-Max-V, Ls)), Ds)
          ;  Ds = [] )
       ;  Ds = [] )
    ),
    findall(_{entrega:E,minimo:Min,maximo:Max,veredicto:V},
            ( member(D, Ds),
              ( is_dict(D) -> E=D.entrega, Min=D.minimo, Max=D.maximo, V=D.veredicto
              ; E=none, Min=0, Max=0, V=none )
            ), Items),
    atom_concat('web/grafica_llegadas_', U, Pref),
    atom_concat(Pref, '.svg', Salida),
    with_output_to(string(JsonStr), json_write_dict(current_output, _{unidad:U, ahora:Ahora, llegadas:Items}, [])),
    py_call(janus_sim:graficar_llegadas(JsonStr, U, Salida), Resultado).

graficar_llegadas_janus(Resultado) :-
    graficar_llegadas_janus(u1, Resultado).

%% Construye un dict de estado similar a /api/estado para enviarlo a Python.
estado_dict_para_janus(Estado) :-
    ( current_predicate(ahora/1), ahora(Ahora) -> true ; Ahora = 300 ),
    % unidades
    findall(Ud, unidad_dict_janus(Ahora, Ud), Unidades),
    % entregas
    findall(Ed, entrega_dict_janus(Ahora, Ed), Entregas),
    Estado = _{ahora: Ahora, unidades: Unidades, entregas: Entregas}.

unidad_dict_janus(Ahora, D) :-
    current_predicate(unidad/3),
    unidad(U, CapP, CapV),
    ( current_predicate(carga/4) -> carga(U, Peso, Vol, Ahora) ; Peso=0, Vol=0 ),
    ( current_predicate(averiada/2), averiada(U, Ahora) -> Estado = averiada
    ; current_predicate(silencio/4), silencio(U, Ahora, _, _) -> Estado = en_duda
    ; Estado = ok
    ),
    D = _{unidad: U, capacidad_peso: CapP, capacidad_volumen: CapV,
          carga_peso: Peso, carga_volumen: Vol, estado_unidad: Estado}.

entrega_dict_janus(Ahora, D) :-
    current_predicate(entrega/4),
    entrega(E, P, Peso, Vol),
    ( current_predicate(estado_entrega/3) -> estado_entrega(E, Est, Ahora) ; Est = desconocido ),
    ( current_predicate(asignacion_vigente_en/5)
    -> ( asignacion_vigente_en(E, Ahora, U, _, _) -> UAsig = U ; UAsig = null )
    ;  UAsig = null
    ),
    D = _{entrega: E, punto: P, peso: Peso, volumen: Vol, estado: Est, unidad: UAsig}.
