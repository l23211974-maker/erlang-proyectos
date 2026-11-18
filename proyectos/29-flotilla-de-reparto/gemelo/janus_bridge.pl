%% janus_bridge.pl — integración Janus/Python para el gemelo digital (#29)
%%
%% Proporciona py_call/2 compatible con Janus cuando library(janus) está
%% disponible (SWI-Prolog >= 9.1 con paquete Janus). Si no, implementa un
%% puente equivalente vía proceso Python (janus_call.py) que permite llamar
%% funciones Python desde Prolog para generar lecturas simuladas o graficar.
%%
%% Uso típico:
%%   :- use_module(janus_bridge).
%%   py_call(janus_sim:lecturas_simuladas(300, 8, 29), Lecturas).
%%   py_call(janus_sim:graficar_entregas(JsonStr, "web/grafica_janus.svg"), R).

:- module(janus_bridge, [
    py_call/2,
    py_call/3,
    janus_disponible/1,
    janus_python/1,
    janus_dir/1
]).

:- encoding(utf8).

:- use_module(library(process)).
:- use_module(library(readutil)).
:- use_module(library(filesex)).
:- use_module(library(lists)).
:- use_module(library(http/json)).

%% Detectar disponibilidad real de library(janus)
:- dynamic(janus_real/0).
:- if(exists_source(library(janus))).
:- use_module(library(janus), []).
:- assertz(janus_real).
:- endif.

%! janus_disponible(-Modo) is det.
%  Modo = nativo si library(janus) está cargada, puente en caso contrario.
janus_disponible(nativo) :- janus_real, !.
janus_disponible(puente).

%! janus_python(-Exe) is det.
janus_python(python3).

%! janus_dir(-Dir) is det.
%  Directorio base del gemelo (donde viven los .py).
janus_dir(Dir) :-
    (   module_property(janus_bridge, file(File))
    ->  file_directory_name(File, Dir)
    ;   prolog_load_context(directory, Dir)
    ).

%% ---------------------------------------------------------------------------
%% py_call/2,3 - API compatible
%% ---------------------------------------------------------------------------

%! py_call(+Goal, -Result) is det.
%  Goal de forma Mod:Func(Arg1,...) o Mod:Func. Llama a Python y unifica
%  Result con el valor devuelto (convertido a términos Prolog).
py_call(Goal, Result) :-
    py_call(Goal, Result, []).

%! py_call(+Goal, -Result, +Options) is det.
py_call(Goal, Result, _Options) :-
    janus_real,
    !,
    janus:py_call(Goal, Result).
py_call(Goal, Result, _Options) :-
    py_call_puente(Goal, Result).

%% ---------------------------------------------------------------------------
%% Implementación puente (proceso Python + JSON)
%% ---------------------------------------------------------------------------

py_call_puente(Goal, Result) :-
    goal_a_mfa(Goal, Mod, Func, Args),
    args_a_json(Args, JsonArgs),
    janus_dir(Dir),
    janus_python(PyExe),
    directory_file_path(Dir, 'janus_call.py', Runner),
    (   exists_file(Runner) -> true
    ;   throw(error(existence_error(file, Runner), py_call/2))
    ),
    % Ejecutar: python3 janus_call.py Mod Func JsonArgs  (cwd=Dir)
    % stderr se mezcla con stdout para evitar deadlock de pipes en SWI 9.0.4
    process_create(path(PyExe), [Runner, Mod, Func, JsonArgs],
                   [ stdout(pipe(Out)),
                     stderr(std),
                     cwd(Dir),
                     process(PID)
                   ]),
    read_string(Out, _, OutStr),
    close(Out),
    process_wait(PID, Status),
    handle_py_result(Status, OutStr, "", Result).

goal_a_mfa(Mod:FuncSpec, ModAtom, FuncAtom, Args) :-
    !,
    to_atom(Mod, ModAtom),
    funcspec_a_fa(FuncSpec, FuncAtom, Args).
goal_a_mfa(FuncSpec, ModAtom, FuncAtom, Args) :-
    % sin módulo explícito, usar janus_sim por defecto
    ModAtom = 'janus_sim',
    funcspec_a_fa(FuncSpec, FuncAtom, Args).

funcspec_a_fa(FuncSpec, FuncAtom, Args) :-
    compound(FuncSpec),
    FuncSpec \= (_:_),
    !,
    functor(FuncSpec, Func, Arity),
    atom_string(Func, FuncAtom),
    FuncSpec =.. [_|Args],
    ( Arity >= 0 -> true ; Args = [] ).
funcspec_a_fa(Func, FuncAtom, []) :-
    to_atom(Func, FuncAtom).

to_atom(A, S) :- atom(A), !, atom_string(A, S).
to_atom(S, S) :- string(S), !.
to_atom(T, S) :- term_string(T, S).

args_a_json(Args, JsonStr) :-
    maplist(term_a_json_val, Args, JArgs),
    atom_json_term(JsonStr, JArgs, []).

%% Convierte términos Prolog a valores JSON-amigables
term_a_json_val(V, V) :- var(V), !.  % no debería pasar
term_a_json_val(V, V) :- number(V), !.
term_a_json_val(V, V) :- string(V), !.
term_a_json_val(true, @(true)) :- !.
term_a_json_val(false, @(false)) :- !.
term_a_json_val(null, @(null)) :- !.
term_a_json_val([], []) :- !.
term_a_json_val(A, S) :- atom(A), !, atom_string(A, S).
term_a_json_val(D, J) :- is_dict(D), !,
    dict_pairs(D, _Tag, Pairs),
    maplist(pair_a_json, Pairs, JPairs),
    dict_pairs(J, _, JPairs).
term_a_json_val([H|T], J) :- !, maplist(term_a_json_val, [H|T], J).
term_a_json_val(T, S) :-
    % término compuesto: serializar como string legible
    term_string(T, S).

pair_a_json(K-V, K-JV) :- term_a_json_val(V, JV).

handle_py_result(exit(0), OutStr, _ErrStr, Result) :-
    normalize_space(string(JsonTrim), OutStr),
    (   JsonTrim == ""
    ->  Result = @(null)
    ;   catch(atom_json_dict(JsonTrim, J, []), _, fail)
    ->  (   is_dict(J), get_dict(error, J, Msg)
        ->  throw(error(python_error(Msg), py_call/2))
        ;   Result = J
        )
    ;   catch(atom_json_term(JsonTrim, J, []), _, fail)
    ->  json_a_term(J, R0),
        (   is_dict(R0), get_dict(error, R0, Msg)
        ->  throw(error(python_error(Msg), py_call/2))
        ;   Result = R0
        )
    ;   % no JSON: devolver string crudo
        Result = OutStr
    ),
    !.
handle_py_result(Status, OutStr, ErrStr, _Result) :-
    throw(error(python_process_error(Status, OutStr, ErrStr), py_call/2)).

json_a_term(@(true), true) :- !.
json_a_term(@(false), false) :- !.
json_a_term(@(null), null) :- !.
json_a_term(V, V) :- number(V), !.
json_a_term(V, V) :- string(V), !.
json_a_term(V, V) :- atom(V), !.
json_a_term(D, R) :- is_dict(D), !,
    dict_pairs(D, Tag, Pairs),
    maplist(json_pair_a_term, Pairs, RPairs),
    dict_pairs(R, Tag, RPairs).
json_a_term(L, R) :- is_list(L), !, maplist(json_a_term, L, R).
json_a_term(json(Pairs), R) :- !,
    maplist(json_pair_a_term, Pairs, RPairs),
    dict_pairs(R, _, RPairs).
json_a_term(V, V).

json_pair_a_term(K=V, K-R) :- !, json_a_term(V, R).
json_pair_a_term(K-V, K-R) :- !, json_a_term(V, R).
