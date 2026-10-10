# BLE RC Controller

[English](README.md) · **Español** · [Português](README.pt-BR.md)

Conduce coches de juguete RC con Bluetooth LE usando un **mando** (DualShock 4, DualSense, Xbox, Switch Pro y otros), el **teclado** o **botones táctiles** en pantalla, desde tu ordenador o tu móvil Android.

La app oficial del coche solo funciona en móviles. Esta app usa la misma interfaz Bluetooth, así que puedes usar un mando de verdad.

> **Proyecto no oficial.** Es independiente, de código abierto (MIT) y **no está afiliado, respaldado ni patrocinado** por Shell ni por ninguna otra marca de coches, juguetes o combustibles. «Shell» y todos los demás nombres pertenecen a sus respectivos dueños y se usan aquí solo para indicar con qué coches funciona esta app. Consulta el [Aviso legal](#aviso-legal).

## Coches compatibles

- **Coches RC Bluetooth de Shell** (los que se venden en las gasolineras Shell). Verificado con un modelo; los demás modelos parecen usar la misma interfaz Bluetooth y deberían funcionar. Se agradecen reportes.
- **Vendrán más coches.** Se irá añadiendo compatibilidad con otros coches de juguete Bluetooth LE; consulta [CONTRIBUTING.md](CONTRIBUTING.md) para ayudar.

## Funciones

- Encuentra los coches cercanos y te deja **elegir cuál conducir** (puede haber varios encendidos).
- **Compatible con los mandos más comunes**, con un asistente **«Enseñar mando»** y un **monitor de entradas** para mandos que la app no conoce.
- **Reasigna todos los botones.** Cada acción (adelante, marcha atrás, izquierda, derecha, luz, turbo, giro 360°) admite varias entradas: botones del mando, direcciones del stick y teclas.
- Control por **teclado** (WASD / flechas por defecto) y **botones en pantalla** para pantallas táctiles.
- Nivel de batería, intensidad de señal y reconexión automática con el último coche.
- Seguridad: el coche se detiene al desconectar, cambiar de app o perder el mando.
- Disponible en **English, Español y Português**.

## Plataformas

| Plataforma | Estado |
|---|---|
| macOS | ✅ Verificado con un modelo de coche y un DualShock 4: conecta, muestra la batería y reconoce el mando. |
| Android | 🟡 Se compila en CI; aún sin probar en un dispositivo real — se agradecen reportes. |
| Windows | 🟡 Se compila en CI; aún sin probar en un PC real — se agradecen reportes. |
| iOS | ❌ No compatible. |

## Descarga

Descarga la última versión para tu sistema desde [**Releases**](../../releases):

- **Android:** `ble-rc-controller-<version>-android.apk` (permite «instalar apps desconocidas» a tu navegador o gestor de archivos).
- **macOS:** `ble-rc-controller-<version>-macos.zip`. La app no está notarizada; la primera vez: clic derecho → **Abrir**.
- **Windows:** `ble-rc-controller-<version>-windows.zip`. Descomprime y ejecuta `ble_rc_controller.exe`. Si SmartScreen avisa: **Más información → Ejecutar de todas formas**.

## Primeros pasos

1. **Cierra la app oficial del coche** en tu móvil: el coche solo acepta una conexión a la vez.
2. Enciende el coche y abre **BLE RC Controller**. El coche aparece en la lista **Coches** (los nombres empiezan por `SL-`). Haz clic o tócalo.
3. Empareja tu mando por Bluetooth (o conéctalo por USB) y pulsa cualquier botón. Aparece en **Mandos**.
4. ¡A conducir!

### Controles por defecto

| Acción | Mando | Teclado |
|---|---|---|
| Adelante | Gatillo derecho (R2 / RT) | ↑ o W |
| Marcha atrás | Gatillo izquierdo (L2 / LT) | ↓ o S |
| Izquierda / Derecha | Stick izquierdo o cruceta | ← → o A D |
| Luz (on/off) | Botón inferior (✕ / A) | L |
| Turbo (mantener) | Botón derecho (○ / B) | Espacio |
| Giro 360° (mantener) | Botón superior (△ / Y) | Q |

Empujar el stick izquierdo hacia arriba/abajo **no** conduce por defecto. Si lo prefieres, añádelo en **Botones** (*Adelante* → Añadir → empuja el stick hacia arriba).

En los botones en pantalla, **Luz**, **Turbo** y **Giro 360°** se activan y desactivan con cada toque.

Todo es editable en la pestaña **Botones**. Todo es encendido/apagado: el coche no tiene velocidad ni dirección proporcionales.

## Mandos compatibles

Los mandos se reconocen con una base de datos de mapeos integrada, así que las disposiciones **PlayStation (DualShock 4 / DualSense), Xbox y Switch Pro** funcionan directamente en las plataformas donde el sistema los expone como mandos.

Para cualquier otro, abre **Mandos → Enseñar este mando…** y pulsa uno a uno el botón que pide la app (omite lo que tu mando no tenga). También puedes usar el **Monitor de entradas** para ver las señales en bruto y asignar una señal directamente a una acción con **Botones → Añadir**.

## Teclado y pantalla táctil

- El teclado solo cuenta mientras la ventana de la app está en primer plano.
- **Ajustes → Mostrar controles en pantalla** activa los botones táctiles (por defecto en Android). Se pueden mantener varios a la vez.

## Solución de problemas

- **El coche no aparece** — apágalo y enciéndelo, cierra la app oficial en todos los móviles y comprueba que el Bluetooth esté activo. En Android concede el permiso de «Dispositivos cercanos».
- **«No se pudo conectar»** — probablemente otro dispositivo está conectado al coche.
- **No se detecta el mando** — empareja primero y luego pulsa un botón. En Windows, el sistema puede no reconocer un DualShock 4 como mando; herramientas como Steam Input o DS4Windows lo hacen pasar por un mando Xbox, o usa el asistente **Enseñar**.
- **Un botón no hace nada** — mira el **Monitor de entradas** (pestaña Mandos). Si la señal aparece allí, asígnala con **Botones → Añadir**.

## Compilar desde el código

Necesitas [Flutter](https://docs.flutter.dev/get-started/install) (estable, 3.47 o superior).

```bash
flutter pub get
flutter test
flutter run -d macos     # o: -d windows / -d <dispositivo android>
flutter build apk --release
```

Las traducciones están en `lib/l10n`. Edita `tool/gen_arb.py` (única fuente de los tres idiomas) y ejecuta `python3 tool/gen_arb.py && flutter gen-l10n`.

## Cómo funciona

El coche expone un servicio Bluetooth LE con una característica de solo escritura que recibe un **paquete de 8 bytes**. La app envía ese paquete cada vez que cambian tus entradas, y al menos cinco veces por segundo como señal de vida. Detalles en [docs/PROTOCOL.es.md](docs/PROTOCOL.es.md).

## Contribuir

Se agradecen issues y pull requests, sobre todo reportes de pruebas con hardware real (otros modelos de coche, Android, Windows, otros mandos). Consulta [CONTRIBUTING.md](CONTRIBUTING.md).

## Aviso legal

Es un proyecto independiente de interoperabilidad. No contiene, distribuye ni depende de código ni recursos del fabricante del coche ni de su app, y no usa logotipos. Los nombres de marcas aparecen solo para describir la compatibilidad. Úsalo bajo tu responsabilidad: el coche puede moverse de golpe, así que úsalo en un lugar despejado. Las leyes sobre ingeniería inversa e interoperabilidad varían según el país; nada aquí es asesoría legal.

## Licencia

[MIT](LICENSE)
