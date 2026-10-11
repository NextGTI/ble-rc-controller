// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'BLE RC Controller';

  @override
  String get btOffTitle => 'Bluetooth desligado';

  @override
  String get btOffBody => 'Ligue o Bluetooth para encontrar o carro.';

  @override
  String get btDeniedTitle => 'Bluetooth bloqueado';

  @override
  String get btDeniedBody =>
      'Libere o Bluetooth para este app nos ajustes do sistema.';

  @override
  String get btUnsupportedTitle => 'Bluetooth LE indisponível';

  @override
  String get btUnsupportedBody =>
      'Este aparelho não consegue falar com o carro.';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get connectedLabel => 'Conectado';

  @override
  String get msgDropped => 'O carro desconectou.';

  @override
  String get rememberLast => 'Reconectar ao último carro';

  @override
  String get actionForward => 'Frente';

  @override
  String get actionReverse => 'Ré';

  @override
  String get actionLeft => 'Esquerda';

  @override
  String get actionRight => 'Direita';

  @override
  String get actionLight => 'Luz';

  @override
  String get actionTurbo => 'Turbo';

  @override
  String get actionDonut => 'Giro 360°';

  @override
  String get hintHold => 'enquanto pressionado';

  @override
  String get hintToggle => 'cada toque liga e desliga';

  @override
  String get add => 'Adicionar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get remove => 'Remover';

  @override
  String get restoreDefaults => 'Restaurar padrão';

  @override
  String get useKeyboard => 'Usar o teclado';

  @override
  String get sharedInput => 'Esta entrada também está atribuída a outra ação.';

  @override
  String get controllersTitle => 'Controles';

  @override
  String get noControllerHint =>
      'Pareie o controle por Bluetooth ou USB e aperte qualquer botão.';

  @override
  String get teachTitle => 'Ensinar controle';

  @override
  String get teachDone =>
      'Pronto! Este controle já funciona com todas as ações.';

  @override
  String get done => 'Pronto';

  @override
  String get skip => 'Pular';

  @override
  String rawInput(String key) {
    return 'Bruto: $key';
  }

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get onScreen => 'Botões na tela';

  @override
  String get onScreenHint => 'Para tablet e celular';

  @override
  String get disclaimer =>
      'Projeto de código aberto, independente e não oficial (MIT). Não é afiliado, endossado nem patrocinado por nenhuma marca de carros, brinquedos ou combustíveis. Todos os nomes pertencem aos seus donos.';

  @override
  String versionLabel(String version) {
    return 'Versão $version';
  }

  @override
  String get noCarShort => 'Nenhum carro';

  @override
  String get statusSearching => 'Procurando';

  @override
  String get statusConnecting => 'Conectando';

  @override
  String get statusReconnecting => 'Reconectando';

  @override
  String get batteryLabel => 'bateria';

  @override
  String get searchTitle => 'Ligue o carro';

  @override
  String get searchBody => 'Ele aparece aqui sozinho, em poucos segundos.';

  @override
  String get tipNotShowingLabel => 'Não aparece?';

  @override
  String get tipNotShowing =>
      'Feche outros apps ligados a ele. O carro aceita uma conexão por vez.';

  @override
  String get tipStillLabel => 'Ainda nada?';

  @override
  String get tipStill => 'Desligue e ligue o carro de novo.';

  @override
  String get carsNearby => 'Carros por perto';

  @override
  String get actionConnect => 'Conectar';

  @override
  String get actionSwitch => 'Trocar';

  @override
  String get signalStrong => 'sinal forte';

  @override
  String get signalMedium => 'sinal médio';

  @override
  String get signalWeak => 'sinal fraco';

  @override
  String get btEnable => 'Ligar o Bluetooth';

  @override
  String get retry => 'Tentar de novo';

  @override
  String get close => 'Fechar';

  @override
  String connectingTitle(String car) {
    return 'Conectando ao $car';
  }

  @override
  String get connectingBody => 'Leva alguns segundos.';

  @override
  String get lostTag => 'Conexão perdida';

  @override
  String get lostBody =>
      'O carro parou. O app volta a conectar assim que ele aparecer.';

  @override
  String connectFailedTitle(String car) {
    return 'Não foi possível conectar ao $car';
  }

  @override
  String get connectFailedBody =>
      'Desligue e ligue o carro e confira se nenhum outro app está conectado a ele.';

  @override
  String get lightOn => 'Acesa';

  @override
  String get lightOff => 'Apagada';

  @override
  String get turboOn => 'Ativo';

  @override
  String get turboOff => 'Desligado';

  @override
  String get spinOn => 'Girando';

  @override
  String get spinOff => 'Parado';

  @override
  String get cellController => 'Controle';

  @override
  String get noControllerShort => 'Nenhum controle';

  @override
  String get keySpace => 'Espaço';

  @override
  String get legendSteer => 'Direção';

  @override
  String steerRight(int deg) {
    return '$deg° direita';
  }

  @override
  String steerLeft(int deg) {
    return '$deg° esquerda';
  }

  @override
  String get gaugeLeft => 'esquerda';

  @override
  String get gaugeRight => 'direita';

  @override
  String get scaleForward => 'frente';

  @override
  String get scaleReverse => 'ré';

  @override
  String get scaleTurbo => 'turbo';

  @override
  String get groupCommands => 'Comandos';

  @override
  String get groupDriving => 'Pilotagem';

  @override
  String get groupApp => 'App';

  @override
  String get bindingsTitle => 'Botões e teclas';

  @override
  String get bindingsHint => 'O que cada entrada faz';

  @override
  String get deadzoneTitle => 'Zona morta do analógico';

  @override
  String get deadzoneHint => 'Ignora toques leves no analógico';

  @override
  String get aboutTitle => 'Sobre';

  @override
  String aboutHint(String version) {
    return 'Versão $version, código aberto';
  }

  @override
  String get aboutRepository => 'Código-fonte';

  @override
  String get aboutLicenseMit => 'Licença MIT';

  @override
  String get aboutLicenses => 'Licenças de código aberto';

  @override
  String get bindingsLeadTouch =>
      'Toque em Adicionar e aperte um botão do controle, mova o analógico ou aperte uma tecla.';

  @override
  String get bindingsLeadClick =>
      'Clique em Adicionar e aperte um botão do controle, mova o analógico ou aperte uma tecla.';

  @override
  String captureWaiting(String action) {
    return 'Aperte o que vai acionar $action';
  }

  @override
  String get connectedSection => 'Conectados';

  @override
  String get recognized => 'Reconhecido';

  @override
  String get taught => 'Ensinado';

  @override
  String get liveSignals => 'Sinais ao vivo';

  @override
  String get liveSignalsHint =>
      'Aperte botões para ver os sinais. Útil para conferir um controle que o app não conhece.';

  @override
  String get teachNew => 'Ensinar um controle novo';

  @override
  String get forgetTaught => 'Esquecer o que foi ensinado';

  @override
  String teachStep(int n, int total) {
    return 'Passo $n de $total';
  }

  @override
  String get teachGroupFace => 'Botões de ação';

  @override
  String get teachGroupShoulders => 'Ombros e gatilhos';

  @override
  String get teachGroupMiddle => 'Botões do meio';

  @override
  String get teachGroupSticks => 'Analógicos';

  @override
  String get teachGroupDpad => 'Direcional';

  @override
  String get teachHint_a => '✕ no PlayStation, A no Xbox, B no Switch';

  @override
  String get teachHint_b => '○ no PlayStation, B no Xbox, A no Switch';

  @override
  String get teachHint_x => '□ no PlayStation, X no Xbox, Y no Switch';

  @override
  String get teachHint_y => '△ no PlayStation, Y no Xbox, X no Switch';

  @override
  String get teachHint_leftBumper =>
      'L1 no PlayStation, LB no Xbox, L no Switch';

  @override
  String get teachHint_rightBumper =>
      'R1 no PlayStation, RB no Xbox, R no Switch';

  @override
  String get teachHint_leftTrigger =>
      'L2 no PlayStation, LT no Xbox, ZL no Switch';

  @override
  String get teachHint_rightTrigger =>
      'R2 no PlayStation, RT no Xbox, ZR no Switch';

  @override
  String get teachHint_back =>
      'Share no PlayStation, View no Xbox, − no Switch';

  @override
  String get teachHint_start =>
      'Options no PlayStation, Menu no Xbox, + no Switch';

  @override
  String get padA => 'Botão de baixo (A / ✕)';

  @override
  String get padB => 'Botão da direita (B / ○)';

  @override
  String get padX => 'Botão da esquerda (X / □)';

  @override
  String get padY => 'Botão de cima (Y / △)';

  @override
  String get padLeftBumper => 'Bumper esquerdo (LB / L1)';

  @override
  String get padRightBumper => 'Bumper direito (RB / R1)';

  @override
  String get padLeftTrigger => 'Gatilho esquerdo (LT / L2)';

  @override
  String get padRightTrigger => 'Gatilho direito (RT / R2)';

  @override
  String get padBack => 'Voltar (View / Share / −)';

  @override
  String get padStart => 'Início (Menu / Options / +)';

  @override
  String get padHome => 'Home (Guide / PS)';

  @override
  String get padLeftStick => 'Clique do analógico esquerdo (L3)';

  @override
  String get padRightStick => 'Clique do analógico direito (R3)';

  @override
  String get padTouchpad => 'Touchpad';

  @override
  String get padDpadUp => 'D-pad ↑';

  @override
  String get padDpadDown => 'D-pad ↓';

  @override
  String get padDpadLeft => 'D-pad ←';

  @override
  String get padDpadRight => 'D-pad →';

  @override
  String get padLeftStickUp => 'Analógico esq. ↑';

  @override
  String get padLeftStickDown => 'Analógico esq. ↓';

  @override
  String get padLeftStickLeft => 'Analógico esq. ←';

  @override
  String get padLeftStickRight => 'Analógico esq. →';

  @override
  String get padRightStickUp => 'Analógico dir. ↑';

  @override
  String get padRightStickDown => 'Analógico dir. ↓';

  @override
  String get padRightStickLeft => 'Analógico dir. ←';

  @override
  String get padRightStickRight => 'Analógico dir. →';

  @override
  String get teach_a => 'Aperte o botão de baixo';

  @override
  String get teach_b => 'Aperte o botão da direita';

  @override
  String get teach_x => 'Aperte o botão da esquerda';

  @override
  String get teach_y => 'Aperte o botão de cima';

  @override
  String get teach_leftBumper => 'Aperte o ombro esquerdo';

  @override
  String get teach_rightBumper => 'Aperte o ombro direito';

  @override
  String get teach_leftTrigger => 'Aperte o gatilho esquerdo';

  @override
  String get teach_rightTrigger => 'Aperte o gatilho direito';

  @override
  String get teach_back => 'Aperte o botão do meio, à esquerda';

  @override
  String get teach_start => 'Aperte o botão do meio, à direita';

  @override
  String get teach_leftStickX =>
      'Empurre o analógico esquerdo todo para a direita';

  @override
  String get teach_leftStickY => 'Empurre o analógico esquerdo todo para cima';

  @override
  String get teach_rightStickX =>
      'Empurre o analógico direito todo para a direita';

  @override
  String get teach_rightStickY => 'Empurre o analógico direito todo para cima';

  @override
  String get teach_dpadUp => 'Aperte o direcional para cima';

  @override
  String get teach_dpadDown => 'Aperte o direcional para baixo';

  @override
  String get teach_dpadLeft => 'Aperte o direcional para a esquerda';

  @override
  String get teach_dpadRight => 'Aperte o direcional para a direita';
}
