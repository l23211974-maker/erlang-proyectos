-module(p29_broadcaster).
-behaviour(gen_server).

%% Difusor del mapa en vivo hacia los handlers SSE. Un solo proceso se
%% suscribe al reloj (no uno por conexion HTTP) y envia la instantanea JSON a
%% cada watcher con monitor: si el navegador se va, el handler muere y el
%% 'DOWN' limpia el suscriptor sin arrastrar al reloj ni a los demas.

-export([start_link/0, subscribe/1, desuscribir/1,
         registrar_jornada/2, jornada_actual/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

subscribe(Pid) when is_pid(Pid) ->
  gen_server:call(?MODULE, {subscribe, Pid}).

desuscribir(Pid) when is_pid(Pid) ->
  gen_server:call(?MODULE, {desuscribir, Pid}).

%% La demo ancla su jornada [T0, Fin) con una llamada sincrona: a partir de
%% Fin el difusor deja de emitir por tick (30 Hz) y pasa a un latido de
%% 300 ticks (30s a 10s/tick) para keep-alive. Sin jornada registrada el
%% comportamiento es el de siempre: un evento por tick.
registrar_jornada(T0, Fin) when is_integer(T0), is_integer(Fin), Fin > T0 ->
  gen_server:call(?MODULE, {registrar_jornada, T0, Fin}).

jornada_actual() ->
  gen_server:call(?MODULE, jornada_actual).

%% latido post-jornada: 300 ticks a 10s = 30 min simulados (configurable via app env)
cadencia_idle() ->
    case application:get_env(p29_flotilla_de_reparto, cadencia_idle) of
        {ok, V} when is_integer(V), V > 0 -> V;
        _ -> 300
    end.

init([]) ->
  case whereis(p29_reloj) of
    undefined -> ok;
    _ -> gen_server:call(p29_reloj, {subscribe, self()})
  end,
  TicksJornada = case application:get_env(p29_flotilla_de_reparto, ticks_jornada) of
                   {ok, V} -> V;
                   _ -> 2160
                 end,
  {ok, #{watchers => #{}, jornada => undefined, ticks_jornada => TicksJornada, jornada_terminada => false}}.

handle_call({subscribe, Pid}, _From, State = #{watchers := Watch}) ->
  Mon = erlang:monitor(process, Pid),
  {reply, ok, State#{watchers := Watch#{Pid => Mon}}};
handle_call({desuscribir, Pid}, _From, State = #{watchers := Watch}) ->
  case maps:find(Pid, Watch) of
    {ok, Mon} ->
      erlang:demonitor(Mon, [flush]),
      {reply, ok, State#{watchers := maps:remove(Pid, Watch)}};
    error ->
      {reply, ok, State}
  end;
handle_call({registrar_jornada, T0, Fin}, _From, State) ->
  {reply, ok, State#{jornada := {T0, Fin}, ticks_jornada => Fin, jornada_terminada => false}};
handle_call(jornada_actual, _From, State) ->
  {reply, maps:get(jornada, State), State};
handle_call(desconocido, _From, State) ->
  {reply, {error, desconocido}, State}.

handle_cast(_Msg, State) ->
  {noreply, State}.

%% sin watchers no se fabrica JSON por tick: el reloj tira a 33 ms
%% tras ticks_jornada (Fin): solo latidos cada 300 ticks (30s) para keep-alive
handle_info({p29_tick, N}, State = #{watchers := Watch, jornada := Jornada}) ->
  {Emitir, EsJornadaFin} = case Jornada of
                               {_T0, Fin} when is_integer(Fin), N >= Fin ->
                                   {((N - Fin) rem cadencia_idle() =:= 0), true};
                               _ ->
                                   {true, false}
                           end,
  case Emitir andalso maps:size(Watch) > 0 of
    false ->
      ok;
    true ->
      case EsJornadaFin of
        true ->
          maps:foreach(fun(Pid, _Mon) -> Pid ! {p29_latido, N} end, Watch);
        false ->
          JSON = p29_json:instantanea(N),
          maps:foreach(fun(Pid, _Mon) -> Pid ! {p29_estado, N, JSON} end, Watch)
      end
  end,
  {noreply, State};
handle_info({'DOWN', _Mon, process, Pid, _Motivo}, State = #{watchers := Watch}) ->
  {noreply, State#{watchers := maps:remove(Pid, Watch)}};

handle_info(_Msg, State) ->
  {noreply, State}.