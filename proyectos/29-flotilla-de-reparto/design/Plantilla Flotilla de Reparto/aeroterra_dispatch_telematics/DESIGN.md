---
name: AeroTerra Dispatch Telematics
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#3f4850'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#707881'
  outline-variant: '#bfc7d2'
  surface-tint: '#006398'
  primary: '#006194'
  on-primary: '#ffffff'
  primary-container: '#007bb9'
  on-primary-container: '#fdfcff'
  inverse-primary: '#93ccff'
  secondary: '#545d7c'
  on-secondary: '#ffffff'
  secondary-container: '#d0d9fd'
  on-secondary-container: '#555e7d'
  tertiary: '#00628d'
  on-tertiary: '#ffffff'
  tertiary-container: '#007cb1'
  on-tertiary-container: '#fcfcff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#cce5ff'
  primary-fixed-dim: '#93ccff'
  on-primary-fixed: '#001d31'
  on-primary-fixed-variant: '#004b73'
  secondary-fixed: '#dbe1ff'
  secondary-fixed-dim: '#bdc5e9'
  on-secondary-fixed: '#111a36'
  on-secondary-fixed-variant: '#3d4664'
  tertiary-fixed: '#c9e6ff'
  tertiary-fixed-dim: '#89ceff'
  on-tertiary-fixed: '#001e2f'
  on-tertiary-fixed-variant: '#004c6e'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  headline-xl:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline-xl-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  headline-md:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  telemetry-lg:
    fontFamily: JetBrains Mono
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 26px
  telemetry-md:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 18px
  telemetry-sm:
    fontFamily: JetBrains Mono
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
  label-caps:
    fontFamily: JetBrains Mono
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 12px
    letterSpacing: 0.08em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1rem
  gutter-desktop: 1.5rem
  margin-desktop: 2rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2.5rem
---

## Brand & Style
The design system is constructed for mission-critical telemetry, multimodal logistics, and tactical dispatch operations across air corridors and ground networks. Its operational philosophy balances high-density information architecture with rapid human decision-making under time constraints and outdoor/field visibility challenges.

The aesthetic fuses **Industrial Modernism** with **Aerospace Instrument Design**: crisp technical clarity, low visual noise, purposeful contrast hierarchies, and immediate visual feedback. It eliminates decorative ambiguity in favor of instrument-grade legibility, predictable ergonomics, and cognitive ergonomics tuned for operators managing high-velocity logistics simultaneously across cockpits, dispatch centers, and ruggedized tablets on tarmac or cargo bays.

## Colors
The system enforces a high-contrast functional color palette built on top of cold, glare-resistant surfaces.

### Surface & Frame Tokens
- **Canvas Base (`bg-surface-canvas`):** `#F4F6F9` — A cold, neutral base engineered to reduce eye strain under varying ambient lighting conditions.
- **Card / Surface Default (`bg-surface-card`):** `#FFFFFF` — High-clarity elevated containers.
- **Structural Framing (`border-subtle` / `border-bold`):** `#E2E8F0` and `#CBD5E1` — Defined delineation for tabular data, instrument frames, and telemetry groups.
- **Telemetry Shell / High Contrast Panels (`bg-surface-slate`):** `#0B132B` and `#1C2541` — Deep industrial slate applied to map heads-up displays, side navigation rails, and mission-critical telemetry summaries.

### Telematics & Interactive Accents
- **Primary Telematics Action:** `#0284C7` (Sky 600) — Primary routing buttons, active fleet filters, and geofence vectors.
- **Active Beacon / Pulse:** `#0EA5E9` (Sky 500) — Radiating radar scans, live telemetry pings, and real-time connectivity indicators.

### Rigorous Operational Semaphores
Operational status tokens are absolute; they are never muted or adjusted for decorative whims.
- **Nominal (In Route / On Schedule / Systems Nominal):**
  - Core: `#10B981` (Emerald 500)
  - Surface Tint: `#ECFDF5`
  - Deep Text / Outline: `#059669`
- **Warning (Delay / Cautionary Deviation / Metric Threshold):**
  - Core: `#F59E0B` (Amber 500)
  - Surface Tint: `#FFFBEB`
  - Deep Text / Outline: `#D97706`
- **Critical Failure (Emergency / Ground Stop / Critical Alert / Maintenance Fault):**
  - Core: `#EF4444` (Red 500)
  - Surface Tint: `#FEF2F2`
  - Deep Text / Outline: `#DC2626`

## Typography
The system enforces a dual-typeface structure: **Inter** handles human-interface narrative, commands, and structured metadata, while **JetBrains Mono** is reserved exclusively for instrument readings, coordinates, ETA counts, callsigns, flight levels, and vehicle identifiers.

### Numerical Data Alignment
All numbers in tables, telemetry metrics, and dispatch manifests must use tabular figures (`font-variant-numeric: tabular-nums`) to prevent horizontal jitter during real-time streaming updates.

### Hierarchy Guidelines
- **Telemetry Display (`telemetry-lg`, `telemetry-md`):** Fixed-width data channels for metrics such as Ground Speed (`GS: 420 kts`), Barometric Altitude (`FL240`), Fuel Reserve (`8,450 lbs`), and Waypoint Lat/Long.
- **Operational Badges (`label-caps`):** Rendered uppercase with generous tracking for vehicle status tags (e.g., `CARGO-AIR`, `REEFER-TRUCK`, `HEAVY-HAUL`).

## Layout & Spacing
The layout follows a modular, 12-column responsive fluid grid structured around tactical dashboard splits and side-docked dispatch panels.

### Responsive Breakpoints & Multi-Column Rules
- **Mobile (< 768px):** Single-column stacked telemetry cards with sticky bottom operational sheets. Outer margin: `1rem` (`16px`). Touch targets lock to a mandatory minimum hit area of `48px`.
- **Tablet / Cockpit Mount (768px - 1024px):** 2-column view with split-pane layout: sticky telemetry map viewport on the top half and interactive dispatch queue on the lower half. Outer margin: `1.5rem` (`24px`).
- **Desktop Dispatch Center (> 1024px):** 12-column grid. Left fixed navigation/filter pane (3 columns), central tactical map / radar view (6 columns), right detailed dispatch manifest & asset health telemetry (3 columns). Outer margin: `2rem` (`32px`).

### Component Spacing Rhythm
Component interiors adhere to strict 8-point increments. Tactical data clusters use compact micro-spacing (`0.25rem` to `0.5rem`), while card boundaries and modular docks separate at `1rem` to `1.5rem` increments.

## Elevation & Depth
Depth in the design system uses crisp structural outlines and functional tonal layering rather than dramatic, blurred shadows. This prevents loss of contrast under cockpit sunshine or rugged field laptop environments.

### Depth Layers
- **Layer 0 (Canvas):** `#F4F6F9` — Ambient foundation.
- **Layer 1 (Card & Module Surface):** `#FFFFFF` paired with an explicit `1px solid #E2E8F0` border. No drop shadow.
- **Layer 2 (Elevated Flyouts & Floating HUD Panels):** `#FFFFFF` or `#0B132B` bordered by `1px solid #CBD5E1` with an ambient tactical offset: `0 4px 12px rgba(11, 19, 43, 0.08)`.
- **Layer 3 (Modal Alerts & Emergency Overrides):** `0 12px 32px rgba(11, 19, 43, 0.22)`, bounded by a `2px solid` border in the alert's state color (`#EF4444` for emergencies).

## Shapes
The shape language enforces controlled structural geometry. Base elements utilize `0.5rem` (`8px`) radii to retain an industrial, instrument-panel personality without aggressive sharp edges that impede touch ergonomics.

- **Standard Containers & Cards:** `8px` (`roundedness: 2`).
- **Input Fields & Tactical Action Buttons:** `8px` corner radius.
- **Operational Status Chips & Dynamic Radar Tags:** Pill-shaped (`9999px`) to immediately distinguish ephemeral status metadata from structural functional cards.

## Components

### 1. Buttons & Touch Controls
- **Touch-First Sizing:** All mobile and tablet interactive targets maintain a minimum dimension of `48px` height (Desktop allows compact `40px` toolbars).
- **Primary Operational Button:** Solid `#0284C7` background, white label, active scale-down press state (`0.98`), `8px` radius.
- **Secondary Dispatch Control:** Slate border `#CBD5E1`, background `#FFFFFF`, text `#1C2541`.
- **Emergency / Stop Action:** Solid `#EF4444` background with white uppercase bold typography.

### 2. Operational Status Chips (Pill Indicators)
- **Geometry:** Height `24px` to `28px`, full pill radius (`9999px`), padding `0 10px`.
- **Nominal Pill (`OK / EN ROUTE`):** Background `#ECFDF5`, text `#059669`, border `1px solid #A7F3D0`. Includes a static `6px` emerald indicator dot.
- **Active Tracking Pill (`LIVE TELEMETRY`):** Background `#E0F2FE`, text `#0284C7`. Contains a pulsing `6px` cyan dot with a CSS radial ripple animation (`@keyframes pulse`).
- **Warning Pill (`DELAY / WEATHER`):** Background `#FFFBEB`, text `#D97706`, border `1px solid #FDE68A`.
- **Critical Pill (`GROUND STOP / CRITICAL`):** Background `#FEF2F2`, text `#DC2626`, border `1px solid #FECACA` with an active high-contrast warning icon.

### 3. Asset Cards & Dispatch Manifests
- **Header Asset Tag:** Distinctive asset iconography:
  - **Aviation:** Fixed-wing, rotorcraft, and cargo drone silhouettes.
  - **Ground Fleet:** Semi-trailer, box truck, and delivery van vector symbols.
- **Content Splitting:** Left side features Asset ID and Call Sign in `Inter Bold`; right side hosts real-time telemetry block (Altitude/Speed or Engine Temp/Speed) formatted in `JetBrains Mono`.
- **Active Focus:** Selecting an asset card highlights the border with a `2px solid #0284C7` frame.

### 4. Form Fields & Coordinate Inputs
- **Height:** Minimum `48px` on mobile/tablet devices.
- **Font:** Coordinate inputs (Latitude, Longitude, Altitude, Geohash) strictly render in `JetBrains Mono` at `14px`.
- **Borders:** Resting state `1px solid #CBD5E1`. Focused state `2px solid #0284C7` with no soft blur halo.

### 5. Checkboxes & Radio Selectors
- **Sizing:** Box size `20px x 20px` embedded in a minimum `48px x 48px` transparent bounding hit box to prevent misclicks on touch hardware.
- **Checked Accent:** `#0284C7` with sharp white tick icon.

### 6. Critical Alert Banners
- Full-width industrial header anchored to the top of the interface for priority override notifications (Runway incursions, geofence breaches, mechanical failures).
- Background `#FEF2F2`, left edge indicator strip of `4px solid #EF4444`, leading alert icon, JetBrains Mono timestamp (`UTC`), and direct action button (`ACKNOWLEDGE / REROUTE`).