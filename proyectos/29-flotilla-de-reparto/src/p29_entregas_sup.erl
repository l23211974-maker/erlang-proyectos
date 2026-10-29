-module(p29_entregas_sup).
-behaviour(supervisor).

%% Supervisor dinamico de entregas: un gen_statem por paquete (900 en la
%% jornada; trivial para BEAM). permanent: si una entrega muere sin motivo
%% interno, el supervisor la relanza con sus datos originales guardados
%% (start_child args). El guardado del estado vivo de la corrida es tarea del
%% despachador, no de esta plantilla.

-export([start_link/0]).
-export([init/1]).

start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
  {ok, {#{strategy => simple_one_for_one, intensity => 50, period => 60},
        [#{id => undefined,
           start => {p29_entrega, start_link, []},
           restart => permanent,
           shutdown => brutal_kill,
           type => worker}]}}.
