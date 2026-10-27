# #35 — Control de calidad: el problema

## Contexto
En manufactura, un defecto descubierto en el cliente cuesta mucho mas que uno detectado en la linea. El control estadistico de procesos (SPC) distingue la variacion normal de una señal de que el proceso se desvio, antes de producir lotes enteros defectuosos. Es obligatorio en automotriz (IATF 16949) y dispositivos medicos (ISO 13485).

## Datos del mundo real
- **Cartas de control:** la media del proceso con limites a ±3 desviaciones estandar; un punto fuera de limites es señal de causa especial.
- **Reglas de Western Electric/Nelson** detectan patrones: 8 puntos seguidos del mismo lado de la media, 6 puntos en tendencia, 2 de 3 puntos cerca del limite.
- **Cpk** mide si el proceso cabe en la tolerancia; 1.33 es el minimo comun en automotriz, 1.67 para caracteristicas criticas. Seis Sigma = 3.4 defectos por millon de oportunidades.
- **Muestreo por aceptacion (AQL):** de un lote de 1,000 piezas se inspecciona una muestra (por ejemplo 80) y se acepta o rechaza el lote segun el numero de defectos encontrados.
- Un rechazo implica contener: segregar el lote, rastrear lotes vecinos y notificar.

## El problema
Recibir mediciones y resultados de inspeccion por lote y estacion, evaluar en tiempo real si el proceso esta bajo control, decidir aceptar, retener o rechazar un lote con un semaforo (verde/amarillo/rojo), y dejar trazabilidad de cada decision y de los lotes afectados.

## Escenario a simular
- 6 caracteristicas medidas cada 15 min, 20 lotes por turno.
- Una deriva lenta de la media a lo largo de 3 horas.
- Un lote rechazado que comparte materia prima con otros 4.

## Casos dificiles
- Mediciones faltantes o capturadas fuera de orden.
- Decidir con pocos datos sin falsas alarmas.
- Reabrir un lote rechazado tras reinspeccion.

## Preguntas guia
1. ¿Cuando una señal amerita parar la linea y cuando solo avisar?
2. ¿Como conectas un defecto con todo lo que pudo contaminar?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
