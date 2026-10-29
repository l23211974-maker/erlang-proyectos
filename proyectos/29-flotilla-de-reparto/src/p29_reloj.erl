-module(p29_reloj).
-behaviour(gen_server).

%% Unico dueno del tiempo simulado. El despachador y los vehiculos NO invocan
%% functions de tiempo propios: solo reaccionan a {p29_tick, N}. Asi los tests
%% y la demo impulsan la jornada con el mismo mecanismo y el resultado es
%% reproducible (ver config: tick_interval_ms controla la aceleracion real).

-export([start_link/0, tick/0, tick_actual/0, subscribe/1, desuscribir/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% Impulsa un tick manualmente (la demo y los tests usan esta via).
tick() ->
  gen_server:call(?MODULE, tick).

tick_actual() ->
  gen_server:call(?MODULE, tick_actual).

subscribe(Pid) when is_pid(Pid) ->
  gen_server:call(?MODULE, {subscribe, Pid}).

desuscribir(Pid) when is_pid(Pid) ->
  gen_server:call(?MODULE, {desuscribir, Pid}).

init([]) ->
  Auto = application:get_env(p29_flotilla_de_reparto, reloj_auto, true),
  case Auto of
    true ->
      Intervalo = application:get_env(p29_flotilla_de_reparto, tick_interval_ms, 166),
      erlang:send_after(Intervalo, self(), tick);
    false ->
      ok
  end,
  {ok, #{ticks => 0, suscriptores => sets:new([{version, 2}])}}.

%% Broadcast: nadie espera al resto (los GPS vuelan en cast), los tests usan
%% polling con el helper espera/2 para sincronizar.

handle_call(tick, _From, State = #{ticks := N, suscriptores := Sus}) ->
  difundir(N + 1, sets:to_list(Sus)),
  {reply, N + 1, State#{ticks := N + 1}};
handle_call(tick_actual, _From, State) ->
  {reply, maps:get(ticks, State), State};
handle_call({subscribe, Pid}, _From, State = #{suscriptores := Sus}) ->
  {reply, ok, State#{suscriptores := sets:add_element(Pid, Sus)}};
handle_call({desuscribir, Pid}, _From, State = #{suscriptores := Sus}) ->
  {reply, ok, State#{suscriptores := sets:del_element(Pid, Sus)}};
handle_call(desconocido, _From, State) ->
  {reply, {error, desconocido}, State}.

handle_cast(_Msg, State) ->
  {noreply, State}.

handle_info(tick, State = #{ticks := N, suscriptores := Sus}) ->
  difundir(N + 1, sets:to_list(Sus)),
  Auto = application:get_env(p29_flotilla_de_reparto, reloj_auto, true),
  case Auto of
    true ->
      Intervalo = application:get_env(p29_flotilla_de_reparto, tick_interval_ms, 166),
      erlang:send_after(Intervalo, self(), tick);
    false ->
      ok
  end,
  {noreply, State#{ticks := N + 1}};
handle_info(_Msg, State) ->
  {noreply, State}.

difundir(_N, []) -> ok;
difundir(N, [Pid | Resto]) ->
  Pid ! {p29_tick, N},
  difundir(N, Resto).
