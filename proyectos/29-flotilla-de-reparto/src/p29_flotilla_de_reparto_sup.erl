-module(p29_flotilla_de_reparto_sup).
-behaviour(supervisor).

%% Arbol de supervision del proyecto AeroCargo. rest_for_one: las dependencias
%% arrancan en orden y si algo intermedio cae, lo que depende de el se
%% re-arranca:
%%   datos (tablas ETS) -> reloj (ticks) -> despachador (quien ordena) ->
%%   ruta_vectorial (rutas/waypoints) -> meteo (alertas) -> adsb (reporteria) ->
%%   adsb_receptor (receptor 1090 MHz) -> aeronaves_sup (aeronaves) ->
%%   envios_sup (gen_statem por paquete) -> transbordo_sup (transbordos) ->
%%   broadcaster (difusion SSE) -> web (cowboy, siempre el ultimo)
%% El despachador aparte esta del arbol de unidades: si una aeronave muere,
%% el despachador NO muere y la reasignacion ocurre.

-export([start_link/0]).
-export([init/1]).

start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
  Children = [
    %% 1. Datos (ETS tables) - base de todo
    #{id => p29_datos,
      start => {p29_datos, start_link, []},
      restart => permanent, shutdown => 5000, type => worker},
    %% 2. Reloj - unico duenyo del tiempo
    #{id => p29_reloj,
      start => {p29_reloj, start_link, []},
      restart => permanent, shutdown => 5000, type => worker},
    %% 3. Rutas vectoriales - waypoints y rutas (DEBE iniciar antes que despachador)
    #{id => p29_ruta_vectorial,
      start => {p29_ruta_vectorial, start_link, []},
      restart => permanent, shutdown => 5000, type => worker},
    %% 4. Meteo - alertas SIGMET/AIRMET
    #{id => p29_meteo,
      start => {p29_meteo, start_link, []},
      restart => permanent, shutdown => 5000, type => worker},
    %% 5. ADS-B - almacenamiento reportes
    #{id => p29_adsb,
      start => {p29_adsb, start_link, []},
      restart => permanent, shutdown => 5000, type => worker},
    %% 6. ADS-B Receptor - simula recepcion 1090 MHz
    #{id => p29_adsb_receptor,
      start => {p29_adsb_receptor, start_link, []},
      restart => permanent, shutdown => 5000, type => worker},
    %% 7. Despachador - cerebro logistico (despues de rutas y meteo)
    #{id => p29_despachador,
      start => {p29_despachador, start_link, []},
      restart => permanent, shutdown => 5000, type => worker},
    %% 8. Aeronaves - supervisor dinamico
    #{id => p29_aeronaves_sup,
      start => {p29_aeronaves_sup, start_link, []},
      restart => permanent, shutdown => infinity, type => supervisor},
    %% 9. Envios - supervisor dinamico
    #{id => p29_envios_sup,
      start => {p29_envios_sup, start_link, []},
      restart => permanent, shutdown => infinity, type => supervisor},
    %% 10. Transbordos - supervisor dinamico
    #{id => p29_transbordo_sup,
      start => {p29_transbordo_sup, start_link, []},
      restart => permanent, shutdown => infinity, type => supervisor},
    %% 11. Broadcaster - difusion SSE (ultimo antes de web)
    #{id => p29_broadcaster,
      start => {p29_broadcaster, start_link, []},
      restart => permanent, shutdown => 5000, type => worker},
    %% 12. Web - Cowboy listener (siempre el ultimo)
    #{id => p29_web,
      start => {p29_web, start_link, []},
      restart => permanent, shutdown => 5000, type => worker}
  ],
  {ok, {#{strategy => rest_for_one, intensity => 10, period => 60}, Children}}.