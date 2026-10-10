# Redesenho do app: plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Objetivo:** substituir toda a interface do app pela identidade e pela navegação aprovadas: painel primeiro, decalque, âmbar, partículas e vidro fosco. Todas as funções atuais continuam funcionando.

**Arquitetura:** o `Driver` continua sendo a única fonte de estado e ganha poucas propriedades novas. A pasta `lib/ui/` é refeita em módulos (`theme`, `common`, `cockpit`, `garage`, `settings`), com os desenhos feitos em `CustomPainter`. Um `Shell` escolhe o layout pelo tamanho da tela e decide onde os Ajustes abrem. As telas antigas só saem na última tarefa de código, depois que as novas estiverem testadas.

**Tecnologias:** Flutter (Dart 3), Material 3 só como base, `universal_ble`, `gamepads`, `shared_preferences`, `package_info_plus`, l10n gerado por `tool/gen_arb.py`, fonte Saira variável embutida.

**Especificação:** `docs/superpowers/specs/2026-10-10-redesign-design.md`. Ler antes de cada tarefa: as seções citadas em cada tarefa definem aparência, textos e comportamento.

As peças de divulgação (seção 9 da especificação) ficam para um plano próprio, depois deste, porque são renderizadas a partir do app novo.

## Restrições globais

- Tema escuro único, sem tema claro (especificação 3.1).
- Cores exatas da especificação 3.1: fundo `#0A0C0F`, texto `#ECEEF1`, texto 2 `#99A0AB`, texto 3 `#7D8591`, traço `#5E6570`, traço fraco `#363C45`, âmbar `#FFB547`, âmbar quente `#FF8A2A`, farol `#FFEBC8`, vidro branco a 4%, borda de vidro branco a 8%. **Texto nunca usa `#5E6570`.**
- Âmbar só em estado ativo, ação principal ou atenção.
- Fonte Saira variável (SIL OFL 1.1). Números e nomes com `wdth` 75 e `wght` 300 e algarismos de largura fixa (`FontFeature.tabularFigures()`). Texto corrido com `wdth` 100 e `wght` 400. Nunca caixa alta.
- Áreas de toque com no mínimo 48×48.
- Com "reduzir movimento" do sistema (`MediaQuery.disableAnimationsOf`) ligado: partículas, reflexo de vidro, desenho do decalque e giro ficam parados ou viram troca direta de estado.
- Nenhuma dependência nova de pacote. O único arquivo externo é a fonte, e baixá-la exige o OK do Daniel (Tarefa 1).
- Textos novos só em `tool/gen_arb.py`, nos três idiomas. A tupla segue a ordem `(en, es, pt, params)`. Depois de editar, rodar `python3 tool/gen_arb.py && flutter gen-l10n`.
- A lógica fica no `Driver`. As telas só leem dele e chamam seus métodos.
- Commits assinados (a configuração do git já assina), autor só Daniel Galhardi, **sem nenhuma linha `Co-Authored-By`** (regra do Daniel, que prevalece sobre o padrão da ferramenta). Nada de `git push` sem o OK do Daniel.
- `flutter analyze lib test` limpo e `flutter test` passando ao fim de cada tarefa.

## Pontos de atenção da revisão

Cinco situações que a especificação implica e que podem pegar quem usa o app. Cada uma tem teste na tarefa dona do código:

1. **Cancelar e logo conectar outro carro:** tocar em Cancelar durante "Conectando" e, em seguida, Conectar em outro carro. O app termina conectado só ao segundo, e uma conexão atrasada do primeiro é desfeita. Teste na Tarefa 2.
2. **Bluetooth desligado com o carro conectado:** o painel mostra "Bluetooth desligado", não "Conexão perdida" reconectando para sempre. Teste na Tarefa 2 (Driver) e na Tarefa 12 (tela).
3. **App em segundo plano com turbo travado e partículas rodando:** as entradas são limpas, o turbo destrava e as partículas param de desenhar. Teste na Tarefa 8 (partículas) e na Tarefa 9 (células).
4. **Nomes longos e textos em espanhol na tela de 320 de largura:** o nome do carro e as células cortam com reticências, sem estourar. Teste na Tarefa 11.
5. **Controle desconectado no meio de "Ensinar controle":** a tela continua de pé, avisa que não há controle e "Cancelar" funciona. Teste na Tarefa 14.

---

## Estrutura de arquivos

| Arquivo | Responsabilidade |
|---|---|
| `assets/fonts/Saira-Variable.ttf`, `assets/fonts/OFL-Saira.txt` | Fonte e licença |
| `lib/ui/theme/tokens.dart` | `AppColors`, `AppType`, `AppMotion`, `Breakpoints`, `LayoutKind`, `layoutFor()` |
| `lib/ui/theme/theme.dart` | `ThemeData buildAppTheme()` |
| `lib/ui/common/glass.dart` | `Glass` (superfície de vidro, com estado ativo) |
| `lib/ui/common/metal_text.dart` | `MetalText` (degradê metálico) |
| `lib/ui/common/notice.dart` | `Notice` (aviso âmbar com até duas ações) |
| `lib/ui/common/input_tag.dart` | `InputTag` (etiqueta de entrada) |
| `lib/ui/common/signal_meter.dart` | `SignalMeter` |
| `lib/ui/common/amber_switch.dart` | `AmberSwitch` |
| `lib/ui/common/settings_row.dart` | `SettingsRow`, `SettingsGroup` |
| `lib/ui/common/ambient.dart` | `AmbientBackdrop` (luz ambiente, granulação e reflexo de vidro) |
| `lib/ui/cockpit/car_decal.dart` | `CarDecal`, `DecalVariant`, `carBodyPath()` |
| `lib/ui/cockpit/steering_gauge.dart` | `SteeringGauge` |
| `lib/ui/cockpit/throttle_scale.dart` | `ThrottleScale`, `throttleFill()` |
| `lib/ui/cockpit/particles.dart` | `ParticleField`, `EffectsScope`, `flowTarget()`, `zoneFactor()` |
| `lib/ui/cockpit/state_cells.dart` | `StateCells` |
| `lib/ui/cockpit/touch_pads.dart` | `TouchPads` (as quatro setas) |
| `lib/ui/cockpit/key_legend.dart` | `KeyLegend` |
| `lib/ui/cockpit/cockpit_header.dart` | `CockpitHeader` |
| `lib/ui/cockpit/instrument.dart` | `Instrument` (decalque, transferidor, acelerador e partículas juntos) |
| `lib/ui/cockpit/cockpit_states.dart` | `SearchingView`, `BluetoothView`, `ConnectingView`, `LostView` |
| `lib/ui/cockpit/cockpit.dart` | `Cockpit` (escolhe o conteúdo pelo estado e o layout pelo tamanho) |
| `lib/ui/garage/car_list.dart` | `CarList` |
| `lib/ui/garage/car_sheet.dart` | `showCarSheet()` |
| `lib/ui/garage/garage_column.dart` | `GarageColumn` (computador) |
| `lib/ui/settings/settings_page.dart` | `SettingsPage` |
| `lib/ui/settings/bindings_page.dart` | `BindingsPage` |
| `lib/ui/settings/language_page.dart` | `LanguagePage` |
| `lib/ui/settings/about_page.dart` | `AboutPage` |
| `lib/ui/settings/controllers_page.dart` | `ControllersPage` |
| `lib/ui/settings/gamepad_drawing.dart` | `GamepadDrawing`, `gamepadPartFor()` |
| `lib/ui/settings/teach_page.dart` | `TeachPage`, `teachGroupOf()` |
| `lib/ui/shell.dart` | `Shell`, `openSettings()` |
| `test/support/fake_transport.dart` | `FakeTransport` compartilhado |
| `test/support/harness.dart` | `pumpWithDriver()` |

Saem na Tarefa 15: `lib/ui/home_page.dart`, `drive_page.dart`, `cars_panel.dart`, `controls_page.dart`, `controllers_page.dart`, `settings_page.dart`, `touch_controls.dart`, `widgets.dart`, `motion.dart`, além dos testes `drive_page_test.dart`, `controls_page_test.dart` e `touch_controls_test.dart`, que são substituídos.

---

### Tarefa 1: Tokens, tema e fonte

**Arquivos:**
- Criar: `lib/ui/theme/tokens.dart`, `lib/ui/theme/theme.dart`, `assets/fonts/Saira-Variable.ttf`, `assets/fonts/OFL-Saira.txt`
- Modificar: `pubspec.yaml` (seção `flutter: fonts:`), `lib/main.dart` (registrar a licença da fonte)
- Teste: `test/theme_test.dart`

**Interfaces:**
- Produz:
  - `AppColors`: constantes `bg`, `text`, `text2`, `text3`, `trace`, `traceWeak`, `amber`, `amberHot`, `headlight`, `glass`, `glassEdge`, `decal` (`#C9CFD8`) e `ghost` (`#4A515B`).
  - `AppType.numeric({required double size})` e `AppType.body({required double size, FontWeight weight = FontWeight.w400})`, ambos `TextStyle`.
  - `AppMotion`: `state` (220 ms), `needle` (350 ms), `spin` (550 ms), `draw` (1600 ms), `sweepEvery` (9 s).
  - `Breakpoints`: `tablet = 600`, `desktop = 900`, `landscapeMaxHeight = 500`.
  - `enum LayoutKind { phone, tablet, landscape, desktop }` e `LayoutKind layoutFor(Size s)`: `desktop` com largura ≥ 900; `landscape` com altura < 500 e largura ≥ 600; `tablet` com largura ≥ 600; `phone` nos demais casos.
  - `ThemeData buildAppTheme()`.

- [ ] **Passo 1: Pedir o OK do Daniel para baixar a fonte.** Os arquivos são `Saira[wdth,wght].ttf` e `OFL.txt`, de `https://github.com/google/fonts/tree/main/ofl/saira`, licença SIL OFL 1.1, cerca de 300 KB. Só seguir com a resposta afirmativa.
- [ ] **Passo 2: Baixar com `curl -L`** para uma pasta temporária nova e copiar como `assets/fonts/Saira-Variable.ttf` e `assets/fonts/OFL-Saira.txt`. Conferir com `file` que o `.ttf` é "TrueType Font data".
- [ ] **Passo 3: Escrever o teste que falha** em `test/theme_test.dart`:

```dart
double contrast(Color a, Color b) { /* razão WCAG 2.x: (L1+0.05)/(L2+0.05) */ }

test('text colours meet 4.5:1 on the background', () {
  for (final c in [AppColors.text, AppColors.text2, AppColors.text3, AppColors.amber]) {
    expect(contrast(c, AppColors.bg), greaterThanOrEqualTo(4.5));
  }
});
test('numbers are condensed, light and tabular', () {
  final s = AppType.numeric(size: 42);
  expect(s.fontFamily, 'Saira');
  expect(s.fontVariations, containsAll([const FontVariation('wdth', 75), const FontVariation('wght', 300)]));
  expect(s.fontFeatures, contains(const FontFeature.tabularFigures()));
});
test('layout kinds follow the breakpoints', () {
  expect(layoutFor(const Size(390, 844)), LayoutKind.phone);
  expect(layoutFor(const Size(600, 960)), LayoutKind.tablet);
  expect(layoutFor(const Size(800, 360)), LayoutKind.landscape);
  expect(layoutFor(const Size(1180, 760)), LayoutKind.desktop);
});
test('theme is dark with the amber accent', () {
  final t = buildAppTheme();
  expect(t.brightness, Brightness.dark);
  expect(t.scaffoldBackgroundColor, AppColors.bg);
  expect(t.colorScheme.primary, AppColors.amber);
});
```

- [ ] **Passo 4: Rodar** `flutter test test/theme_test.dart`. Resultado esperado: falha de compilação, porque `AppColors` ainda não existe.
- [ ] **Passo 5: Implementar `tokens.dart` e `theme.dart`.** No tema: `useMaterial3: true`, esquema escuro com `primary: AppColors.amber`, `surface: AppColors.bg`, `fontFamily: 'Saira'` e `textTheme` com os tamanhos da especificação 3.2. Declarar a família `Saira` no `pubspec.yaml`, apontando para `assets/fonts/Saira-Variable.ttf`. Em `main.dart`, registrar `assets/fonts/OFL-Saira.txt` com `LicenseRegistry.addLicense` (pacote `saira`). Declarar também o `.txt` em `assets:`.
- [ ] **Passo 6: Rodar** `flutter test test/theme_test.dart && flutter analyze lib test`. Resultado esperado: passa, sem avisos.
- [ ] **Passo 7: Commit:** `git add assets/fonts lib/ui/theme pubspec.yaml lib/main.dart test/theme_test.dart && git commit -m "Add the design tokens, dark theme and the Saira font"`

---

### Tarefa 2: Driver: reconexão, falha com nome e cancelar

**Arquivos:**
- Criar: `test/support/fake_transport.dart`, movendo para lá o `FakeTransport` de `test/driver_test.dart`
- Modificar: `lib/core/driver.dart`, `test/driver_test.dart`

**Interfaces:**
- Produz (no `Driver`):
  - `FoundCar? get lostCar`: carro que caiu enquanto a reconexão automática estava ligada.
  - `bool get reconnecting => lostCar != null && link == LinkState.idle`.
  - `FoundCar? get failedCar`: carro da última falha de conexão.
- Regras:
  - `lostCar` só é preenchido em `_onDropped` e só com `autoConnect` ligado.
  - `lostCar` é limpo quando: uma conexão dá certo; `disconnect()` é chamado; `autoConnect` passa a falso; o Bluetooth deixa de estar pronto.
  - `failedCar` é preenchido junto com `MessageKind.connectFailed` e limpo em `dismissMessage()` e no início de `connect()`.

- [ ] **Passo 1: Mover o `FakeTransport`** para `test/support/fake_transport.dart`, com um `StreamController<BluetoothState> avail` exposto em `availability`. Ajustar o import em `driver_test.dart` e rodar `flutter test test/driver_test.dart`. Resultado esperado: 21 testes passam, sem mudança de comportamento.
- [ ] **Passo 2: Escrever os testes que falham** em `driver_test.dart`:

```dart
test('a dropped link with auto-reconnect on shows the lost car', () async {
  await setUp0(); await connectCar();
  transport.conn.add(false); await settle();
  expect(driver.reconnecting, isTrue);
  expect(driver.lostCar!.model, 'SF-25');
});
test('no lost car when auto-reconnect is off', () async {
  await setUp0({'autoConnect': false}); await connectCar();
  transport.conn.add(false); await settle();
  expect(driver.reconnecting, isFalse);
  expect(driver.message, MessageKind.dropped);
});
test('Bluetooth turning off clears the lost car', () async {
  await setUp0(); await connectCar();
  transport.conn.add(false); await settle();
  transport.avail.add(BluetoothState.off); await settle();
  expect(driver.reconnecting, isFalse);
  expect(driver.bluetooth, BluetoothState.off);
});
test('a failed connection remembers which car failed', () async {
  await setUp0();
  transport.scan.add(const FoundCar(id: 'car1', name: 'SL-SF-25', rssi: -55)); await settle();
  transport.failConnect = true;
  await driver.connect('car1');
  expect(driver.failedCar!.model, 'SF-25');
  driver.dismissMessage();
  expect(driver.failedCar, isNull);
});
test('cancelling a connection then picking another car connects only the second', () async {
  await setUp0();
  transport.scan..add(const FoundCar(id: 'car1', name: 'SL-SF-25', rssi: -55))
                ..add(const FoundCar(id: 'car2', name: 'SL-296 GT3', rssi: -60));
  await settle();
  transport.connectDelay = const Duration(milliseconds: 200); // car1 is slow
  final first = driver.connect('car1');
  await driver.disconnect();                 // Cancel
  transport.connectDelay = Duration.zero;
  await driver.connect('car2');
  await first;
  expect(driver.carId, 'car2');
  expect(transport.connected, ['car2'], reason: 'the late car1 connection is undone');
});
```

  O `FakeTransport` ganha `Duration connectDelay = Duration.zero`, aplicado em `connect()`.
- [ ] **Passo 3: Rodar** `flutter test test/driver_test.dart`. Resultado esperado: os cinco testes novos falham, porque `reconnecting`, `lostCar` e `failedCar` não existem.
- [ ] **Passo 4: Implementar** os campos e as regras da seção Interfaces em `driver.dart`. O cancelamento já é tratado pelo `_connectToken`. Se o último teste ainda falhar, corrigir o caminho em que a conexão antiga termina depois do token ter mudado.
- [ ] **Passo 5: Rodar** `flutter test test/driver_test.dart`. Resultado esperado: todos passam.
- [ ] **Passo 6: Commit:** `git add lib/core/driver.dart test/driver_test.dart test/support && git commit -m "Driver: track the lost and the failed car; prove cancel-then-switch"`

---

### Tarefa 3: Bluetooth, permissão, sinal e atalhos

**Arquivos:**
- Modificar: `lib/core/car_transport.dart`, `lib/core/ble_transport.dart`, `lib/core/driver.dart`, `lib/input/bindings.dart`, `test/support/fake_transport.dart`
- Teste: `test/driver_test.dart`, `test/bindings_test.dart`, `test/signal_test.dart`

**Interfaces:**
- Produz:
  - Em `CarTransport`: `bool get canEnableBluetooth` e `Future<bool> enableBluetooth()`.
  - Em `UniversalBleTransport`: `canEnableBluetooth` é verdadeiro só no Android (`defaultTargetPlatform == TargetPlatform.android`), e `enableBluetooth()` chama `UniversalBle.enableBluetooth()`, devolvendo falso se lançar erro.
  - No `Driver`: `bool get canEnableBluetooth`, `Future<void> enableBluetooth()` e `Future<void> retryPermissions()`. O `retryPermissions` chama `transport.requestPermissions()`. Com sucesso, limpa `MessageKind.permissionDenied` e relê `currentAvailability()`. Com erro, mantém a mensagem.
  - Em `car_transport.dart`: `enum SignalStrength { strong, medium, weak }` e `SignalStrength get signalStrength` em `FoundCar`. O nível 4 é `strong`, os níveis 3 e 2 são `medium` e o nível 1 é `weak`.
  - Em `bindings.dart`: `InputRef? firstPadInput(Bindings b, CarAction a)` (primeira entrada de controle, `pad` ou `raw`) e `List<InputRef> keyInputs(Bindings b, CarAction a)` (todas as teclas, na ordem).

- [ ] **Passo 1: Escrever os testes que falham:**

```dart
// test/signal_test.dart
test('four bar levels map to three words', () {
  expect(const FoundCar(id: 'a', name: 'SL-X', rssi: -55).signalStrength, SignalStrength.strong);
  expect(const FoundCar(id: 'a', name: 'SL-X', rssi: -70).signalStrength, SignalStrength.medium);
  expect(const FoundCar(id: 'a', name: 'SL-X', rssi: -80).signalStrength, SignalStrength.medium);
  expect(const FoundCar(id: 'a', name: 'SL-X', rssi: -90).signalStrength, SignalStrength.weak);
});
// test/bindings_test.dart
test('shortcut helpers read the current bindings', () {
  final b = defaultBindings();
  expect(firstPadInput(b, CarAction.turbo), InputRef.pad(PadInput.b));
  expect(keyInputs(b, CarAction.forward).map((r) => r.keyText), ['↑', 'W']);
  expect(firstPadInput({CarAction.turbo: [InputRef.key(PhysicalKeyboardKey.space)]}, CarAction.turbo), isNull);
});
// test/driver_test.dart
test('retrying the permission clears the denial when it is granted', () async {
  transport.denyPermission = true; await setUp0();
  expect(driver.message, MessageKind.permissionDenied);
  transport.denyPermission = false;
  await driver.retryPermissions();
  expect(driver.message, isNull);
});
test('enableBluetooth goes through the transport', () async {
  await setUp0();
  await driver.enableBluetooth();
  expect(transport.enableCalls, 1);
});
```

  O `FakeTransport` ganha `bool denyPermission`, `int permissionCalls` (incrementado em cada `requestPermissions`), `int enableCalls` e `bool canEnableBluetooth = true`.
- [ ] **Passo 2: Rodar** `flutter test`. Resultado esperado: os testes novos falham na compilação.
- [ ] **Passo 3: Implementar** as interfaces acima. Atualizar também o `DemoTransport` de `marketing/render_ui_test.dart`, que é um arquivo local, para continuar compilando.
- [ ] **Passo 4: Rodar** `flutter test && flutter analyze lib test`. Resultado esperado: tudo passa.
- [ ] **Passo 5: Commit:** `git add lib/core lib/input/bindings.dart test && git commit -m "Add Bluetooth enable, permission retry, signal words and shortcut helpers"`

---

### Tarefa 4: Textos

**Arquivos:**
- Modificar: `tool/gen_arb.py`; arquivos gerados em `lib/l10n/`
- Teste: `test/l10n_test.dart`

**Interfaces:**
- Produz: as chaves abaixo em `AppLocalizations`. As tarefas seguintes usam esses nomes exatos.

Chaves novas, em português. O inglês e o espanhol seguem o mesmo sentido e a mesma terminologia dos textos atuais em cada idioma:

| Chave | Português |
|---|---|
| `noCarShort` | Nenhum carro |
| `statusSearching` / `statusConnecting` / `statusReconnecting` | Procurando / Conectando / Reconectando |
| `batteryLabel` | bateria |
| `searchTitle` / `searchBody` | Ligue o carro / Ele aparece aqui sozinho, em poucos segundos. |
| `tipNotShowingLabel` / `tipNotShowing` | Não aparece? / Feche outros apps ligados a ele. O carro aceita uma conexão por vez. |
| `tipStillLabel` / `tipStill` | Ainda nada? / Desligue e ligue o carro de novo. |
| `carsNearby` | Carros por perto |
| `actionConnect` / `actionSwitch` | Conectar / Trocar |
| `signalStrong` / `signalMedium` / `signalWeak` | sinal forte / sinal médio / sinal fraco |
| `btEnable` / `retry` / `close` | Ligar o Bluetooth / Tentar de novo / Fechar |
| `connectingTitle(car)` / `connectingBody` | Conectando ao {car} / Leva alguns segundos. |
| `lostTag` / `lostBody` | Conexão perdida / O carro parou. O app volta a conectar assim que ele aparecer. |
| `connectFailedTitle(car)` / `connectFailedBody` | Não foi possível conectar ao {car} / Desligue e ligue o carro e confira se nenhum outro app está conectado a ele. |
| `lightOn` / `lightOff` | Acesa / Apagada |
| `turboOn` / `turboOff` | Ativo / Desligado |
| `spinOn` / `spinOff` | Girando / Parado |
| `cellController` / `noControllerShort` | Controle / Nenhum controle |
| `steerRight(deg)` / `steerLeft(deg)` | {deg}° direita / {deg}° esquerda |
| `scaleForward` / `scaleReverse` / `scaleTurbo` | frente / ré / turbo |
| `groupCommands` / `groupDriving` / `groupApp` | Comandos / Pilotagem / App |
| `bindingsTitle` / `bindingsHint` | Botões e teclas / O que cada entrada faz |
| `controllersTitle` | Controles |
| `deadzoneTitle` / `deadzoneHint` | Zona morta do analógico / Ignora toques leves no analógico |
| `aboutTitle` / `aboutHint(version)` | Sobre / Versão {version}, código aberto |
| `bindingsLeadTouch` / `bindingsLeadClick` | Toque em Adicionar e aperte um botão do controle, mova o analógico ou aperte uma tecla. / Clique em Adicionar e aperte um botão do controle, mova o analógico ou aperte uma tecla. |
| `captureWaiting(action)` | Aperte o que vai acionar {action} |
| `connectedSection` / `recognized` / `taught` | Conectados / Reconhecido / Ensinado |
| `liveSignals` / `liveSignalsHint` | Sinais ao vivo / Aperte botões para ver os sinais. Útil para conferir um controle que o app não conhece. |
| `teachNew` / `forgetTaught` | Ensinar um controle novo / Esquecer o que foi ensinado |
| `teachTitle` / `teachStep(n, total)` / `done` | Ensinar controle / Passo {n} de {total} / Pronto |
| `teachGroupFace` / `teachGroupShoulders` / `teachGroupMiddle` / `teachGroupSticks` / `teachGroupDpad` | Botões de ação / Ombros e gatilhos / Botões do meio / Analógicos / Direcional |
| `teachHint_a` / `_b` / `_x` / `_y` | ✕ no PlayStation, A no Xbox, B no Switch / ○ no PlayStation, B no Xbox, A no Switch / □ no PlayStation, X no Xbox, Y no Switch / △ no PlayStation, Y no Xbox, X no Switch |
| `teachHint_leftBumper` / `_rightBumper` / `_leftTrigger` / `_rightTrigger` | L1 no PlayStation, LB no Xbox, L no Switch / R1, RB, R / L2, LT, ZL / R2, RT, ZR (mesmo formato) |
| `teachHint_back` / `_start` | Share no PlayStation, View no Xbox, − no Switch / Options no PlayStation, Menu no Xbox, + no Switch |

Textos que mudam:

| Chave | Novo texto em português |
|---|---|
| `useKeyboard` | Usar o teclado |
| `onScreenHint` | Para tablet e celular |
| `btUnsupportedBody` | Este aparelho não consegue falar com o carro. |
| `teach_*` (os 18) | Instrução curta, sem parênteses e sem caixa alta. Exemplos: `teach_a` "Aperte o botão de baixo"; `teach_leftTrigger` "Aperte o gatilho esquerdo"; `teach_leftStickX` "Empurre o analógico esquerdo todo para a direita"; `teach_dpadUp` "Aperte o direcional para cima" |

- [ ] **Passo 1: Escrever o teste que falha** em `test/l10n_test.dart`. Para cada idioma (`en`, `es`, `pt`), carregar `AppLocalizations.delegate.load(Locale(code))` e conferir:
  - que não estão vazios: `searchTitle`, `connectingTitle('SF-25')`, `teachHint_a` e `teachStep(1, 18)`;
  - em `pt`: `connectingTitle('SF-25') == 'Conectando ao SF-25'` e `teachStep(4, 18) == 'Passo 4 de 18'`;
  - em `pt`, que `teach_leftStickX` não contém letras maiúsculas depois da primeira (`RegExp(r'^.[^A-ZÀ-Ú]*$')`).
- [ ] **Passo 2: Rodar** `flutter test test/l10n_test.dart`. Resultado esperado: falha, porque as chaves não existem.
- [ ] **Passo 3: Acrescentar e alterar as chaves** em `tool/gen_arb.py`, nos três idiomas, e rodar `python3 tool/gen_arb.py && flutter gen-l10n`.
- [ ] **Passo 4: Rodar** `flutter test && flutter analyze lib test`. Resultado esperado: tudo passa. As telas antigas continuam compilando, porque nenhuma chave foi removida.
- [ ] **Passo 5: Commit:** `git add tool/gen_arb.py lib/l10n test/l10n_test.dart && git commit -m "Add the strings for the redesigned screens"`

---

### Tarefa 5: Componentes comuns

**Arquivos:**
- Criar: os oito arquivos de `lib/ui/common/` da tabela de estrutura, e `test/support/harness.dart`
- Teste: `test/common_test.dart`

**Interfaces:**
- Produz:
  - `Glass({required Widget child, bool active = false, double radius = 16, EdgeInsets padding = const EdgeInsets.all(12), VoidCallback? onTap})`. Usa `BackdropFilter` com desfoque de 14, fundo `AppColors.glass`, borda `glassEdge` e filete de luz no topo. Com `active`, segue a especificação 3.3.
  - `MetalText(String text, {required TextStyle style, int maxLines = 1})`, com `ShaderMask` em degradê de `#FFFFFF` a `#8E959F` e `TextOverflow.ellipsis`.
  - `Notice({required String title, required String body, String? primaryLabel, VoidCallback? onPrimary, String? secondaryLabel, VoidCallback? onSecondary})`.
  - `InputTag({required String label, required InputKind kind, bool shared = false, VoidCallback? onRemove})`. O ícone de controle vem para `pad` e `raw`, e o de teclado para `key`.
  - `SignalMeter({required String label, required double value})`. O valor é limitado a 0..1 e mostrado com duas casas no formato do idioma (`NumberFormat('0.00', locale)` do `intl`, que já vem com o Flutter).
  - `AmberSwitch({required bool value, required ValueChanged<bool> onChanged})`.
  - `SettingsGroup({required String title, required List<Widget> rows})` e `SettingsRow({required String title, String? subtitle, Widget? trailing, VoidCallback? onTap})`.
  - `AmbientBackdrop({bool sweep = false})`: o fundo da especificação 3.3. Tem o degradê frio do alto, o foco quente central, os cantos escurecidos e a granulação (ruído desenhado uma vez, com semente fixa, a 8%). Com `sweep`, uma faixa diagonal a 5,5% atravessa a tela a cada `AppMotion.sweepEvery`. A faixa não anima com "reduzir movimento" nem com `EffectsScope.particlesOf` falso. É usado atrás do `Cockpit` (com `sweep`) e das telas de Ajustes (sem).
  - `Future<void> pumpWithDriver(WidgetTester t, Driver d, Widget child, {Size size = const Size(390, 844), String locale = 'pt', bool reduceMotion = false})`. Monta `MaterialApp` com `buildAppTheme()`, os delegados de l10n, `DriverScope`, `EffectsScope(particles: false)` (Tarefa 8) e `MediaQuery(disableAnimations: reduceMotion)`.

- [ ] **Passo 1: Escrever os testes que falham** em `test/common_test.dart`:
  - `Notice` mostra título e corpo; tocar em `primaryLabel` chama `onPrimary` uma vez.
  - `InputTag` com `onRemove` mostra o botão "×" com a dica `remove`; tocar chama `onRemove`.
  - `SignalMeter(label: 'R2', value: 0.72)` mostra `0,72` em `pt` e `0.72` em `en`; `value: 1.7` mostra `1,00`.
  - `AmberSwitch` alterna e chama `onChanged(true)`.
  - `AmbientBackdrop(sweep: true)` dentro de `EffectsScope(particles: false)` não deixa quadro agendado depois de `pump()`.
  - `MetalText` com texto longo numa caixa de 120 de largura não gera exceção de estouro.

  Até a Tarefa 8, o harness usa um `EffectsScope` provisório.
- [ ] **Passo 2: Rodar** `flutter test test/common_test.dart`. Resultado esperado: falha de compilação.
- [ ] **Passo 3: Implementar** os componentes e o harness. Criar o `EffectsScope` mínimo já em `lib/ui/cockpit/particles.dart`, com `InheritedWidget`, `final bool particles` e `static bool particlesOf(BuildContext)` (padrão `true` sem escopo). A Tarefa 8 completa o arquivo.
- [ ] **Passo 4: Rodar** `flutter test && flutter analyze lib test`. Resultado esperado: passa.
- [ ] **Passo 5: Commit:** `git add lib/ui/common lib/ui/cockpit/particles.dart test/support/harness.dart test/common_test.dart && git commit -m "Add the shared glass components"`

---

### Tarefa 6: Decalque do carro

**Arquivos:**
- Criar: `lib/ui/cockpit/car_decal.dart`
- Teste: `test/car_decal_test.dart`

**Interfaces:**
- Produz:
  - `enum DecalVariant { solid, ghost, drawing, icon }`.
  - `Path carBodyPath(Size size)`: o contorno da especificação 4.1, no espaço 100×200 e escalado para `size`. Os pontos vêm do caminho SVG `M50 3 C38 3 29 6 24 12 …` usado nos esboços (`direcao-a-v11.html`, constante `BODY`).
  - `double wheelAngle(int steer)`: `steer * 18 * pi / 180`.
  - `CarDecal({DecalVariant variant = DecalVariant.solid, int steer = 0, bool lights = false, bool turbo = false, bool spinning = false, Color? iconColor})`, com `steer` em −1, 0 ou 1.
  - Comportamento:
    - O widget faz o giro de 360° em `AppMotion.spin` quando `spinning` passa a verdadeiro, e a inclinação de `steer * 4.5°`.
    - `drawing` anima o traço de 0 a 1 em `AppMotion.draw`, em repetição, extraindo o trecho com `PathMetric`.
    - Com "reduzir movimento", `drawing` mostra o traço completo e o giro não anima.

- [ ] **Passo 1: Escrever os testes que falham:**
  - `wheelAngle(1) == 18 * pi / 180`, `wheelAngle(-1) == -wheelAngle(1)` e `wheelAngle(0) == 0`.
  - `carBodyPath(const Size(100, 200)).getBounds()` fica dentro de `Rect.fromLTWH(10, 2, 81, 196)` com tolerância de 1.
  - Cada variante renderiza em 80×160 sem exceção, com e sem "reduzir movimento".
  - Com `spinning: true` e "reduzir movimento" ligado, depois de um `pump()` não há frames pendentes (`tester.hasRunningAnimations` é falso).
- [ ] **Passo 2: Rodar** `flutter test test/car_decal_test.dart`. Resultado esperado: falha de compilação.
- [ ] **Passo 3: Implementar** `car_decal.dart` com um `CustomPainter`. Desenhar na ordem: rodas, carroceria, para-brisa, teto, vidro traseiro, linha central tracejada, faróis e lanternas. Por cima, nas condições certas: fachos (degradê `headlight` de 50% a 0, terminando 76 unidades acima do carro) e halo do turbo (degradê radial de `amber` a `amberHot` até transparente). As cores e espessuras são as da especificação 4.1. `ghost` aplica traço tracejado (4, 4) em `AppColors.ghost` a todos os elementos.
- [ ] **Passo 4: Rodar** os testes. Resultado esperado: passam.
- [ ] **Passo 5: Commit:** `git add lib/ui/cockpit/car_decal.dart test/car_decal_test.dart && git commit -m "Add the line-drawn car decal"`

---

### Tarefa 7: Transferidor e acelerador

**Arquivos:**
- Criar: `lib/ui/cockpit/steering_gauge.dart`, `lib/ui/cockpit/throttle_scale.dart`
- Teste: `test/instruments_test.dart`

**Interfaces:**
- Produz:
  - `SteeringGauge({required int steer})`. Arco de −40° a +40°, marcas a cada 5° e maiores a cada 20°. O ponteiro âmbar fica em `steer * 18°`, animado com `AppMotion.needle` e uma curva com pequeno passar do ponto. As marcas a até 6° do ponteiro acendem quando `steer != 0`. A leitura usa `steerRight(18)`, `steerLeft(18)` ou `'0°'`.
  - `double throttleFill(CarCommand c)`: 1.0 com `turbo`, 0.72 com `forward`, −0.6 com `reverse` e 0 nos demais casos.
  - `ThrottleScale({required CarCommand command})`. A régua tem 17 marcas e rótulos `scaleForward`, `scaleReverse` e, só com turbo, `scaleTurbo` em âmbar.

- [ ] **Passo 1: Escrever os testes que falham:**
  - `throttleFill(const CarCommand(turbo: true)) == 1.0`; `forward: true` dá `0.72`; `reverse: true` dá `-0.6`; `CarCommand()` dá `0`.
  - `SteeringGauge(steer: 1)` em `pt` mostra "18° direita"; `steer: -1` mostra "18° esquerda"; `steer: 0` mostra "0°".
  - `ThrottleScale` com turbo mostra "turbo"; sem turbo, não mostra.
- [ ] **Passo 2: Rodar** os testes. Resultado esperado: falham.
- [ ] **Passo 3: Implementar** com `CustomPainter`. Texto de rótulo com `AppType.body(size: 10)` em `text3`.
- [ ] **Passo 4: Rodar** os testes. Resultado esperado: passam.
- [ ] **Passo 5: Commit:** `git add lib/ui/cockpit/steering_gauge.dart lib/ui/cockpit/throttle_scale.dart test/instruments_test.dart && git commit -m "Add the steering gauge and throttle scale"`

---

### Tarefa 8: Partículas

**Arquivos:**
- Modificar: `lib/ui/cockpit/particles.dart` (completar)
- Teste: `test/particles_test.dart`

**Interfaces:**
- Produz:
  - `Offset flowTarget(CarCommand c, {double tiltDegrees = 0})`. A velocidade é 520 com turbo, 240 com frente ou ré e 0 nos demais casos. O `y` vale `+velocidade` na frente e `−velocidade` na ré. O `x` vale `−steer × velocidade × 0.55`, com `steer` derivado de `left` e `right`. Depois disso, o vetor é rotacionado por `tiltDegrees`.
  - `double spinTarget(CarCommand c)`: 2.6 com `donut` e 0 sem.
  - `double zoneFactor(double y, {required double heroTop, required double heroBottom})`: 0.55 acima do instrumento; 1 dentro dele; abaixo, `max(0.18, 1 - (y - heroBottom) / 60)`.
  - `ParticleField({required CarCommand Function() command, required Offset Function() carCenter, required Rect Function() hero, Rect Function()? beam, int count = 95})`. Usa `CustomPainter` com `Ticker`. A velocidade de cada partícula se aproxima do alvo em 6% por quadro. Partículas dentro do facho, com a luz acesa, ficam em cor de farol com o brilho multiplicado por até 3,4.
  - Regras de execução:
    - Não cria `Ticker` se `EffectsScope.particlesOf(context)` for falso ou se "reduzir movimento" estiver ligado. Nos dois casos, desenha as partículas paradas uma vez.
    - Para o `Ticker` quando `TickerMode.of(context)` é falso e quando o ciclo de vida do app não é `resumed` (observador de `WidgetsBindingObserver`).

- [ ] **Passo 1: Escrever os testes que falham:**

```dart
test('flow follows the car', () {
  expect(flowTarget(const CarCommand(forward: true)), const Offset(0, 240));
  expect(flowTarget(const CarCommand(reverse: true)), const Offset(0, -240));
  expect(flowTarget(const CarCommand(turbo: true)).dy, 520);
  expect(flowTarget(const CarCommand(forward: true, right: true)).dx, lessThan(0));
  expect(flowTarget(const CarCommand()), Offset.zero);
  expect(spinTarget(const CarCommand(donut: true)), 2.6);
});
test('quiet behind the header and the controls', () {
  expect(zoneFactor(10, heroTop: 100, heroBottom: 400), 0.55);
  expect(zoneFactor(250, heroTop: 100, heroBottom: 400), 1);
  expect(zoneFactor(430, heroTop: 100, heroBottom: 400), closeTo(0.5, 1e-9));
  expect(zoneFactor(900, heroTop: 100, heroBottom: 400), 0.18);
});
```

  Testes de widget:
  - Com `EffectsScope(particles: false)`, depois de `pump()`, `tester.binding.hasScheduledFrame` é falso.
  - Com efeitos ligados e o app em `AppLifecycleState.paused` (`tester.binding.handleAppLifecycleStateChanged`), também não há quadro agendado. Isso cobre o ponto de atenção 3.
- [ ] **Passo 2: Rodar** os testes. Resultado esperado: falham.
- [ ] **Passo 3: Implementar.** Distribuir as partículas com um gerador aleatório de semente fixa, para o desenho inicial ser estável.
- [ ] **Passo 4: Rodar** `flutter test && flutter analyze lib test`. Resultado esperado: passa.
- [ ] **Passo 5: Commit:** `git add lib/ui/cockpit/particles.dart test/particles_test.dart && git commit -m "Add the car-reactive particle field"`

---

### Tarefa 9: Células, setas e legenda de teclas

**Arquivos:**
- Criar: `lib/ui/cockpit/state_cells.dart`, `lib/ui/cockpit/touch_pads.dart`, `lib/ui/cockpit/key_legend.dart`
- Teste: `test/cockpit_controls_test.dart`

**Interfaces:**
- Consome: `firstPadInput` e `keyInputs` (Tarefa 3); `Glass` (Tarefa 5); os métodos existentes do Driver `setVirtual`, `toggleLatched` e `isLatched`.
- Produz:
  - `StateCells({required bool tappable, int columns = 2})`. Mostra quatro `Glass`: Luz, Turbo, Giro 360° e Controle, cada um com o símbolo do atalho (Tarefa 3) e o valor (Tarefa 4).
  - Com `tappable`:
    - Tocar em Luz chama `setVirtual(light, true)` ao pressionar e `false` ao soltar, o que faz o Driver alternar a luz.
    - Tocar em Turbo ou em Giro chama `toggleLatched`.
    - A célula fica âmbar quando a ação está ativa.
  - `TouchPads()`: as quatro setas (←, →, ↓, ↑) que valem enquanto pressionadas, com `setVirtual`.
  - `KeyLegend()`: uma linha com as teclas de cada ação (W/↑ frente…). Cada grupo acende quando a ação está no comando atual. Some (`SizedBox.shrink`) com `keyboardEnabled` falso.

- [ ] **Passo 1: Escrever os testes que falham** (com `pumpWithDriver` e `FakeTransport`, carro conectado):
  - Tocar em "Turbo" deixa `driver.command.turbo` verdadeiro. Depois de 300 ms sem toque, continua verdadeiro. Um segundo toque desliga.
  - Tocar em "Luz" deixa `driver.command.light` verdadeiro, e outro toque desliga.
  - Segurar a seta ↑ (`startGesture`) deixa `forward` verdadeiro, e soltar desliga.
  - A `KeyLegend` mostra "W" e "Espaço". Com `driver.keyboardEnabled = false`, não mostra "W".
  - Com o turbo travado, `driver.didChangeAppLifecycleState(AppLifecycleState.paused)` destrava e a célula volta a "Desligado". Isso cobre o ponto de atenção 3.
- [ ] **Passo 2: Rodar** os testes. Resultado esperado: falham.
- [ ] **Passo 3: Implementar.** Células com altura mínima de 56. Setas com no mínimo 52×52, que crescem com a largura disponível como no `touch_controls.dart` atual (`((largura - 36) / 4).clamp(52, 84)`).
- [ ] **Passo 4: Rodar** os testes. Resultado esperado: passam.
- [ ] **Passo 5: Commit:** `git add lib/ui/cockpit/state_cells.dart lib/ui/cockpit/touch_pads.dart lib/ui/cockpit/key_legend.dart test/cockpit_controls_test.dart && git commit -m "Add state cells, arrow pads and the key legend"`

---

### Tarefa 10: Garagem

**Arquivos:**
- Criar: `lib/ui/garage/car_list.dart`, `lib/ui/garage/car_sheet.dart`, `lib/ui/garage/garage_column.dart`
- Teste: `test/garage_test.dart`

**Interfaces:**
- Consome: `signalStrength` (Tarefa 3), `CarDecal` na variante `icon` (Tarefa 6), `Glass`, `AmberSwitch` e `Notice` (Tarefa 5).
- Produz:
  - `CarList()`: linhas na ordem de `driver.cars`. Cada linha mostra nome, barras (`signalLevel`) e o texto de `signalStrength`.
    - O carro conectado mostra "Conectado · {bateria}%" e o botão `disconnect`.
    - Os demais mostram `actionConnect` quando não há carro conectado e `actionSwitch` quando há. Os dois chamam `driver.connect(id)`.
  - `Future<void> showCarSheet(BuildContext context)`: folha modal com `CarList` e, no rodapé, o `AmberSwitch` de `autoReconnect`. Fecha sozinha quando um `connect` termina com sucesso.
  - `GarageColumn()`: largura 280, com `carsNearby` e o indicador de busca, a `CarList`, a seção de controles (nome do controle e `recognized` ou `taught`) e o rodapé com `autoReconnect`.

- [ ] **Passo 1: Escrever os testes que falham:**
  - Com dois carros encontrados e nenhum conectado, aparecem "SF-25", "sinal forte" e dois botões "Conectar".
  - Depois de conectar o SF-25: a linha dele mostra "Desconectar", e a do 296 GT3 mostra "Trocar".
  - Tocar em "Desconectar" deixa `link` em `idle`.
  - Na folha, desligar o interruptor deixa `driver.autoConnect` falso.
  - Abrir a folha e tocar em "Conectar" no 296 GT3 conecta e fecha a folha: depois de `pumpAndSettle`, `find.byType(CarList)` não encontra nada.
- [ ] **Passo 2: Rodar** os testes. Resultado esperado: falham.
- [ ] **Passo 3: Implementar.**
- [ ] **Passo 4: Rodar** os testes. Resultado esperado: passam.
- [ ] **Passo 5: Commit:** `git add lib/ui/garage test/garage_test.dart && git commit -m "Add the garage list, car sheet and desktop column"`

---

### Tarefa 11: Painel conectado e layouts

**Arquivos:**
- Criar: `lib/ui/cockpit/cockpit_header.dart`, `lib/ui/cockpit/instrument.dart`, `lib/ui/cockpit/cockpit.dart`
- Teste: `test/cockpit_layout_test.dart`

**Interfaces:**
- Consome: as Tarefas 6 a 10, `AmbientBackdrop` (Tarefa 5) e `LayoutKind` e `layoutFor` (Tarefa 1).
- Produz:
  - `CockpitHeader({required VoidCallback onSettings, VoidCallback? onCarTap})`: nome com `MetalText`, situação, bateria e engrenagem. Com `onCarTap` nulo, o nome não é tocável.
  - O nome é o modelo do carro conectado ou em conexão; no estado de reconexão, o de `lostCar`; nos demais, `noCarShort`.
  - A situação segue a mesma prioridade da Tarefa 12: `btOffTitle` (ponto apagado) quando o Bluetooth não está pronto; `statusConnecting` (indicador girando); `connectedLabel` (ponto aceso); `statusReconnecting` (indicador girando); `statusSearching` (indicador girando).
  - A bateria só aparece conectado.
  - `Instrument()`: `ParticleField` ao fundo (`count` 150 em `desktop` e 95 nos demais), `SteeringGauge` acima do carro, `CarDecal` sólido e `ThrottleScale` à direita, num quadro de proporção 1:1 que se ajusta à altura disponível.
  - `Cockpit({required VoidCallback onSettings, VoidCallback? onCarTap})`: com o carro conectado, monta cabeçalho, instrumento, `StateCells` e `TouchPads` ou `KeyLegend`, conforme `layoutFor`:

| Layout | Composição |
|---|---|
| `phone` | Células 2×2 e setas, se `onScreenControls` estiver ligado |
| `tablet` | Células em uma linha de quatro e setas |
| `landscape` | Duas colunas: instrumento à esquerda, células e setas à direita |
| `desktop` | Células em uma linha de quatro e `KeyLegend`. Setas acima da legenda só com `onScreenControls` ligado |

  Fora do estado conectado, o `Cockpit` delega para a Tarefa 12. Até lá, mostra `SearchingView` provisório.

- [ ] **Passo 1: Escrever os testes que falham.** Para cada tamanho (320×568, 360×780, 390×844, 430×932, 600×960, 800×360 e 1180×760), cada idioma (`pt`, `en`, `es`) e "reduzir movimento" ligado e desligado, com o carro conectado:
  - `tester.takeException()` é nulo;
  - o botão ↑ fica inteiro na tela (`getRect(...).right <= largura`), exceto em `desktop` com setas desligadas;
  - em 1180×760 aparece "Espaço" (legenda) e não aparece o ícone de seta para cima.

  Teste extra (ponto de atenção 4): carro com o nome `SL-SUPER-LONG-NAME-296-GT3-EVO`, em 320×568, em `es`, sem exceção.
- [ ] **Passo 2: Rodar** os testes. Resultado esperado: falham.
- [ ] **Passo 3: Implementar.** No celular, se faltar altura, as células e as setas ficam fixas embaixo e o `Instrument` encolhe (`Expanded`). O texto não diminui.
- [ ] **Passo 4: Rodar** `flutter test && flutter analyze lib test`. Resultado esperado: passa.
- [ ] **Passo 5: Commit:** `git add lib/ui/cockpit test/cockpit_layout_test.dart && git commit -m "Compose the connected cockpit for phone, tablet, landscape and desktop"`

---

### Tarefa 12: Estados do painel

**Arquivos:**
- Modificar: `lib/ui/cockpit/cockpit_states.dart` (criar), `lib/ui/cockpit/cockpit.dart`
- Teste: `test/cockpit_states_test.dart`

**Interfaces:**
- Consome: `lostCar`, `reconnecting` e `failedCar` (Tarefa 2); `canEnableBluetooth`, `enableBluetooth` e `retryPermissions` (Tarefa 3); `Notice`; `CarList`; `CarDecal` nas variantes `ghost` e `drawing`.
- Produz: `SearchingView()`, `BluetoothView(BluetoothState state)`, `ConnectingView()` e `LostView()`.

O `Cockpit` escolhe o conteúdo nesta ordem de prioridade:

| Prioridade | Condição | Conteúdo |
|---|---|---|
| 1 | `bluetooth` é `off`, `unauthorized` ou `unsupported`, ou `message == permissionDenied` | `BluetoothView` |
| 2 | `link == connecting` | `ConnectingView` |
| 3 | `link == connected` | Painel conectado (Tarefa 11) |
| 4 | `reconnecting` | `LostView` |
| 5 | Demais casos | `SearchingView` |

O `SearchingView` mostra:
- as ondas e as dicas quando `cars` está vazio, ou `carsNearby` com a `CarList` quando há carros;
- `Notice` de falha quando `message == connectFailed` ("Tentar de novo" chama `connect(failedCar!.id)` e "Fechar" chama `dismissMessage()`);
- `Notice` com `msgDropped` quando `message == dropped`.

Textos e ações conforme a especificação 5.2.

- [ ] **Passo 1: Escrever os testes que falham** (em `pt`, com `FakeTransport`):
  - Sem carros: aparecem "Ligue o carro", "Não aparece?" e "Ainda nada?".
  - Com um carro: aparecem "Carros por perto" e "Conectar".
  - `avail.add(off)` com `canEnableBluetooth` verdadeiro: aparecem "Bluetooth desligado" e "Ligar o Bluetooth", e tocar no botão incrementa `enableCalls`. Com `canEnableBluetooth` falso, o botão não aparece.
  - `avail.add(unauthorized)`: aparecem "Bluetooth bloqueado" e "Tentar de novo", e tocar incrementa `permissionCalls`.
  - `avail.add(unsupported)`: aparece "Bluetooth LE indisponível", sem botão.
  - Conexão lenta (`connectDelay`): aparecem "Conectando ao SF-25" e "Cancelar", e tocar em "Cancelar" deixa `link` em `idle`.
  - Queda com reconexão ligada: aparece "Conexão perdida", e as células não aparecem.
  - Carro conectado e Bluetooth desligado: aparece "Bluetooth desligado", e não "Conexão perdida". Isso cobre o ponto de atenção 2.
  - Falha: aparece "Não foi possível conectar ao SF-25", e tocar em "Tentar de novo" volta a chamar `connect`.
- [ ] **Passo 2: Rodar** os testes. Resultado esperado: falham.
- [ ] **Passo 3: Implementar.** As ondas da busca: três anéis âmbar que crescem de 0,6 a 2,2 vezes e somem, em 2,4 s, defasados em 0,8 s. Com "reduzir movimento", um anel parado.
- [ ] **Passo 4: Rodar** os testes. Resultado esperado: passam.
- [ ] **Passo 5: Commit:** `git add lib/ui/cockpit test/cockpit_states_test.dart && git commit -m "Add the searching, Bluetooth, connecting and lost states"`

---

### Tarefa 13: Ajustes, botões e teclas, idioma e sobre

**Arquivos:**
- Criar: `lib/ui/settings/settings_page.dart`, `bindings_page.dart`, `language_page.dart`, `about_page.dart`
- Teste: `test/settings_test.dart`, `test/bindings_page_test.dart`

**Interfaces:**
- Consome: `SettingsGroup`, `SettingsRow`, `AmberSwitch`, `InputTag` e `Glass`; os métodos existentes do Driver `beginCapture`, `cancelCapture`, `removeBinding`, `resetBindings`, `actionsUsing`, `keyboardEnabled`, `deadzone`, `onScreenControls`, `autoConnect` e `localeCode`.
- Produz:
  - `SettingsPage({required void Function(Widget page) open})`. A navegação para as subtelas passa por `open`, para que o `Shell` decida se empilha uma rota (celular) ou troca dentro do painel lateral (computador).
  - Linhas conforme a especificação 5.4. A zona morta abre um `Slider` de 0.10 a 0.60, em passos de 0.05.
  - `BindingsPage()`: as sete ações em `CarAction.values`. O texto de abertura é `bindingsLeadClick` quando `layoutFor` dá `desktop` e `bindingsLeadTouch` nos demais casos. A ação em captura segue a especificação 5.5, e o rodapé fica fixo.
  - `LanguagePage()`: Sistema, Português, English e Español, com marcação da escolha atual.
  - `AboutPage()`: nome, `versionLabel` (com `PackageInfo`), `disclaimer`, licença MIT e um botão que abre `showLicensePage`.

- [ ] **Passo 1: Escrever os testes que falham:**
  - `SettingsPage` mostra "Comandos", "Pilotagem" e "App". Tocar em "Botões e teclas" chama `open` com um `BindingsPage`.
  - Arrastar o controle deslizante da zona morta para o fim deixa `driver.deadzone` em `0.60`.
  - Na `LanguagePage`, tocar em "English" deixa `driver.localeCode` em `'en'`.
  - Na `BindingsPage`, tocar em "+ Adicionar" de Turbo mostra "Aperte o que vai acionar Turbo" e "Cancelar". Tocar em "Cancelar" limpa `driver.capturing`.
  - Remover a etiqueta "W" de Frente tira essa entrada de `driver.bindings[forward]`.
  - Leva a regressão de `controls_page_test.dart`: `BindingsPage` sem exceção em 320, 360 e 390 de largura, nos três idiomas.
- [ ] **Passo 2: Rodar** os testes. Resultado esperado: falham.
- [ ] **Passo 3: Implementar.**
- [ ] **Passo 4: Rodar** os testes. Resultado esperado: passam.
- [ ] **Passo 5: Commit:** `git add lib/ui/settings test/settings_test.dart test/bindings_page_test.dart && git commit -m "Add settings, buttons and keys, language and about"`

---

### Tarefa 14: Controles e ensinar controle

**Arquivos:**
- Criar: `lib/ui/settings/controllers_page.dart`, `gamepad_drawing.dart`, `teach_page.dart`
- Teste: `test/teach_test.dart`

**Interfaces:**
- Consome: `rawSignals` e `rawRevision`, `controllers`, `profiles`, `beginTeaching`, `skipTeachStep`, `cancelTeaching`, `finishTeaching`, `forgetProfile` e `teaching` (com `index` e `finished`), todos do Driver; `teachSteps` de `controller_profile.dart`; `SignalMeter`.
- Produz:
  - `enum GamepadPart { faceBottom, faceRight, faceLeft, faceTop, leftBumper, rightBumper, leftTrigger, rightTrigger, back, start, leftStick, rightStick, dpadUp, dpadDown, dpadLeft, dpadRight }` e `GamepadPart gamepadPartFor(String stepId)`, que cobre os 18 ids de `teachSteps`. Os dois eixos de cada analógico apontam para o mesmo analógico.
  - `String teachGroupOf(AppLocalizations l, String stepId)`: devolve um dos cinco grupos da Tarefa 4.
  - `GamepadDrawing({required GamepadPart highlight})`: controle genérico em traço fino, com a parte destacada em âmbar pulsando (parada com "reduzir movimento").
  - `ControllersPage({required void Function(Widget page) open})`: segue a especificação 5.6. Os medidores vêm de `rawSignals.values`, ordenados pelo valor absoluto, no máximo seis, e são reconstruídos a cada mudança de `rawRevision`. Os valores negativos usam o valor absoluto.
  - `TeachPage()`: segue a especificação 5.7, com `teachStep(index + 1, teachSteps.length)`.
  - As etiquetas dos passos já feitos usam o nome curto de cada passo: para botões, `l.pad(PadInput.values.byName(id))`; para eixos, `l.padLeftStick` ou `l.padRightStick`. Mostrar só os do grupo atual.

- [ ] **Passo 1: Escrever os testes que falham:**

```dart
test('every teach step has a part and a group', () {
  expect(teachSteps.length, 18);
  for (final s in teachSteps) {
    expect(() => gamepadPartFor(s.id), returnsNormally);
  }
  expect(gamepadPartFor('a'), GamepadPart.faceBottom);
  expect(gamepadPartFor('axis:leftStickY'), GamepadPart.leftStick);
});
```

  Testes de widget:
  - Com um controle conectado, tocar em "Ensinar um controle novo" abre a `TeachPage` com "Passo 1 de 18" e "Botões de ação". "Pular" leva a "Passo 2 de 18".
  - Pulando todos os passos, aparece "Pronto". Tocar em "Pronto" chama `finishTeaching` e grava um perfil em `driver.profiles`.
  - Ponto de atenção 5: com o assistente aberto, `connEvents.add(...disconnected)` não gera exceção, a tela mostra `noControllerShort` e "Cancelar" fecha a tela e deixa `driver.teaching` nulo.
- [ ] **Passo 2: Rodar** os testes. Resultado esperado: falham.
- [ ] **Passo 3: Implementar.**
- [ ] **Passo 4: Rodar** os testes. Resultado esperado: passam.
- [ ] **Passo 5: Commit:** `git add lib/ui/settings test/teach_test.dart && git commit -m "Add controllers with live meters and the teach wizard"`

---

### Tarefa 15: Shell, navegação e remoção das telas antigas

**Arquivos:**
- Criar: `lib/ui/shell.dart`
- Modificar: `lib/app.dart` (tema escuro único e `home: Shell()`), `tool/gen_arb.py` (remover as chaves sem uso)
- Remover: os arquivos antigos listados na estrutura e seus testes substituídos
- Teste: `test/shell_test.dart`

**Interfaces:**
- Consome: `Cockpit`, `GarageColumn`, `showCarSheet`, `SettingsPage` e `layoutFor`.
- Produz:
  - `Shell()`. Em `desktop`, monta uma `Row` com a `GarageColumn` e o `Cockpit`, sem `onCarTap`. Nos outros layouts, monta só o `Cockpit`, com `onCarTap: () => showCarSheet(context)`.
  - `void openSettings(BuildContext context)`:
    - Em `desktop`, mostra um painel lateral de 380 à direita, com fundo escurecido a 35% que fecha ao clicar, e as subtelas trocam dentro dele (`Navigator` próprio).
    - Nos outros layouts, empilha a `SettingsPage` como rota, e as subtelas são novas rotas.
  - O `MaterialApp` passa a usar só `theme: buildAppTheme()`, sem `darkTheme`.

- [ ] **Passo 1: Escrever os testes que falham:**
  - Em 1180×760: aparecem "Carros por perto" (coluna) e "Espaço". Tocar na engrenagem mostra "Ajustes" e mantém "SF-25" visível. Clicar no fundo escurecido fecha os Ajustes.
  - Em 390×844: tocar no nome do carro abre a folha. Tocar na engrenagem empilha "Ajustes", e voltar retorna ao painel.
  - `BleRcApp` monta sem exceção e o `Theme.of(context).brightness` é escuro.
- [ ] **Passo 2: Rodar** os testes. Resultado esperado: falham.
- [ ] **Passo 3: Implementar `shell.dart` e ligar no `app.dart`.**
- [ ] **Passo 4: Remover as telas e os testes antigos.** Apagar as chaves de `tool/gen_arb.py` que ficaram sem referência: conferir com `grep -rn "l\.<chave>\b" lib` antes de cada remoção. Regenerar o l10n.
- [ ] **Passo 5: Atualizar a única referência ao app em `marketing/render_ui_test.dart`** (arquivo local, fora do git) para usar `Shell`, para ele continuar compilando. O visual das peças é do próximo plano.
- [ ] **Passo 6: Rodar** `flutter test && flutter analyze lib test`. Resultado esperado: tudo passa, sem avisos.
- [ ] **Passo 7: Commit:** `git add -A lib test tool && git commit -m "Switch to the new shell and remove the old screens"`

---

### Tarefa 16: Verificação no aparelho

**Arquivos:** nenhum, a menos que apareçam defeitos. Cada defeito vira teste e correção, com commit próprio.

- [ ] **Passo 1: Compilar** com `flutter build apk --release` e instalar no tablet com `adb install -r build/app/outputs/flutter-apk/app-release.apk`.
- [ ] **Passo 2: No tablet, conferir o roteiro**, capturando a tela de cada etapa:
  1. Abrir sem carro: "Procurando".
  2. Ligar o SF-25: aparece na lista. Conectar: o decalque se desenha e o painel ganha vida.
  3. Frente, ré, curvas, luz, turbo e giro, pelo toque e pelo DualShock: o carro reage, o ponteiro, a régua e as partículas acompanham.
  4. Desligar o carro: "Conexão perdida". Religar: reconecta sozinho.
  5. Desligar o Bluetooth do tablet: "Bluetooth desligado" com "Ligar o Bluetooth".
  6. Trocar para o 296 GT3 pela folha.
  7. Ajustes: botões e teclas (capturar uma entrada), controles (medidores), ensinar controle (três passos e cancelar), idioma, sobre.
  8. Ligar "remover animações" do Android: nada quebra.
  9. Fluidez: pilotar 30 s com turbo e faróis, observando a tela. Se as partículas ou o vidro engasgarem, reduzir a quantidade de partículas e, se ainda pesar, trocar o desfoque por vidro opaco equivalente (especificação 12).
- [ ] **Passo 3: Ler o `adb logcat`** atrás de exceções do Flutter durante o roteiro.
- [ ] **Passo 4: Rodar o app de macOS** com `flutter run -d macos --release`, conferir a coluna de carros, a legenda de teclas e os Ajustes no painel lateral, e pilotar com o teclado.
- [ ] **Passo 5: Relatar ao Daniel** o que passou e o que não passou, com as capturas. Não subir versão nem enviar ao GitHub sem o OK dele.
