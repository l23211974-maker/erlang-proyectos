-module(cowboy_demo_sim).
-behaviour(gen_server).

-export([start_link/0, next/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% Paso de caminata aleatoria acotada; separado para poder probarlo con eunit.
-spec next(map()) -> map().
next(#{temp := T, hum := H}) ->
    #{temp => clamp(T + (rand:uniform() - 0.5), 15.0, 35.0),
      hum  => clamp(H + (rand:uniform() - 0.5) * 2, 30.0, 90.0)}.

init([]) ->
    schedule(),
    {ok, #{temp => 24.0, hum => 55.0}}.

handle_call(_Request, _From, State) ->
    {reply, {error, unsupported}, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(tick, State) ->
    #{temp := T, hum := H} = Next = next(State),
    cowboy_demo_store:put_reading(#{ts => erlang:system_time(millisecond),
                                    temp => round1(T),
                                    hum => round1(H)}),
    schedule(),
    {noreply, Next}.

schedule() ->
    Ms = application:get_env(cowboy_demo, sim_interval_ms, 1000),
    erlang:send_after(Ms, self(), tick).

clamp(V, Min, _Max) when V < Min -> Min;
clamp(V, _Min, Max) when V > Max -> Max;
clamp(V, _Min, _Max) -> V.

round1(V) ->
    round(V * 10) / 10.
