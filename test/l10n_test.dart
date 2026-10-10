import 'package:ble_rc_controller/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppLocalizations> _load(String code) =>
    AppLocalizations.delegate.load(Locale(code));

void main() {
  for (final code in ['en', 'es', 'pt']) {
    test('$code has the strings the redesigned screens use', () async {
      final l = await _load(code);
      expect(l.searchTitle, isNotEmpty);
      expect(l.connectingTitle('SF-25'), contains('SF-25'));
      expect(l.connectFailedTitle('SF-25'), contains('SF-25'));
      expect(l.teachHint_a, isNotEmpty);
      expect(l.teachStep(1, 18), contains('18'));
      expect(l.steerRight(18), contains('18'));
      expect(l.steerLeft(18), contains('18'));
      expect(l.aboutHint('1.2.3'), contains('1.2.3'));
      expect(l.captureWaiting('Luz'), contains('Luz'));
    });

    test('$code teaches each step in short words, without brackets or shouting',
        () async {
      final l = await _load(code);
      final steps = [
        l.teach_a, l.teach_b, l.teach_x, l.teach_y,
        l.teach_leftBumper, l.teach_rightBumper,
        l.teach_leftTrigger, l.teach_rightTrigger,
        l.teach_back, l.teach_start,
        l.teach_leftStickX, l.teach_leftStickY,
        l.teach_rightStickX, l.teach_rightStickY,
        l.teach_dpadUp, l.teach_dpadDown, l.teach_dpadLeft, l.teach_dpadRight,
      ];
      expect(steps, hasLength(18));
      for (final s in steps) {
        expect(s, isNotEmpty);
        expect(s, isNot(contains('(')), reason: s);
        expect(s, isNot(matches(RegExp(r'\b[A-ZÀ-Ú]{2,}\b'))), reason: s);
        expect(s, isNot(contains('!')), reason: s);
      }
    });
  }

  test('pt connects and counts steps in Portuguese', () async {
    final l = await _load('pt');
    expect(l.connectingTitle('SF-25'), 'Conectando ao SF-25');
    expect(l.teachStep(4, 18), 'Passo 4 de 18');
  });

  test('pt keeps the old screens\' texts in line with the spec', () async {
    final l = await _load('pt');
    expect(l.btOffBody, 'Ligue o Bluetooth para encontrar o carro.');
    expect(l.onScreen, 'Botões na tela');
    expect(l.hintHold, 'enquanto pressionado');
    expect(l.hintToggle, 'cada toque liga e desliga');
    expect(l.languageSystem, 'Sistema');
  });

  test('en and es name the on-screen buttons and the system language as the spec does',
      () async {
    final en = await _load('en');
    expect(en.onScreen, 'On-screen buttons');
    expect(en.languageSystem, 'System');
    final es = await _load('es');
    expect(es.onScreen, 'Botones en pantalla');
    expect(es.languageSystem, 'Sistema');
  });

  test('pt teach_leftStickX has no capitals after the first letter', () async {
    final l = await _load('pt');
    expect(l.teach_leftStickX, matches(RegExp(r'^.[^A-ZÀ-Ú]*$')));
  });

  test('the controller hints name the same button on PlayStation, Xbox and Switch',
      () async {
    // Bottom is ✕ / A / B, right is ○ / B / A, left is □ / X / Y, top is △ / Y / X.
    RegExp hint(String ps, String xbox, String sw) =>
        RegExp('^$ps \\S+ PlayStation, $xbox \\S+ Xbox, $sw \\S+ Switch\$');
    for (final code in ['en', 'es', 'pt']) {
      final l = await _load(code);
      expect(l.teachHint_a, matches(hint('✕', 'A', 'B')), reason: code);
      expect(l.teachHint_b, matches(hint('○', 'B', 'A')), reason: code);
      expect(l.teachHint_x, matches(hint('□', 'X', 'Y')), reason: code);
      expect(l.teachHint_y, matches(hint('△', 'Y', 'X')), reason: code);
      expect(l.teachHint_leftBumper, matches(hint('L1', 'LB', 'L')), reason: code);
      expect(l.teachHint_rightBumper, matches(hint('R1', 'RB', 'R')), reason: code);
      expect(l.teachHint_leftTrigger, matches(hint('L2', 'LT', 'ZL')), reason: code);
      expect(l.teachHint_rightTrigger, matches(hint('R2', 'RT', 'ZR')), reason: code);
    }
  });
}
