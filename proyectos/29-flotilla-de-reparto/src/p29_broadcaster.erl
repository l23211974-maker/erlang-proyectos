-module(p29_broadcaster).
-behaviour(gen_server).

%% Difusor del mapa en vivo hacia los handlers SSE. Un solo proceso se
%% suscribe al reloj (no uno por conexion HTTP) y envia la instantanea JSON a
%% cada watcher con monitor: si el navegador se va, el handler muere y el
%% 'DOWN' limpia el suscriptor sin arrastrar al reloj ni a los demas.

-export([start_link/0, subscribe/1, desuscribir/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

subscribe(Pid) when is_pid(Pid) ->
  gen_server:call(?MODULE, {subscribe, Pid}).

desuscribir(Pid) when is_pid(Pid) ->
  gen_server:call(?MODULE, {desuscribir, Pid}).

init([]) ->
  case whereis(p29_reloj) of
    undefined -> ok;
    _ -> gen_server:call(p29_reloj, {subscribe, self()})
  end,
  {ok, #{watchers => #{}}}.

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
handle_call(desconocido, _From, State) ->
  {reply, {error, desconocido}, State}.

handle_cast(_Msg, State) ->
  {noreply, State}.

%% sin watchers no se fabrica JSON por tick: el reloj tira a 33 ms
handle_info({p29_tick, N}, State = #{watchers := Watch}) ->
  case maps:size(Watch) of
    0 ->
      ok;
    _ ->
      JSON = p29_json:instantanea(N),
      maps:foreach(fun(Pid, _Mon) -> Pid ! {p29_estado, N, JSON} end, Watch)
  end,
  {noreply, State};
handle_info({'DOWN', _Mon, process, Pid, _Motivo}, State = #{watchers := Watch}) ->
  {noreply, State#{watchers := maps:remove(Pid, Watch)}};

handle_info(_Msg, State) ->
  {noreply, State}.
