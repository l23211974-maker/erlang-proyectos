-module(p29_flotilla_de_reparto_sup).
-behaviour(supervisor).

%% Arbol de supervision del proyecto. rest_for_one: las dependencias arrancan
%% en orden y si algo intermedio cae, lo que depende de el se re-arranca:
%%   datos (tablas ETS) -> reloj (ticks) -> despachador (quien ordena) ->
%%   flota_sup (vehiculos) -> entregas_sup (gen_statem por paquete)
%% El despachador aparte esta del arbol de unidades: si un vehiculo muere,
%% el despachador NO muere y la reasignacion ocurre.

-export([start_link/0]).
-export([init/1]).

start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
  Children = [
    #{id => p29_datos,
      start => {p29_datos, start_link, []},
      restart => permanent, shutdown => 5000, type => worker},
    #{id => p29_reloj,
      start => {p29_reloj, start_link, []},
      restart => permanent, shutdown => 5000, type => worker},
    #{id => p29_despachador,
      start => {p29_despachador, start_link, []},
      restart => permanent, shutdown => 5000, type => worker},
    #{id => p29_flota_sup,
      start => {p29_flota_sup, start_link, []},
      restart => permanent, shutdown => infinity, type => supervisor},
    #{id => p29_entregas_sup,
      start => {p29_entregas_sup, start_link, []},
      restart => permanent, shutdown => infinity, type => supervisor}
  ],
  {ok, {#{strategy => rest_for_one, intensity => 10, period => 60}, Children}}.
