# #53 — Paneles solares: el problema

## Contexto
Baja California tiene un recurso solar excelente: Tijuana recibe del orden de 5 a 5.5 horas solares pico al dia en promedio anual. Mucha gente instala paneles para reducir su recibo de CFE, pero no sabe si su sistema produce lo que deberia ni como aprovechar mejor la energia.

## Datos del mundo real
- Un panel moderno entrega 400-550 W de pico con ~20 % de eficiencia. Un sistema residencial de 3-5 kWp produce del orden de 15-25 kWh/dia en buen dia.
- La produccion depende de irradiancia, temperatura (cada °C sobre 25 °C resta ~0.3-0.4 % de potencia), suciedad, sombras, y nubosidad. En la costa, la capa marina (niebla matutina, "June gloom") reduce la produccion en las mañanas de primavera y verano.
- **Medicion neta** (CFE): la energia que inyectas a la red se compensa con la que consumes, para sistemas de hasta 500 kW.
- Un inversor reporta potencia AC, voltaje, corriente, temperatura y codigos de falla; la perdida de produccion rara vez avisa por si sola.
- Una casa consume energia de forma distinta a como el sol produce: pico de consumo en la tarde y noche vs. pico solar a mediodia.

## El problema
Medir produccion y consumo en tiempo real, calcular excedente o deficit, detectar un rendimiento anormalmente bajo (sombra, suciedad, falla) comparando contra el esperado segun las condiciones, y recomendar cuando conviene usar equipos de alto consumo para aprovechar el excedente.

## Escenario a simular
- Sistema de 4 kWp y casa con consumo variable, datos cada 1 min durante un dia.
- Nube pasajera que baja la produccion 70 % por 10 min.
- Un panel con sombra permanente desde las 3 p. m.

## Casos dificiles
- Distinguir nube de falla del equipo.
- Recomendaciones basadas en un pronostico imperfecto.
- Medidores de produccion y consumo con relojes distintos.

## Preguntas guia
1. ¿Cual es la produccion "esperada" y de que depende?
2. ¿Cuando una recomendacion es util y cuando es ruido?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
