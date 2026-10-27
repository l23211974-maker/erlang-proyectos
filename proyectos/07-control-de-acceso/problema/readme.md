# #7 — Control de acceso: el problema

## Contexto
Oficinas, plantas maquiladoras, hospitales y universidades controlan puertas con tarjetas o credenciales. En Tijuana la industria maquiladora emplea a cientos de miles de personas con turnos continuos; un acceso lento forma filas y uno inseguro compromete la planta.

## Datos del mundo real
- **Credenciales:** tarjetas RFID de 125 kHz (EM4100) y 13.56 MHz (MIFARE), huella, codigo QR, NFC en celular. Lectores envian por Wiegand (26/34 bits) o RS-485/OSDP.
- **Tiempo de respuesta esperado:** la puerta debe decidir en menos de ~0.5-1 s; el usuario percibe retraso mayor.
- **Modos de falla:** *fail-secure* (puerta cerrada sin energia) vs *fail-safe* (puerta abierta sin energia). Las salidas de emergencia deben abrir siempre (NOM-002-STPS-2010 en prevencion de incendios).
- **Reglas comunes:** horarios por rol, anti-passback (no entrar dos veces sin salir), puerta forzada, puerta abierta demasiado tiempo, tailgating.
- Las puertas deben seguir decidiendo aunque se caiga la red al servidor central.

## El problema
Decidir en tiempo real si una credencial puede abrir una puerta, registrar cada evento para auditoria, reaccionar cuando una puerta se comporta de manera anomala y permitir cambiar permisos (revocar una tarjeta perdida) con efecto inmediato.

## Escenario a simular
- 40 puertas, 2,000 personas, picos de 150 lecturas/minuto a cambio de turno.
- Servidor central incomunicado 30 minutos.
- Tarjeta reportada como robada y usada 3 veces en 1 minuto.

## Casos dificiles
- Revocacion que debe aplicar tambien a puertas sin conexion.
- Orden de eventos para anti-passback entre dos lectores.
- Auditoria que no puede perder eventos.

## Preguntas guia
1. ¿Que hace cada puerta cuando no puede consultar al servidor?
2. ¿Que eventos son "criticos" y no pueden descartarse bajo carga?

## Que debes entregar (sin que aqui se de la solucion)
- Un diseño OTP explicado brevemente: procesos, supervisores y quien reinicia a quien, justificando cada decision frente a los casos dificiles de arriba.
- La simulacion del escenario descrito, con datos generados y fallas inyectadas.
- Una lista de supuestos propios y de las cifras de este documento que verificaste.
- Una prueba de caos: que mataste, que esperabas y que ocurrio.
- `rebar3 compile` y `rebar3 eunit` en verde; capturas de Stitch y de la app real si hay interfaz.

---
*Las cifras son de referencia (ordenes de magnitud). Verifica la fuente vigente antes de citarlas en tu entrega y anota las que uses en tu README.*
