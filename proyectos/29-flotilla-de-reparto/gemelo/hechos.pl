%% hechos.pl Ã¢â‚¬â€ gemelo digital de la flotilla de reparto (#29)
%%
%% Escenario reducido de la extension Prolog: 4 unidades, 14 entregas y
%% 8 puntos del mapa. Todas las cifras de este archivo son supuestos
%% declarados en README.md; las del enunciado (15 unidades, 900 entregas,
%% averia a las 11 a.m., paradas de 2 a 5 min, 5-15 % fallidas, GPS cada
%% 10 s, una hora sin senal) viven en ../problema/readme.md.
%%
%% El "ahora" NO es el reloj del sistema: es el hecho ahora/1, en minutos
%% desde el inicio de la jornada (08:00 = 0). Ningun predicado usa
%% get_time/1 ni random/1.

:- encoding(utf8).

%% Las ventanas se declaran junto a cada entrega y se amplian al final con el
%% pedido urgente, por eso no quedan juntas en el archivo.
:- discontiguous ventana/3.
:- discontiguous evento/4.

%% ---------------------------------------------------------------------------
%% Tiempo
%% ---------------------------------------------------------------------------

jornada_inicio(0).          % 08:00
jornada_fin(360).           % 14:00 (6 h)
ahora(300).                 % 13:00, instante de consulta por omision

%% ---------------------------------------------------------------------------
%% Unidades: capacidad de peso (kg) y de volumen (unidades de bodega)
%% ---------------------------------------------------------------------------

unidad(u1, 110, 10).
unidad(u2, 100, 10).
unidad(u3, 120, 12).
unidad(u4, 80,  8).

conductor(u1, 'Ana Ruiz').
conductor(u2, 'Luis Pena').
conductor(u3, 'Marta Soto').
conductor(u4, 'Ivan Cruz').

manejado(u1, 150).
manejado(u2, 460).
manejado(u3, 120).
manejado(u4, 300).

max_manejo(480).            % tope de minutos al volante por conductor
umbral_silencio(60).        % minutos sin lectura que vuelven dudosa a una unidad
tolerancia_ventana(0).      % retraso tolerado en ventana (0 = ventanas duras por defecto)
tiempo_recogida_averia(parada_minima).  % recoger paquetes de averiada: viaje al punto + 1 parada minima

%% Ultima lectura conocida de cada unidad (posicion y minuto en que se midio).
lectura(u1, posicion, a_almacen, 120).
lectura(u1, posicion, a_almacen, 300).
lectura(u2, posicion, b_norte,   180).
lectura(u3, posicion, c_centro,  180).
lectura(u4, posicion, d_sur,     120).
lectura(u4, posicion, d_sur,     300).

lectura(u1, motor, ok, 300).
lectura(u2, motor, ok, 180).
lectura(u3, motor, averia, 180).
lectura(u4, motor, ok, 300).

%% Rangos del modelo: una parada dura entre 2 y 5 minutos.
rango(parada, 2, 5).

%% ---------------------------------------------------------------------------
%% Puntos del mapa y tramos (tiempo base en minutos)
%% ---------------------------------------------------------------------------

punto(a_almacen, 'Almacen',        20, 80).
punto(b_norte,   'Colonia Norte',  50, 90).
punto(c_centro,  'Centro',         45, 55).
punto(d_sur,     'Colonia Sur',    60, 20).
punto(e_este,    'Colonia Este',   85, 55).
punto(f_oeste,   'Colonia Oeste',  10, 50).
punto(g_puente,  'El Puente',      70, 70).
punto(h_cerro,   'El Cerro',       90, 25).

tramo(a_almacen, b_norte,   12).
tramo(a_almacen, c_centro,   8).
tramo(a_almacen, f_oeste,   10).
tramo(b_norte,   c_centro,   7).
tramo(b_norte,   g_puente,  18).
tramo(c_centro,  d_sur,      9).
tramo(c_centro,  f_oeste,    6).
tramo(c_centro,  g_puente,  14).
tramo(d_sur,     e_este,    11).
tramo(d_sur,     h_cerro,   20).
tramo(e_este,    g_puente,   8).
tramo(e_este,    h_cerro,   16).
tramo(f_oeste,   g_puente,  12).
tramo(g_puente,  h_cerro,   10).

%% ---------------------------------------------------------------------------
%% Entregas: punto, peso, volumen y ventana prometida
%% ---------------------------------------------------------------------------

entrega(e1,  b_norte,  20, 2).
entrega(e2,  b_norte,  15, 1).
entrega(e3,  c_centro, 25, 3).
entrega(e4,  d_sur,    30, 3).
entrega(e5,  e_este,   10, 1).
entrega(e6,  f_oeste,  18, 2).
entrega(e7,  g_puente, 22, 2).
entrega(e8,  h_cerro,  12, 1).
entrega(e9,  d_sur,    16, 2).
entrega(e10, e_este,   14, 1).
entrega(e11, f_oeste,  20, 2).
entrega(e12, c_centro,  9, 1).
entrega(e13, g_puente, 11, 1).
entrega(e14, h_cerro,   8, 1).

ventana(e1,  300, 420).
ventana(e2,  300, 420).
ventana(e3,  200, 280).
ventana(e4,  360, 480).
ventana(e5,  250, 420).
ventana(e6,  210, 285).
ventana(e7,  300, 420).
ventana(e8,  240, 420).
ventana(e9,  300, 345).
ventana(e10, 360, 480).
ventana(e11, 240, 330).
ventana(e12, 300, 420).
ventana(e13, 320, 323).
ventana(e14, 300, 348).

%% ---------------------------------------------------------------------------
%% Asignaciones vigentes: asignacion(Entrega, Unidad, Orden, Minuto)
%% ---------------------------------------------------------------------------

asignacion(e1,  u1, 1, 60).
asignacion(e2,  u1, 2, 60).
asignacion(e9,  u1, 3, 60).

asignacion(e3,  u2, 1, 60).
asignacion(e6,  u2, 2, 60).
asignacion(e5,  u2, 3, 60).
asignacion(e14, u2, 4, 60).

asignacion(e4,  u3, 1, 60).
asignacion(e7,  u3, 2, 60).
asignacion(e10, u3, 3, 60).
asignacion(e12, u3, 4, 60).

asignacion(e8,  u4, 1, 60).
asignacion(e11, u4, 2, 60).
asignacion(e13, u4, 3, 60).

%% Reasignacion ya tomada por el despachador durante el silencio de u2:
%% a las 250 se paso e5 a u1. El reporte en lote probara que u2 si la entrego.
reasignacion(e5, u2, u1, 250).

%% ---------------------------------------------------------------------------
%% Eventos: evento(Minuto, Tipo, Entidad, Detalle)
%% Tipos: averia | silencio | reporte_lote | entregada | fallida | tramo_lento |
%%        reasignada
%% ---------------------------------------------------------------------------

evento(180, averia,      u3, motor_calentado).
evento(180, silencio,    u2, ultima_lectura_b_norte).
evento(240, fallida,     e11, direccion_mala).
evento(275, entregada,   e5,  u2).
evento(280, tramo_lento, tramo(c_centro, d_sur), 24).
evento(290, reporte_lote, u2, 290).
evento(300, fallida,     e8,  cliente_ausente).
evento(400, cierre,      cruce(h_cerro), mantenimiento).  % futuro (fuera de jornada): extension cierres

%% El reporte en lote de u2 llega a las 290 pero trae lo que ocurrio antes:
%% la entrega e5 se hizo a las 275 y hasta el reporte nadie lo sabia.
recepcion(275, entregada, e5, u2, 290).

%% ---------------------------------------------------------------------------
%% Pedido urgente que entra a la jornada (situacion 2)
%% ---------------------------------------------------------------------------

urgente(ue1, f_oeste, 25, 2).
ventana(ue1, 300, 360).     % plazo: 13:00-14:00

%% ---------------------------------------------------------------------------
%% Reintento ofrecido para una entrega fallida (situacion 5)
%% ---------------------------------------------------------------------------

reintento(e8, 330, 420).    % nueva ventana si se reprograma hoy


%% ===========================================================================
%% Extensiones posibles (implementadas)
%% ===========================================================================

%% 1) Ventanas blandas con penalizacion y clientes con prioridad por contrato.
%%    e2 tiene ventana blanda: puede llegar tarde con penalizacion por minuto.
%%    e9 tiene prioridad alta por contrato (cliente prioritario).
ventana_blanda(e2, 5).          % penalizacion 5 unidades por minuto de retraso
ventana_blanda(e14, 2).         % penalizacion 2 por minuto
prioridad_contrato(e9, alta).
prioridad_contrato(e1, alta).
prioridad_contrato(e7, media).
%% prioridad normal por defecto (se resuelve en reglas)

%% 2) Autonomia de combustible/bateria y puntos de carga en la ruta.
%%    autonomia(Unidad, MinutosDisponibles, ConsumoPorMinutoViaje).
%%    punto_carga(Punto, MinutosRecargaCompleta).
autonomia(u1, 180, 1).          % 180 min de autonomia restante
autonomia(u2, 60,  1).          % poca autonomia (afecta si debe cargar)
autonomia(u3, 0,   1).          % averiada, sin autonomia util
autonomia(u4, 200, 1).
punto_carga(a_almacen, 30).
punto_carga(g_puente, 20).
recarga_minima(10).             % recarga rapida minima en minutos

%% 3) Transferir paquetes entre dos unidades a medio camino.
%%    punto_encuentro(Punto, U1, U2, MinutoDisponible) - lugar/tiempo viable
%%    para transbordo de paquetes entre dos unidades.
punto_encuentro(c_centro, u1, u4, 310).
punto_encuentro(a_almacen, u1, u2, 305).
transferencia_permitida(si).    % politica: se permiten transferencias

%% 4) Devoluciones y recolecciones junto con las entregas.
%%    recoleccion(Id, Punto, Peso, Volumen, UnidadAsignada, Orden, Minuto, VentanaDesde, VentanaHasta).
%%    devolucion(Entrega, Unidad, PuntoDevolucion). Recoger agrega carga; devolver la libera.
recoleccion(r1, b_norte, 8, 1, u1, 4, 60, 300, 420).
devolucion(e11, u4, a_almacen). % e11 (direccion mala) debe devolverse al almacen

%% 5) Cierre de una calle o de un cruce que cambia varios tramos a la vez.
%%    (sin cierres activos en el escenario base; se consultan por hechos/eventos)
%%    Ejemplo de cierre de cruce (afecta todos los tramos de g_puente):
%%      evento(350, cierre, cruce(g_puente), obra).
%%    Ejemplo de cierre de tramo especifico:
%%      evento(350, cierre, tramo(b_norte, g_puente), accidente).
%%    Un cierre futuro de ejemplo (minuto 400, fuera de jornada) demuestra la
%%    capacidad sin afectar el escenario base; ver evento cierre cruce(h_cerro).

