-module(p29_envios_sup).
-behaviour(supervisor).

%% Supervisor dinamico de envios: un gen_statem por paquete de carga aerea.
%% permanent: si un envio muere sin motivo interno, el supervisor lo relanza
%% con sus datos originales guardados (start_child args).

-export([start_link/0]).
-export([init/1]).

start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
  {ok, {#{strategy => simple_one_for_one, intensity => 50, period => 60},
        [#{id => undefined,
           start => {p29_envio, start_link, []},
           restart => permanent,
           shutdown => brutal_kill,
           type => worker}]}}.