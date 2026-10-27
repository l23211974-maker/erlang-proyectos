-module(p10_api_rest_con_cowboy_y_postgr_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% TODO(equipo): agregar aqui los supervisores/workers del dominio. one_for_one porque
%% por ahora los hijos son independientes; cambiar a rest_for_one si hay orden de arranque.
init([]) ->
  Children = [
    #{id => p10_api_rest_con_cowboy_y_postgr_server,
      start => {p10_api_rest_con_cowboy_y_postgr_server, start_link, []},
      restart => permanent,
      shutdown => 5000,
      type => worker}
  ],
  {ok, {#{strategy => one_for_one, intensity => 10, period => 60}, Children}}.
