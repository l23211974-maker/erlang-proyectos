-module(cowboy_demo_tests).
-include_lib("eunit/include/eunit.hrl").

sim_next_stays_in_bounds_test() ->
    Final = lists:foldl(fun(_, Acc) ->
                            Next = cowboy_demo_sim:next(Acc),
                            #{temp := T, hum := H} = Next,
                            ?assert(T >= 15.0 andalso T =< 35.0),
                            ?assert(H >= 30.0 andalso H =< 90.0),
                            Next
                        end, #{temp => 34.9, hum => 89.9}, lists:seq(1, 500)),
    ?assertMatch(#{temp := _, hum := _}, Final).

store_test_() ->
    {setup,
     fun() ->
         {ok, Pg} = pg:start_link(),
         {ok, Store} = cowboy_demo_store:start_link(),
         {Pg, Store}
     end,
     fun({Pg, Store}) ->
         lists:foreach(fun(P) -> unlink(P), exit(P, shutdown) end, [Store, Pg])
     end,
     fun(_) ->
         [fun empty_store_has_no_latest/0,
          fun latest_returns_last_inserted/0,
          fun history_is_bounded/0,
          fun subscribers_get_published_readings/0]
     end}.

empty_store_has_no_latest() ->
    ?assertEqual(undefined, cowboy_demo_store:latest()).

latest_returns_last_inserted() ->
    cowboy_demo_store:put_reading(#{ts => 1, temp => 20.0, hum => 50.0}),
    cowboy_demo_store:put_reading(#{ts => 2, temp => 21.0, hum => 51.0}),
    sync(),
    ?assertEqual({ok, #{ts => 2, temp => 21.0, hum => 51.0}},
                 cowboy_demo_store:latest()).

history_is_bounded() ->
    lists:foreach(fun(N) ->
                      cowboy_demo_store:put_reading(#{ts => 100 + N, temp => 1.0, hum => 1.0})
                  end, lists:seq(1, 300)),
    sync(),
    ?assertEqual(120, length(cowboy_demo_store:history())).

subscribers_get_published_readings() ->
    ok = pg:join(readings, self()),
    R = #{ts => 99999, temp => 22.0, hum => 44.0},
    cowboy_demo_store:put_reading(R),
    ?assertEqual(ok, receive {reading, R} -> ok after 1000 -> timeout end),
    ok = pg:leave(readings, self()).

%% put_reading/1 es cast; un call al sistema vacia la cola antes de leer ETS.
sync() ->
    _ = sys:get_state(cowboy_demo_store),
    ok.
