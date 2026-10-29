-module(p29_flota_sup).
-behaviour(supervisor).

%% Supervisor dinamico de unidades: un hijo por vehiculo, arrancado bajo
%% demanda por el despachador. permanent + simple_one_for_one: una unidad
%% muerta (averia en la prueba de caos) se relanza vacia y lista para
%% volver a recibir cargas.

-export([start_link/0]).
-export([init/1]).

start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
  {ok, {#{strategy => simple_one_for_one, intensity => 10, period => 60},
        [#{id => undefined,
           start => {p29_vehiculo, start_link, []},
           restart => permanent,
           shutdown => brutal_kill,
           type => worker}]}}.
