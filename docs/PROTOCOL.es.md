# Protocolo del coche

[English](PROTOCOL.md) · **Español** · [Português](PROTOCOL.pt-BR.md)

Describe la interfaz Bluetooth LE de los coches de juguete compatibles, tal como se implementa en `lib/core/protocol.dart`. Se obtuvo observando el comportamiento de los coches y analizando cómo su app construye los paquetes, únicamente para crear un mando compatible. Este proyecto no incluye código ni recursos de esa app.

## Encontrar el coche

El coche anuncia:

- un nombre local que empieza por **`SL-`** (por ejemplo `SL-SF-25`),
- un servicio de 16 bits **`6936`**.

La app muestra un dispositivo si coincide una de las dos cosas. No hace falta emparejar ni PIN.

## GATT

| Servicio | Característica | Propiedades | Uso |
|---|---|---|---|
| `FFF0` | `FFF1` | write, write-without-response, notify | **Paquetes de control** (lo que escribe la app) |
| `FFF0` | `FFF2` | notify | sin uso |
| `6936` | `FE01` | write, write-without-response, notify | sin uso |
| Batería `180F` | `2A19` | read, notify | Porcentaje de batería |

El coche acepta **una sola conexión a la vez**.

## Paquete de control

Escribe **8 bytes** en `FFF1`, **sin respuesta**:

| Byte | Campo | Valores |
|---|---|---|
| 0 | modo | `1` (ver abajo) |
| 1 | adelante | `0` / `1` |
| 2 | marcha atrás | `0` / `1` |
| 3 | izquierda | `0` / `1` |
| 4 | derecha | `0` / `1` |
| 5 | luz | `0` / `1` |
| 6 | turbo | `0` / `1` |
| 7 | giro 360° | `0` / `1` |

Todos los campos son indicadores de encendido/apagado (el primer byte es fijo); no hay velocidad ni dirección proporcionales. Un paquete con todos los indicadores a `0` detiene el coche.

Ejemplo — adelante con la luz encendida: `01 01 00 00 00 01 00 00`.

## Temporización

La app oficial del coche escribe un paquete solo cuando algo cambia. Esta app además repite el paquete actual al menos cada 200 ms. En las pruebas, una conexión sin tráfico fue cerrada por el coche tras unos diez segundos.

Envía siempre un paquete neutro (todo a cero) antes de desconectar.

## Notas y dudas

- `modo`: la app oficial del coche puede cambiar este byte entre `1` y `2`. En los dos coches probados (SF-25 y 296 GT3), conducir con `1` y con `2` se sintió igual, así que esta app siempre envía `1` y no lo ofrece. Qué hace `2`, si es que hace algo, no se sabe.
- Probado con un solo modelo de coche. Los demás parecen usar la misma interfaz; se agradecen reportes.
