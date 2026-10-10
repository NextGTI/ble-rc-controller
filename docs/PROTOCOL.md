# Car protocol

**English** · [Español](PROTOCOL.es.md) · [Português](PROTOCOL.pt-BR.md)

This describes the Bluetooth LE interface of the supported toy cars, as implemented in `lib/core/protocol.dart`. It was worked out by observing the cars' behaviour and analysing the way their companion app builds its packets, purely to make a compatible controller. No code or assets from that app are included in this project.

## Finding the car

The car advertises:

- a local name starting with **`SL-`** (for example `SL-SF-25`),
- a 16-bit service **`6936`**.

The app lists a device if either matches. No pairing or PIN is needed.

## GATT

| Service | Characteristic | Properties | Use |
|---|---|---|---|
| `FFF0` | `FFF1` | write, write-without-response, notify | **Control packets** (this is what the app writes) |
| `FFF0` | `FFF2` | notify | not used |
| `6936` | `FE01` | write, write-without-response, notify | not used |
| Battery `180F` | `2A19` | read, notify | Battery percentage |

The car accepts **one connection at a time**.

## Control packet

Write **8 bytes** to `FFF1`, **without response**:

| Byte | Field | Values |
|---|---|---|
| 0 | mode | `1` (see below) |
| 1 | forward | `0` / `1` |
| 2 | reverse | `0` / `1` |
| 3 | left | `0` / `1` |
| 4 | right | `0` / `1` |
| 5 | light | `0` / `1` |
| 6 | turbo | `0` / `1` |
| 7 | 360° spin | `0` / `1` |

Every field is a plain on/off flag (the first byte is fixed); there is no proportional speed or steering. A packet with all flags at `0` stops the car.

Example — forward with the light on: `01 01 00 00 00 01 00 00`.

## Timing

The car's own app writes a packet only when something changes. This app also repeats the current packet at least every 200 ms. In testing, an idle connection was dropped by the car after about ten seconds.

Always send an all-zero (neutral) packet before disconnecting.

## Notes and unknowns

- `mode`: the car's own app can flip this byte between `1` and `2`. On the two cars tested (SF-25 and 296 GT3) driving with `1` and with `2` felt identical, so this app always sends `1` and does not offer it. What `2` does, if anything, is unknown.
- Tested on one car model. Other models appear to use the same interface; reports are welcome.
