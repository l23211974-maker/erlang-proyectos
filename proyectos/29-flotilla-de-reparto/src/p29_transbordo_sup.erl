-module(p29_transbordo_sup).
-behaviour(supervisor).

%% Supervisor dinamico de transbordos: un gen_statem por transbordo programado.
%% Se lanza bajo demanda por el despachador cuando hay reasignacion con
%% waypoint intermedio.

-export([start_link/0]).
-export([init/1]).

start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
  {ok, {#{strategy => simple_one_for_one, intensity => 20, period => 60},
        [#{id => undefined,
           start => {p29_transbordo, start_link, []},
           restart => permanent,
           shutdown => brutal_kill,
           type => worker}]}}.