// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'BLE RC Controller';

  @override
  String get navCars => 'Coches';

  @override
  String get navDrive => 'Conducir';

  @override
  String get navControls => 'Botones';

  @override
  String get navControllers => 'Mandos';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get carsTitle => 'Coches';

  @override
  String get carsSearching => 'Buscando coches…';

  @override
  String get carsHint =>
      'Enciende el coche. Aparece aquí solo (nombres que empiezan por «SL-»).';

  @override
  String get btOffTitle => 'Bluetooth apagado';

  @override
  String get btOffBody => 'Activa el Bluetooth para encontrar tu coche.';

  @override
  String get btDeniedTitle => 'Bluetooth bloqueado';

  @override
  String get btDeniedBody =>
      'Permite el Bluetooth para esta app en los ajustes del sistema.';

  @override
  String get btUnsupportedTitle => 'Bluetooth LE no disponible';

  @override
  String get btUnsupportedBody =>
      'Este dispositivo no puede comunicarse con el coche.';

  @override
  String get connect => 'Conectar';

  @override
  String connectTo(String car) {
    return 'Conectar con $car';
  }

  @override
  String get disconnect => 'Desconectar';

  @override
  String get connecting => 'Conectando…';

  @override
  String get connectedLabel => 'Conectado';

  @override
  String get noCar => 'Ningún coche conectado';

  @override
  String get noCarHint =>
      'Elige un coche de la lista para conectar (clic o toque).';

  @override
  String get msgConnectFailed =>
      'No se pudo conectar. Apaga y enciende el coche y comprueba que ninguna otra app esté conectada.';

  @override
  String get msgDropped => 'El coche se desconectó.';

  @override
  String get msgPermission => 'Se denegó el permiso de Bluetooth.';

  @override
  String batteryPercent(int percent) {
    return 'Batería $percent %';
  }

  @override
  String get rememberLast => 'Reconectar con el último coche';

  @override
  String get actionForward => 'Adelante';

  @override
  String get actionReverse => 'Marcha atrás';

  @override
  String get actionLeft => 'Izquierda';

  @override
  String get actionRight => 'Derecha';

  @override
  String get actionLight => 'Luz';

  @override
  String get actionTurbo => 'Turbo';

  @override
  String get actionDonut => 'Giro 360°';

  @override
  String get actionMode => 'Modo 1/2';

  @override
  String modeValue(int mode) {
    return 'Modo $mode';
  }

  @override
  String get hintHold => 'mientras se mantiene pulsado';

  @override
  String get hintToggle => 'cada pulsación activa/desactiva';

  @override
  String get controlsIntro =>
      'Pulsa «Añadir» y luego un botón del mando, mueve un stick o pulsa una tecla. Cada acción puede tener varias entradas.';

  @override
  String get add => 'Añadir';

  @override
  String get pressAnything => 'Pulsa un botón, dirección o tecla…';

  @override
  String get cancel => 'Cancelar';

  @override
  String get remove => 'Quitar';

  @override
  String get restoreDefaults => 'Restaurar valores';

  @override
  String get useKeyboard => 'Usar el teclado (solo con la app en primer plano)';

  @override
  String get sharedInput => 'Esta entrada también está asignada a otra acción.';

  @override
  String get controllersTitle => 'Mandos';

  @override
  String get noController => 'No se encontró ningún mando';

  @override
  String get noControllerHint =>
      'Empareja tu mando por Bluetooth o USB y pulsa cualquier botón.';

  @override
  String get controllerRecognised => 'Disposición reconocida';

  @override
  String get controllerCustom => 'Mapeo personalizado';

  @override
  String get teachController => 'Enseñar este mando…';

  @override
  String get forgetMapping => 'Olvidar mapeo personalizado';

  @override
  String get teachTitle => 'Enseñar mando';

  @override
  String get teachIntro =>
      'Pulsa el botón (o mueve el stick) que pide la app. Omite lo que tu mando no tenga. Pulsa Esc para cancelar.';

  @override
  String teachProgress(int n, int total) {
    return 'Paso $n de $total';
  }

  @override
  String get teachDone =>
      '¡Listo! Este mando ya funciona con todas las acciones.';

  @override
  String get done => 'Hecho';

  @override
  String get skip => 'Omitir';

  @override
  String get inputMonitor => 'Monitor de entradas';

  @override
  String get monitorHint =>
      'Pulsa botones y mueve sticks: aquí aparecen las señales en bruto. Útil con mandos desconocidos.';

  @override
  String get monitorEmpty => 'Aún no hay señales.';

  @override
  String rawInput(String key) {
    return 'En bruto: $key';
  }

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Predeterminado del sistema';

  @override
  String deadzone(int percent) {
    return 'Zona muerta del stick: $percent %';
  }

  @override
  String get onScreen => 'Mostrar controles en pantalla';

  @override
  String get onScreenHint =>
      'Botones táctiles para móviles y tabletas (o clics de ratón).';

  @override
  String get about => 'Acerca de';

  @override
  String get disclaimer =>
      'Proyecto de código abierto, independiente y no oficial (MIT). No está afiliado, respaldado ni patrocinado por ninguna marca de coches, juguetes o combustibles. Todos los nombres pertenecen a sus dueños.';

  @override
  String get driveLive => 'Entradas en vivo';

  @override
  String get keyboardTipTitle => 'Teclado';

  @override
  String get safetyNote =>
      'Las entradas solo cuentan con esta ventana en primer plano. Si cambias de app, el coche se detiene.';

  @override
  String get padA => 'Botón inferior (A / ✕)';

  @override
  String get padB => 'Botón derecho (B / ○)';

  @override
  String get padX => 'Botón izquierdo (X / □)';

  @override
  String get padY => 'Botón superior (Y / △)';

  @override
  String get padLeftBumper => 'Bumper izquierdo (LB / L1)';

  @override
  String get padRightBumper => 'Bumper derecho (RB / R1)';

  @override
  String get padLeftTrigger => 'Gatillo izquierdo (LT / L2)';

  @override
  String get padRightTrigger => 'Gatillo derecho (RT / R2)';

  @override
  String get padBack => 'Atrás (View / Share / −)';

  @override
  String get padStart => 'Inicio (Menú / Options / +)';

  @override
  String get padHome => 'Inicio (Guide / PS)';

  @override
  String get padLeftStick => 'Pulsar stick izquierdo (L3)';

  @override
  String get padRightStick => 'Pulsar stick derecho (R3)';

  @override
  String get padTouchpad => 'Panel táctil';

  @override
  String get padDpadUp => 'Cruceta ↑';

  @override
  String get padDpadDown => 'Cruceta ↓';

  @override
  String get padDpadLeft => 'Cruceta ←';

  @override
  String get padDpadRight => 'Cruceta →';

  @override
  String get padLeftStickUp => 'Stick izquierdo ↑';

  @override
  String get padLeftStickDown => 'Stick izquierdo ↓';

  @override
  String get padLeftStickLeft => 'Stick izquierdo ←';

  @override
  String get padLeftStickRight => 'Stick izquierdo →';

  @override
  String get padRightStickUp => 'Stick derecho ↑';

  @override
  String get padRightStickDown => 'Stick derecho ↓';

  @override
  String get padRightStickLeft => 'Stick derecho ←';

  @override
  String get padRightStickRight => 'Stick derecho →';

  @override
  String get teach_a => 'Pulsa el botón inferior (A / ✕)';

  @override
  String get teach_b => 'Pulsa el botón derecho (B / ○)';

  @override
  String get teach_x => 'Pulsa el botón izquierdo (X / □)';

  @override
  String get teach_y => 'Pulsa el botón superior (Y / △)';

  @override
  String get teach_leftBumper => 'Pulsa el bumper izquierdo (LB / L1)';

  @override
  String get teach_rightBumper => 'Pulsa el bumper derecho (RB / R1)';

  @override
  String get teach_leftTrigger => 'Aprieta el gatillo izquierdo (LT / L2)';

  @override
  String get teach_rightTrigger => 'Aprieta el gatillo derecho (RT / R2)';

  @override
  String get teach_back => 'Pulsa Atrás (View / Share / −)';

  @override
  String get teach_start => 'Pulsa Inicio (Menú / Options / +)';

  @override
  String get teach_leftStickX =>
      'Empuja el stick izquierdo del todo a la DERECHA';

  @override
  String get teach_leftStickY =>
      'Empuja el stick izquierdo del todo hacia ARRIBA';

  @override
  String get teach_rightStickX =>
      'Empuja el stick derecho del todo a la DERECHA';

  @override
  String get teach_rightStickY =>
      'Empuja el stick derecho del todo hacia ARRIBA';

  @override
  String get teach_dpadUp => 'Pulsa la cruceta ARRIBA';

  @override
  String get teach_dpadDown => 'Pulsa la cruceta ABAJO';

  @override
  String get teach_dpadLeft => 'Pulsa la cruceta IZQUIERDA';

  @override
  String get teach_dpadRight => 'Pulsa la cruceta DERECHA';
}
