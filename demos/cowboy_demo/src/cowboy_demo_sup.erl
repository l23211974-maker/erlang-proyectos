-module(cowboy_demo_sup).
-behaviour(supervisor).

-export([start_link/0, init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% rest_for_one: cada hijo depende de los anteriores. Si cae `pg` o el store,
%% se reinician simulador y listener para no dejar conexiones colgadas de un
%% estado viejo.
init([]) ->
    SupFlags = #{strategy => rest_for_one, intensity => 5, period => 10},
    Children = [
        #{id => pg, start => {pg, start_link, []},
          restart => permanent, type => worker, modules => [pg]},
        #{id => store, start => {cowboy_demo_store, start_link, []},
          restart => permanent, type => worker, modules => [cowboy_demo_store]},
        #{id => sim, start => {cowboy_demo_sim, start_link, []},
          restart => permanent, type => worker, modules => [cowboy_demo_sim]},
        listener_spec()
    ],
    {ok, {SupFlags, Children}}.

%% El listener cuelga del arbol de supervision (ranch:child_spec) en lugar de
%% arrancarse con cowboy:start_clear/3 desde la app.
listener_spec() ->
    Port = application:get_env(cowboy_demo, port, 8080),
    Dispatch = cowboy_router:compile([{'_', [
        {"/",              cowboy_static, {priv_file, cowboy_demo, "www/index.html"}},
        {"/api/health",    cowboy_demo_health_h, []},
        {"/api/readings",  cowboy_demo_readings_h, []},
        {"/sse",           cowboy_demo_sse_h, []},
        {"/ws",            cowboy_demo_ws_h, []}
    ]}]),
    ranch:child_spec(cowboy_demo_http, ranch_tcp,
                     #{socket_opts => [{port, Port}]},
                     cowboy_clear,
                     #{env => #{dispatch => Dispatch}}).
