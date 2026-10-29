# Prompt para Google Stitch — #29 Flotilla de reparto

Prompt principal (pegar en Stitch, modo avanzado si es posible). Si Stitch corta el
resultado, generar pantalla por pantalla con las secciones de abajo.

---

Diseña la app móvil de un panel de operaciones logísticas llamado **"Flotilla de
reparto"**. Es una herramienta de despacho de última milla: 15 camionetas de reparto
urbanas, 900 entregas al día, posición GPS de cada unidad actualizada cada 10 segundos
y reasignación automática de paquetes a otra unidad cuando una camioneta se avería.
El usuario es el despachador de la empresa: revisa el tablero en la oficina y en el
celular cuando sale a seguir una unidad.

Estados del dominio que la UI debe reflejar con color:
- Vehículo: en ruta (verde), sin señal GPS (ámbar), averiado (rojo).
- Entrega: pendiente (gris), en ruta (azul), entregada (verde), fallida (rojo).
- Eventos: reasignación (ámbar), pedido urgente (magenta), recuperación (verde).

## Pantalla 1 — Dashboard (pantalla por defecto)

Vertical, pensada primero para celular.

- Encabezado: título "Flotilla de reparto", reloj de la jornada simulada y mes con
  "modo demo x60" (la simulación corre acelerada).
- Fila de 4 tarjetas indicadoras: **En ruta**, **Entregadas**, **Pendientes**,
  **Fallidas** (números grandes, cambio animado al actualizar). Debajo, una línea con
  **Vehículos activos 13/15** y **Retraso medio 6 min**.
- Mapa de la ciudad (snapshot ilustrativo, mano de simple) con las 15 unidades como
  íconos de camioneta coloreados por estado del vehículo; al tocar una unidad se abre
  una tarjeta flotante con placa, conductor, entregas pendientes y ETA de su próxima
  parada.
- Lista compacta "Reasignaciones recientes": cada renglón con código de entrega, desde
  qué unidad hacia cuál y el motivo (Avería / Urgente / Sin señal), con hora.

## Pantalla 2 — Detalle de unidad

Se llega tocando una unidad del dashboard.

- Encabezado: número de unidad, conductor, estado actual (chip verde/ámbar/rojo) y
  botón **Simular avería** (rojo, para la prueba de caos en vivo).
- Tarjeta de telemetría: posición GPS (hora del último reporte, si lleva >60 s sin
  reportar mostrar aviso ámbar "Sin señal 90 s"), velocidad, capacidad de carga
  (barra de paquetes en el vehículo vs capacidad máxima).
- Lista de sus entregas del día: cada una con código, colonia, ventana de entrega
  ("2–4 pm") y chip de estado de entrega.
- Sección "Últimos eventos de esta unidad": reasignaciones entrantes y salientes con
  hora y motivo.

## Pantalla 3 — Bitácora de eventos

- Encabezado con filtros en chips: Todos / Reasignaciones / Urgentes / Fallidas /
  Sin señal, y filtro por unidad.
- Lista cronológica (la más reciente arriba) con hora, ícono por tipo de evento,
  descripción en una línea ("E-7742 reasignada de U-07 → U-12: avería") y chip de color
  del estado resultante.
- Cada renglón expande en acordeón el detalle: qué entregas se movieron, capacidad
  resultante de la unidad destino y hora de reprogramación.

## Requisitos generales

- Español en todos los textos; datos realistas en español mexicano (colonias de
  Tijuana, horas "2–4 pm", placas "U-07").
- Legible en celular de una mano; targets táctiles de al menos 44 px.
- Semántica de color estricta: verde ok, ámbar alerta, rojo falla, magenta urgente;
  nunca usar rojo para algo decorativo.
- Estilo sobrio de sala de control: dark map, tipografía sans de alta legibilidad,
  números tabulares para KPIs, sin ilustraciones decorativas.
- Los datos se actualizan en vivo (WebSocket): indicar visualmente "en vivo" con un
  punto pulsante verde en el encabezado.

---

Después de iterar: exportar el zip de Stitch y descomprimirlo en esta carpeta
(`design/`), incluyendo `DESIGN.md`. Archivos esperados aquí: `DESIGN.md`, HTML/CSS
por pantalla y capturas.
