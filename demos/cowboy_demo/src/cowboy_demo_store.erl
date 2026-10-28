-module(cowboy_demo_store).
-behaviour(gen_server).

-export([start_link/0, put_reading/1, latest/0, history/0]).
-export([init/1, handle_call/3, handle_cast/2]).

-define(TAB, cowboy_demo_readings).
-define(MAX, 120).
-define(GROUP, readings).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

-spec put_reading(map()) -> ok.
put_reading(Reading) ->
    gen_server:cast(?MODULE, {put, Reading}).

%% Las lecturas van directo a ETS: el unico escritor es este proceso, pero
%% cualquier handler lee sin pasar por su cola de mensajes.
-spec latest() -> {ok, map()} | undefined.
latest() ->
    case ets:last(?TAB) of
        '$end_of_table' -> undefined;
        Key ->
            case ets:lookup(?TAB, Key) of
                [{_, Reading}] -> {ok, Reading};
                [] -> undefined
            end
    end.

-spec history() -> [map()].
history() ->
    [Reading || {_, Reading} <- ets:tab2list(?TAB)].

init([]) ->
    ?TAB = ets:new(?TAB, [named_table, ordered_set, protected,
                          {read_concurrency, true}]),
    {ok, #{}}.

handle_call(_Request, _From, State) ->
    {reply, {error, unsupported}, State}.

handle_cast({put, #{ts := Ts} = Reading}, State) ->
    true = ets:insert(?TAB, {Ts, Reading}),
    trim(),
    %% Publicacion a todos los handlers SSE/WS suscritos (grupo pg).
    lists:foreach(fun(Pid) -> Pid ! {reading, Reading} end,
                  pg:get_members(?GROUP)),
    {noreply, State}.

trim() ->
    case ets:info(?TAB, size) > ?MAX of
        true -> true = ets:delete(?TAB, ets:first(?TAB)), ok;
        false -> ok
    end.
