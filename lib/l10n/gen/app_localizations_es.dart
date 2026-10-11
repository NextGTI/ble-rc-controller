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
  String get disconnect => 'Desconectar';

  @override
  String get connectedLabel => 'Conectado';

  @override
  String get msgDropped => 'El coche se desconectó.';

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
  String get hintHold => 'mientras se mantiene pulsado';

  @override
  String get hintToggle => 'cada pulsación activa/desactiva';

  @override
  String get add => 'Añadir';

  @override
  String get cancel => 'Cancelar';

  @override
  String get remove => 'Quitar';

  @override
  String get restoreDefaults => 'Restaurar valores';

  @override
  String get useKeyboard => 'Usar el teclado';

  @override
  String get sharedInput => 'Esta entrada también está asignada a otra acción.';

  @override
  String get controllersTitle => 'Mandos';

  @override
  String get noControllerHint =>
      'Empareja tu mando por Bluetooth o USB y pulsa cualquier botón.';

  @override
  String get teachTitle => 'Enseñar mando';

  @override
  String get teachDone =>
      '¡Listo! Este mando ya funciona con todas las acciones.';

  @override
  String get done => 'Hecho';

  @override
  String get skip => 'Omitir';

  @override
  String rawInput(String key) {
    return 'En bruto: $key';
  }

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get onScreen => 'Botones en pantalla';

  @override
  String get onScreenHint => 'Para tabletas y móviles';

  @override
  String get disclaimer =>
      'Proyecto de código abierto, independiente y no oficial (MIT). No está afiliado, respaldado ni patrocinado por ninguna marca de coches, juguetes o combustibles. Todos los nombres pertenecen a sus dueños.';

  @override
  String versionLabel(String version) {
    return 'Versión $version';
  }

  @override
  String get noCarShort => 'Ningún coche';

  @override
  String get statusSearching => 'Buscando';

  @override
  String get statusConnecting => 'Conectando';

  @override
  String get statusReconnecting => 'Reconectando';

  @override
  String get batteryLabel => 'batería';

  @override
  String get searchTitle => 'Enciende el coche';

  @override
  String get searchBody => 'Aparece aquí solo, en pocos segundos.';

  @override
  String get tipNotShowingLabel => '¿No aparece?';

  @override
  String get tipNotShowing =>
      'Cierra otras apps conectadas a él. El coche acepta una sola conexión a la vez.';

  @override
  String get tipStillLabel => '¿Todavía nada?';

  @override
  String get tipStill => 'Apaga y enciende el coche de nuevo.';

  @override
  String get carsNearby => 'Coches cercanos';

  @override
  String get actionConnect => 'Conectar';

  @override
  String get actionSwitch => 'Cambiar';

  @override
  String get signalStrong => 'señal fuerte';

  @override
  String get signalMedium => 'señal media';

  @override
  String get signalWeak => 'señal débil';

  @override
  String get btEnable => 'Activar el Bluetooth';

  @override
  String get retry => 'Intentar de nuevo';

  @override
  String get close => 'Cerrar';

  @override
  String connectingTitle(String car) {
    return 'Conectando con $car';
  }

  @override
  String get connectingBody => 'Tarda unos segundos.';

  @override
  String get lostTag => 'Conexión perdida';

  @override
  String get lostBody =>
      'El coche se detuvo. La app vuelve a conectar en cuanto aparezca.';

  @override
  String connectFailedTitle(String car) {
    return 'No se pudo conectar con $car';
  }

  @override
  String get connectFailedBody =>
      'Apaga y enciende el coche y comprueba que ninguna otra app esté conectada a él.';

  @override
  String get lightOn => 'Encendida';

  @override
  String get lightOff => 'Apagada';

  @override
  String get turboOn => 'Activo';

  @override
  String get turboOff => 'Desactivado';

  @override
  String get spinOn => 'Girando';

  @override
  String get spinOff => 'Parado';

  @override
  String get cellController => 'Mando';

  @override
  String get noControllerShort => 'Ningún mando';

  @override
  String get keySpace => 'Espacio';

  @override
  String get legendSteer => 'Dirección';

  @override
  String steerRight(int deg) {
    return '$deg° derecha';
  }

  @override
  String steerLeft(int deg) {
    return '$deg° izquierda';
  }

  @override
  String get gaugeLeft => 'izquierda';

  @override
  String get gaugeRight => 'derecha';

  @override
  String get scaleForward => 'adelante';

  @override
  String get scaleReverse => 'marcha atrás';

  @override
  String get scaleTurbo => 'turbo';

  @override
  String get groupCommands => 'Comandos';

  @override
  String get groupDriving => 'Conducción';

  @override
  String get groupApp => 'App';

  @override
  String get bindingsTitle => 'Botones y teclas';

  @override
  String get bindingsHint => 'Qué hace cada entrada';

  @override
  String get deadzoneTitle => 'Zona muerta del stick';

  @override
  String get deadzoneHint => 'Ignora toques leves en el stick';

  @override
  String get aboutTitle => 'Acerca de';

  @override
  String aboutHint(String version) {
    return 'Versión $version, código abierto';
  }

  @override
  String get aboutRepository => 'Código fuente';

  @override
  String get aboutLicenseMit => 'Licencia MIT';

  @override
  String get aboutLicenses => 'Licencias de código abierto';

  @override
  String get bindingsLeadTouch =>
      'Toca Añadir y luego pulsa un botón del mando, mueve un stick o pulsa una tecla.';

  @override
  String get bindingsLeadClick =>
      'Haz clic en Añadir y luego pulsa un botón del mando, mueve un stick o pulsa una tecla.';

  @override
  String captureWaiting(String action) {
    return 'Pulsa lo que activará $action';
  }

  @override
  String get connectedSection => 'Conectados';

  @override
  String get recognized => 'Reconocido';

  @override
  String get taught => 'Enseñado';

  @override
  String get liveSignals => 'Señales en vivo';

  @override
  String get liveSignalsHint =>
      'Pulsa botones para ver las señales. Útil para comprobar un mando que la app no conoce.';

  @override
  String get teachNew => 'Enseñar un mando nuevo';

  @override
  String get forgetTaught => 'Olvidar lo enseñado';

  @override
  String teachStep(int n, int total) {
    return 'Paso $n de $total';
  }

  @override
  String get teachGroupFace => 'Botones de acción';

  @override
  String get teachGroupShoulders => 'Bumpers y gatillos';

  @override
  String get teachGroupMiddle => 'Botones centrales';

  @override
  String get teachGroupSticks => 'Sticks';

  @override
  String get teachGroupDpad => 'Cruceta';

  @override
  String get teachHint_a => '✕ en PlayStation, A en Xbox, B en Switch';

  @override
  String get teachHint_b => '○ en PlayStation, B en Xbox, A en Switch';

  @override
  String get teachHint_x => '□ en PlayStation, X en Xbox, Y en Switch';

  @override
  String get teachHint_y => '△ en PlayStation, Y en Xbox, X en Switch';

  @override
  String get teachHint_leftBumper =>
      'L1 en PlayStation, LB en Xbox, L en Switch';

  @override
  String get teachHint_rightBumper =>
      'R1 en PlayStation, RB en Xbox, R en Switch';

  @override
  String get teachHint_leftTrigger =>
      'L2 en PlayStation, LT en Xbox, ZL en Switch';

  @override
  String get teachHint_rightTrigger =>
      'R2 en PlayStation, RT en Xbox, ZR en Switch';

  @override
  String get teachHint_back =>
      'Share en PlayStation, View en Xbox, − en Switch';

  @override
  String get teachHint_start =>
      'Options en PlayStation, Menú en Xbox, + en Switch';

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
  String get teach_a => 'Pulsa el botón inferior';

  @override
  String get teach_b => 'Pulsa el botón derecho';

  @override
  String get teach_x => 'Pulsa el botón izquierdo';

  @override
  String get teach_y => 'Pulsa el botón superior';

  @override
  String get teach_leftBumper => 'Pulsa el bumper izquierdo';

  @override
  String get teach_rightBumper => 'Pulsa el bumper derecho';

  @override
  String get teach_leftTrigger => 'Aprieta el gatillo izquierdo';

  @override
  String get teach_rightTrigger => 'Aprieta el gatillo derecho';

  @override
  String get teach_back => 'Pulsa el botón central izquierdo';

  @override
  String get teach_start => 'Pulsa el botón central derecho';

  @override
  String get teach_leftStickX =>
      'Empuja el stick izquierdo del todo a la derecha';

  @override
  String get teach_leftStickY =>
      'Empuja el stick izquierdo del todo hacia arriba';

  @override
  String get teach_rightStickX =>
      'Empuja el stick derecho del todo a la derecha';

  @override
  String get teach_rightStickY =>
      'Empuja el stick derecho del todo hacia arriba';

  @override
  String get teach_dpadUp => 'Pulsa la cruceta hacia arriba';

  @override
  String get teach_dpadDown => 'Pulsa la cruceta hacia abajo';

  @override
  String get teach_dpadLeft => 'Pulsa la cruceta a la izquierda';

  @override
  String get teach_dpadRight => 'Pulsa la cruceta a la derecha';
}
