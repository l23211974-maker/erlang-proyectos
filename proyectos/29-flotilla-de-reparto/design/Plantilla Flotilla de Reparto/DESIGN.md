# Plantilla Flotilla de Reparto

Export de **Google Stitch** (`stitch_gesti_n_flotilla_multimodal_ux_ui.zip`) usado como base visual del proyecto 29. Es una maqueta de referencia: los HTML usan Tailwind por CDN y `onclick` inline, no están conectados al backend.

| Carpeta | Pantalla | Contenido |
|---|---|---|
| `aeroterra_dispatch_telematics/` | Sistema de diseño | `DESIGN.md` con tokens de color, tipografía, espaciado y componentes — **fuente de verdad de la UI** |
| `dashboard_principal_control_multimodal/` | Dashboard principal | `code.html` (mapa, KPIs, tabla de entregas) |
| `detalle_de_unidad_ficha_y_reasignaci_n/` | Detalle de unidad y reasignación | `code.html` |
| `historial_y_bit_cora_de_alertas/` | Historial y bitácora de alertas | `code.html` |

## Cómo se usa en la Fase 2

1. Leer `aeroterra_dispatch_telematics/DESIGN.md` para colores, tipografías y medidas antes de escribir plantillas.
2. Portar la maqueta de cada pantalla a HTML servido por cowboy (`cowboy_static`), reemplazando Tailwind CDN por un CSS propio con los tokens del sistema de diseño.
3. Sustituir los datos de ejemplo por los endpoints `/api/entregas` y `/api/vehiculos` (ETS de solo lectura) y el canal en vivo del mapa.
4. Los `onclick` de la maqueta marcan las acciones a implementar (filtrar por estado, abrir ficha de unidad, exportar bitácora).

## Nota sobre las capturas

Stitch exportó los `screen.png` como marcadores de error de 28 bytes (`<FIFE Image failed to fetch>`), sin imagen real, así que no se versionan.
