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
  String get navCars => 'Carros';

  @override
  String get navDrive => 'Pilotar';

  @override
  String get navControls => 'Botões';

  @override
  String get navControllers => 'Controles';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get carsTitle => 'Carros';

  @override
  String get carsSearching => 'Procurando carros…';

  @override
  String get carsHint =>
      'Ligue o carrinho. Ele aparece aqui sozinho (nomes que começam com “SL-”).';

  @override
  String get btOffTitle => 'Bluetooth desligado';

  @override
  String get btOffBody => 'Ligue o Bluetooth para encontrar o carrinho.';

  @override
  String get btDeniedTitle => 'Bluetooth bloqueado';

  @override
  String get btDeniedBody =>
      'Libere o Bluetooth para este app nos ajustes do sistema.';

  @override
  String get btUnsupportedTitle => 'Bluetooth LE indisponível';

  @override
  String get btUnsupportedBody =>
      'Este dispositivo não consegue falar com o carrinho.';

  @override
  String get connect => 'Conectar';

  @override
  String connectTo(String car) {
    return 'Conectar ao $car';
  }

  @override
  String get disconnect => 'Desconectar';

  @override
  String get connecting => 'Conectando…';

  @override
  String get connectedLabel => 'Conectado';

  @override
  String get noCar => 'Nenhum carro conectado';

  @override
  String get noCarHint =>
      'Escolha um carro na lista para conectar (clique ou toque).';

  @override
  String get msgConnectFailed =>
      'Não foi possível conectar. Desligue e ligue o carro e confira se nenhum outro app está conectado a ele.';

  @override
  String get msgDropped => 'O carro desconectou.';

  @override
  String get msgPermission => 'A permissão de Bluetooth foi negada.';

  @override
  String batteryPercent(int percent) {
    return 'Bateria $percent%';
  }

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
  String get actionMode => 'Modo 1/2';

  @override
  String modeValue(int mode) {
    return 'Modo $mode';
  }

  @override
  String get hintHold => 'enquanto estiver pressionado';

  @override
  String get hintToggle => 'cada toque liga/desliga';

  @override
  String get controlsIntro =>
      'Clique em “Adicionar” e aperte um botão do controle, empurre um analógico ou aperte uma tecla. Cada ação pode ter várias entradas.';

  @override
  String get add => 'Adicionar';

  @override
  String get pressAnything => 'Aperte um botão, direção ou tecla…';

  @override
  String get cancel => 'Cancelar';

  @override
  String get remove => 'Remover';

  @override
  String get restoreDefaults => 'Restaurar padrão';

  @override
  String get useKeyboard => 'Usar o teclado (só com o app em primeiro plano)';

  @override
  String get sharedInput => 'Esta entrada também está atribuída a outra ação.';

  @override
  String get controllersTitle => 'Controles';

  @override
  String get noController => 'Nenhum controle encontrado';

  @override
  String get noControllerHint =>
      'Pareie o controle por Bluetooth ou USB e aperte qualquer botão.';

  @override
  String get controllerRecognised => 'Layout reconhecido';

  @override
  String get controllerCustom => 'Mapeamento personalizado';

  @override
  String get teachController => 'Ensinar este controle…';

  @override
  String get forgetMapping => 'Esquecer mapeamento personalizado';

  @override
  String get teachTitle => 'Ensinar controle';

  @override
  String get teachIntro =>
      'Aperte o botão (ou mova o analógico) que o app pedir. Pule o que o seu controle não tiver. Esc cancela.';

  @override
  String teachProgress(int n, int total) {
    return 'Passo $n de $total';
  }

  @override
  String get teachDone =>
      'Pronto! Este controle já funciona com todas as ações.';

  @override
  String get done => 'Concluir';

  @override
  String get skip => 'Pular';

  @override
  String get inputMonitor => 'Monitor de entradas';

  @override
  String get monitorHint =>
      'Aperte botões e mova os analógicos: os sinais brutos aparecem aqui. Útil para controles desconhecidos.';

  @override
  String get monitorEmpty => 'Nenhum sinal ainda.';

  @override
  String rawInput(String key) {
    return 'Bruto: $key';
  }

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Padrão do sistema';

  @override
  String deadzone(int percent) {
    return 'Zona morta do analógico: $percent%';
  }

  @override
  String get onScreen => 'Mostrar controles na tela';

  @override
  String get onScreenHint =>
      'Botões de toque para celulares e tablets (ou cliques do mouse).';

  @override
  String get about => 'Sobre';

  @override
  String get disclaimer =>
      'Projeto de código aberto, independente e não oficial (MIT). Não é afiliado, endossado nem patrocinado por nenhuma marca de carros, brinquedos ou combustíveis. Todos os nomes pertencem aos seus donos.';

  @override
  String versionLabel(String version) {
    return 'Versão $version';
  }

  @override
  String get driveLive => 'Entradas ao vivo';

  @override
  String get keyboardTipTitle => 'Teclado';

  @override
  String get safetyNote =>
      'As entradas só valem com esta janela em primeiro plano. Se você trocar de app, o carro para.';

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
  String get teach_a => 'Aperte o botão de baixo (A / ✕)';

  @override
  String get teach_b => 'Aperte o botão da direita (B / ○)';

  @override
  String get teach_x => 'Aperte o botão da esquerda (X / □)';

  @override
  String get teach_y => 'Aperte o botão de cima (Y / △)';

  @override
  String get teach_leftBumper => 'Aperte o bumper esquerdo (LB / L1)';

  @override
  String get teach_rightBumper => 'Aperte o bumper direito (RB / R1)';

  @override
  String get teach_leftTrigger => 'Aperte o gatilho esquerdo (LT / L2)';

  @override
  String get teach_rightTrigger => 'Aperte o gatilho direito (RT / R2)';

  @override
  String get teach_back => 'Aperte Voltar (View / Share / −)';

  @override
  String get teach_start => 'Aperte Início (Menu / Options / +)';

  @override
  String get teach_leftStickX =>
      'Empurre o analógico esquerdo todo para a DIREITA';

  @override
  String get teach_leftStickY => 'Empurre o analógico esquerdo todo para CIMA';

  @override
  String get teach_rightStickX =>
      'Empurre o analógico direito todo para a DIREITA';

  @override
  String get teach_rightStickY => 'Empurre o analógico direito todo para CIMA';

  @override
  String get teach_dpadUp => 'Aperte o D-pad para CIMA';

  @override
  String get teach_dpadDown => 'Aperte o D-pad para BAIXO';

  @override
  String get teach_dpadLeft => 'Aperte o D-pad para a ESQUERDA';

  @override
  String get teach_dpadRight => 'Aperte o D-pad para a DIREITA';
}
