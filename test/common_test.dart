import 'dart:ui' as ui;

import 'package:ble_rc_controller/core/driver.dart';
import 'package:ble_rc_controller/input/input_ref.dart';
import 'package:ble_rc_controller/ui/cockpit/particles.dart';
import 'package:ble_rc_controller/ui/common/ambient.dart';
import 'package:ble_rc_controller/ui/common/amber_switch.dart';
import 'package:ble_rc_controller/ui/common/glass.dart';
import 'package:ble_rc_controller/ui/common/input_tag.dart';
import 'package:ble_rc_controller/ui/common/metal_text.dart';
import 'package:ble_rc_controller/ui/common/notice.dart';
import 'package:ble_rc_controller/ui/common/settings_row.dart';
import 'package:ble_rc_controller/ui/common/signal_meter.dart';
import 'package:ble_rc_controller/ui/strings.dart';
import 'package:ble_rc_controller/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_transport.dart';
import 'support/harness.dart';

Future<Driver> _driver() async {
  SharedPreferences.setMockInitialValues({});
  final driver = Driver(
    transport: FakeTransport(),
    prefs: await SharedPreferences.getInstance(),
    rawEvents: const Stream.empty(),
    connectionEvents: const Stream.empty(),
    listGamepads: () async => [],
    enableKeyboard: false,
  );
  addTearDown(driver.dispose);
  return driver;
}

/// The decoration of the glass surface itself (the one that has the outline).
BoxDecoration _surface(WidgetTester t) => t
    .widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(Glass),
        matching: find.byType(DecoratedBox),
      ),
    )
    .map((b) => b.decoration)
    .whereType<BoxDecoration>()
    .firstWhere((d) => d.border != null);

/// The RGBA of the pixel ([x], [y]) that the repaint boundary [key] draws.
/// The harness runs at a pixel ratio of 1, so a logical pixel is one pixel.
Future<List<int>> _pixel(WidgetTester t, GlobalKey key, int x, int y) async {
  final px = await t.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = (await image.toByteData())!; // raw RGBA
    final at = (y * image.width + x) * 4;
    image.dispose();
    return [for (var i = 0; i < 4; i++) bytes.getUint8(at + i)];
  });
  return px!;
}

/// The colour the text [s] is actually painted with.
Color? _textColor(WidgetTester t, String s) =>
    (t.renderObject<RenderParagraph>(find.text(s)).text as TextSpan)
        .style
        ?.color;

void main() {
  group('harness', () {
    testWidgets('sets the size, the locale, the driver and reduce motion', (
      tester,
    ) async {
      final driver = await _driver();
      late BuildContext ctx;
      await pumpWithDriver(
        tester,
        driver,
        Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
        size: const Size(800, 360),
        locale: 'es',
        reduceMotion: true,
      );
      expect(MediaQuery.sizeOf(ctx), const Size(800, 360));
      expect(Localizations.localeOf(ctx), const Locale('es'));
      expect(MediaQuery.disableAnimationsOf(ctx), isTrue);
      expect(DriverScope.of(ctx), same(driver));
      expect(EffectsScope.particlesOf(ctx), isFalse);
      expect(Theme.of(ctx).brightness, Brightness.dark);
    });

    testWidgets('defaults to a phone, in Portuguese, with motion on', (
      tester,
    ) async {
      final driver = await _driver();
      late BuildContext ctx;
      await pumpWithDriver(
        tester,
        driver,
        Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      );
      expect(MediaQuery.sizeOf(ctx), const Size(390, 844));
      expect(Localizations.localeOf(ctx), const Locale('pt'));
      expect(MediaQuery.disableAnimationsOf(ctx), isFalse);
    });

    testWidgets('EffectsScope defaults to particles on when it is absent', (
      tester,
    ) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      );
      expect(EffectsScope.particlesOf(ctx), isTrue);
    });
  });

  group('Glass', () {
    testWidgets('blurs what is behind it by 14', (tester) async {
      await pumpWithDriver(
        tester,
        await _driver(),
        const Glass(child: Text('x')),
      );
      final blur = tester.widget<BackdropFilter>(
        find.descendant(
          of: find.byType(Glass),
          matching: find.byType(BackdropFilter),
        ),
      );
      expect(blur.filter, ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14));
    });

    testWidgets('idle: glass fill and glass edge, no amber', (tester) async {
      await pumpWithDriver(
        tester,
        await _driver(),
        const Glass(child: Text('x')),
      );
      final d = _surface(tester);
      expect(d.color, AppColors.glass);
      expect(d.gradient, isNull);
      expect((d.border! as Border).top.color, AppColors.glassEdge);
      expect(_textColor(tester, 'x'), isNot(AppColors.amber));
    });

    testWidgets('active: amber edge at 35%, amber fill from 10% to 3%, amber '
        'text with a soft halo', (tester) async {
      await pumpWithDriver(
        tester,
        await _driver(),
        const Glass(active: true, child: Text('x')),
      );
      final d = _surface(tester);
      final edge = (d.border! as Border).top.color;
      expect(edge.a, closeTo(0.35, 0.005));
      expect(edge.toARGB32() & 0xFFFFFF, AppColors.amber.toARGB32() & 0xFFFFFF);
      // The gradient is the whole fill: a colour here would be painted with it
      // and dim it to a few tenths of a percent.
      expect(d.color, isNull);
      final fill = (d.gradient! as LinearGradient).colors;
      expect(fill.first.a, closeTo(0.10, 0.005));
      expect(fill.last.a, closeTo(0.03, 0.005));
      expect(_textColor(tester, 'x'), AppColors.amber);
      final shadows =
          (tester.renderObject<RenderParagraph>(find.text('x')).text
                  as TextSpan)
              .style
              ?.shadows;
      expect(shadows, isNotEmpty);
    });

    testWidgets('active: what is drawn is the amber fill, 10% at the top down '
        'to 3% at the bottom', (tester) async {
      final key = GlobalKey();
      await pumpWithDriver(
        tester,
        await _driver(),
        RepaintBoundary(
          key: key,
          child: const ColoredBox(
            color: Colors.black,
            child: SizedBox(
              width: 100,
              height: 100,
              child: Glass(
                active: true,
                padding: EdgeInsets.zero,
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),
      );
      // Amber (255, 181, 71) over black: 10% is about 25 of red, 3% about 8.
      final top = await _pixel(tester, key, 50, 10);
      expect(top[0], inInclusiveRange(20, 28), reason: 'red near the top');
      expect(top[0], greaterThan(top[1]), reason: 'amber, not white');
      expect(top[1], greaterThan(top[2]), reason: 'amber, not white');
      final bottom = await _pixel(tester, key, 50, 92);
      expect(bottom[0], inInclusiveRange(5, 13), reason: 'red near the bottom');
      expect(top[0], greaterThan(bottom[0]));
    });

    testWidgets('idle: what is drawn is white at 4%', (tester) async {
      final key = GlobalKey();
      await pumpWithDriver(
        tester,
        await _driver(),
        RepaintBoundary(
          key: key,
          child: const ColoredBox(
            color: Colors.black,
            child: SizedBox(
              width: 100,
              height: 100,
              child: Glass(padding: EdgeInsets.zero, child: SizedBox.expand()),
            ),
          ),
        ),
      );
      final px = await _pixel(tester, key, 50, 50);
      for (final c in px.take(3)) {
        expect(c, inInclusiveRange(8, 12)); // 4% of 255 is about 10
      }
    });

    testWidgets('the radius and padding are the ones given', (tester) async {
      await pumpWithDriver(
        tester,
        await _driver(),
        const Glass(
          radius: 22,
          padding: EdgeInsets.all(20),
          child: SizedBox(width: 100, height: 50),
        ),
      );
      expect(
        _surface(tester).borderRadius,
        const BorderRadius.all(Radius.circular(22)),
      );
      expect(tester.getSize(find.byType(Glass)), const Size(140, 90));
    });

    testWidgets('onTap fires, and the target stays at least 48 by 48', (
      tester,
    ) async {
      var taps = 0;
      await pumpWithDriver(
        tester,
        await _driver(),
        Glass(
          padding: EdgeInsets.zero,
          onTap: () => taps++,
          child: const SizedBox(width: 10, height: 10),
        ),
      );
      final size = tester.getSize(find.byType(Glass));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      await tester.tap(find.byType(Glass));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('without onTap it is not a button', (tester) async {
      await pumpWithDriver(
        tester,
        await _driver(),
        const Glass(child: Text('x')),
      );
      expect(
        find.descendant(of: find.byType(Glass), matching: find.byType(InkWell)),
        findsNothing,
      );
    });
  });

  group('MetalText', () {
    testWidgets('a long text in a 120 wide box ends in an ellipsis and does '
        'not overflow', (tester) async {
      const long = 'Um nome de carro muito comprido que não cabe na caixa';
      await pumpWithDriver(
        tester,
        await _driver(),
        SizedBox(
          width: 120,
          child: MetalText(long, style: AppType.numeric(size: 42)),
        ),
      );
      expect(tester.takeException(), isNull);
      final p = tester.renderObject<RenderParagraph>(find.text(long));
      expect(p.didExceedMaxLines, isTrue);
      expect(
        tester.getSize(find.byType(MetalText)).width,
        lessThanOrEqualTo(120),
      );
      final text = tester.widget<Text>(find.text(long));
      expect(text.overflow, TextOverflow.ellipsis);
      expect(text.maxLines, 1);
    });

    testWidgets('paints the glyphs through a gradient, keeping the style', (
      tester,
    ) async {
      await pumpWithDriver(
        tester,
        await _driver(),
        MetalText('Rex', style: AppType.numeric(size: 42), maxLines: 2),
      );
      final mask = tester.widget<ShaderMask>(find.byType(ShaderMask));
      expect(mask.blendMode, BlendMode.srcIn);
      final text = tester.widget<Text>(find.text('Rex'));
      expect(text.style!.fontSize, 42);
      expect(text.style!.fontFamily, 'Saira');
      expect(text.maxLines, 2);
    });
  });

  group('Notice', () {
    testWidgets('shows title and body; the primary action fires once', (
      tester,
    ) async {
      var primary = 0;
      var secondary = 0;
      await pumpWithDriver(
        tester,
        await _driver(),
        Notice(
          title: 'Não conectou',
          body: 'O carro não respondeu.',
          primaryLabel: 'Tentar de novo',
          onPrimary: () => primary++,
          secondaryLabel: 'Fechar',
          onSecondary: () => secondary++,
        ),
      );
      expect(find.text('Não conectou'), findsOneWidget);
      expect(find.text('O carro não respondeu.'), findsOneWidget);

      await tester.tap(find.text('Tentar de novo'));
      await tester.pump();
      expect(primary, 1);
      expect(secondary, 0);

      await tester.tap(find.text('Fechar'));
      await tester.pump();
      expect(primary, 1);
      expect(secondary, 1);
    });

    testWidgets('an action is at least 48 high', (tester) async {
      await pumpWithDriver(
        tester,
        await _driver(),
        Notice(
          title: 't',
          body: 'b',
          primaryLabel: 'Tentar de novo',
          onPrimary: () {},
        ),
      );
      final size = tester.getSize(
        find.widgetWithText(TextButton, 'Tentar de novo'),
      );
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    });

    testWidgets('without labels there are no actions', (tester) async {
      await pumpWithDriver(
        tester,
        await _driver(),
        const Notice(title: 'Aviso', body: 'Só texto.'),
      );
      expect(find.byType(TextButton), findsNothing);
      expect(find.text('Aviso'), findsOneWidget);
    });

    testWidgets('it is the active (amber) glass', (tester) async {
      await pumpWithDriver(
        tester,
        await _driver(),
        const Notice(title: 'Aviso', body: 'Só texto.'),
      );
      expect(tester.widget<Glass>(find.byType(Glass)).active, isTrue);
    });
  });

  group('InputTag', () {
    testWidgets('onRemove shows the × with the "remove" tooltip; tapping it '
        'removes', (tester) async {
      var removed = 0;
      await pumpWithDriver(
        tester,
        await _driver(),
        InputTag(
          label: 'Gatilho direito',
          kind: InputKind.pad,
          onRemove: () => removed++,
        ),
      );
      expect(find.text('Gatilho direito'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byTooltip('Remover'), findsOneWidget);

      await tester.tap(find.byTooltip('Remover'));
      await tester.pump();
      expect(removed, 1);
    });

    testWidgets('the tooltip follows the language', (tester) async {
      await pumpWithDriver(
        tester,
        await _driver(),
        InputTag(label: 'A', kind: InputKind.pad, onRemove: () {}),
        locale: 'en',
      );
      expect(find.byTooltip('Remove'), findsOneWidget);
    });

    testWidgets('the remove button is at least 48 by 48', (tester) async {
      await pumpWithDriver(
        tester,
        await _driver(),
        InputTag(label: 'A', kind: InputKind.pad, onRemove: () {}),
      );
      final size = tester.getSize(find.byTooltip('Remover'));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('without onRemove there is no × and no tooltip', (
      tester,
    ) async {
      await pumpWithDriver(
        tester,
        await _driver(),
        const InputTag(label: 'A', kind: InputKind.pad),
      );
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byTooltip('Remover'), findsNothing);
    });

    testWidgets('a controller icon for pad and raw, a keyboard icon for key', (
      tester,
    ) async {
      final driver = await _driver();
      for (final (kind, icon, other) in [
        (InputKind.pad, Icons.sports_esports_outlined, Icons.keyboard_outlined),
        (InputKind.raw, Icons.sports_esports_outlined, Icons.keyboard_outlined),
        (InputKind.key, Icons.keyboard_outlined, Icons.sports_esports_outlined),
      ]) {
        await pumpWithDriver(tester, driver, InputTag(label: 'A', kind: kind));
        expect(find.byIcon(icon), findsOneWidget, reason: '$kind');
        expect(find.byIcon(other), findsNothing, reason: '$kind');
      }
    });

    testWidgets('the shared warning shows only when shared, with its hint', (
      tester,
    ) async {
      final driver = await _driver();
      const hint = 'Esta entrada também está atribuída a outra ação.';
      await pumpWithDriver(
        tester,
        driver,
        const InputTag(label: 'A', kind: InputKind.pad),
      );
      expect(find.byTooltip(hint), findsNothing);

      await pumpWithDriver(
        tester,
        driver,
        const InputTag(label: 'A', kind: InputKind.pad, shared: true),
      );
      expect(find.byTooltip(hint), findsOneWidget);
    });

    testWidgets('a long label does not overflow a narrow slot', (tester) async {
      await pumpWithDriver(
        tester,
        await _driver(),
        SizedBox(
          width: 140,
          child: InputTag(
            label: 'Botão de ombro esquerdo número dois',
            kind: InputKind.pad,
            shared: true,
            onRemove: () {},
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('SignalMeter', () {
    Future<void> meter(
      WidgetTester t,
      double v, {
      String locale = 'pt',
    }) async => pumpWithDriver(
      t,
      await _driver(),
      SignalMeter(label: 'R2', value: v),
      locale: locale,
    );

    testWidgets('shows two decimals in the language of the app', (
      tester,
    ) async {
      await meter(tester, 0.72);
      expect(find.text('R2'), findsOneWidget);
      expect(find.text('0,72'), findsOneWidget);

      await meter(tester, 0.72, locale: 'en');
      expect(find.text('0.72'), findsOneWidget);
    });

    testWidgets('clamps the value to 0..1', (tester) async {
      await meter(tester, 1.7);
      expect(find.text('1,00'), findsOneWidget);
      await meter(tester, -0.4);
      expect(find.text('0,00'), findsOneWidget);
      await meter(tester, double.nan);
      expect(find.text('0,00'), findsOneWidget);
    });

    testWidgets('the bar is as full as the value', (tester) async {
      await meter(tester, 0.72);
      double fill() => tester
          .widget<FractionallySizedBox>(
            find.descendant(
              of: find.byType(SignalMeter),
              matching: find.byType(FractionallySizedBox),
            ),
          )
          .widthFactor!;
      expect(fill(), closeTo(0.72, 1e-9));
      await meter(tester, 3);
      expect(fill(), 1);
      await meter(tester, -1);
      expect(fill(), 0);
    });

    testWidgets('screen readers get one label and one value', (tester) async {
      final handle = tester.ensureSemantics();
      await meter(tester, 0.5);
      expect(
        tester.getSemantics(find.byType(SignalMeter)),
        isSemantics(label: 'R2', value: '0,50'),
      );
      handle.dispose();
    });
  });

  group('AmberSwitch', () {
    Widget stateful(ValueChanged<bool> seen, {bool initial = false}) {
      var v = initial;
      return StatefulBuilder(
        builder: (context, set) => AmberSwitch(
          value: v,
          onChanged: (x) {
            seen(x);
            set(() => v = x);
          },
        ),
      );
    }

    testWidgets('toggles and reports the new value', (tester) async {
      final seen = <bool>[];
      await pumpWithDriver(tester, await _driver(), stateful(seen.add));
      await tester.tap(find.byType(AmberSwitch));
      await tester.pump(const Duration(milliseconds: 300));
      expect(seen, [true]);
      await tester.tap(find.byType(AmberSwitch));
      await tester.pump(const Duration(milliseconds: 300));
      expect(seen, [true, false]);
    });

    testWidgets('the target is at least 48 by 48', (tester) async {
      await pumpWithDriver(
        tester,
        await _driver(),
        AmberSwitch(value: false, onChanged: (_) {}),
      );
      final size = tester.getSize(find.byType(AmberSwitch));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('a tap on the far corner of the target still toggles', (
      tester,
    ) async {
      final seen = <bool>[];
      await pumpWithDriver(tester, await _driver(), stateful(seen.add));
      final box = tester.getRect(find.byType(AmberSwitch));
      await tester.tapAt(box.topLeft + const Offset(2, 2));
      await tester.pump(const Duration(milliseconds: 300));
      expect(seen, [true]);
    });

    testWidgets('amber when on, grey when off', (tester) async {
      final driver = await _driver();
      Color track() {
        final box = tester
            .widgetList<AnimatedContainer>(
              find.descendant(
                of: find.byType(AmberSwitch),
                matching: find.byType(AnimatedContainer),
              ),
            )
            .first;
        return (box.decoration! as BoxDecoration).color!;
      }

      await pumpWithDriver(
        tester,
        driver,
        AmberSwitch(value: true, onChanged: (_) {}),
      );
      expect(track(), AppColors.amber);
      await pumpWithDriver(
        tester,
        driver,
        AmberSwitch(value: false, onChanged: (_) {}),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(track(), isNot(AppColors.amber));
    });

    testWidgets('exposes an on/off state to screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpWithDriver(
        tester,
        await _driver(),
        AmberSwitch(value: true, onChanged: (_) {}),
      );
      expect(
        tester.getSemantics(find.byType(AmberSwitch)),
        isSemantics(hasToggledState: true, isToggled: true, hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets('with reduce motion the change is instant', (tester) async {
      final driver = await _driver();
      await pumpWithDriver(
        tester,
        driver,
        AmberSwitch(value: false, onChanged: (_) {}),
        reduceMotion: true,
      );
      await pumpWithDriver(
        tester,
        driver,
        AmberSwitch(value: true, onChanged: (_) {}),
        reduceMotion: true,
      );
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('SettingsGroup and SettingsRow', () {
    testWidgets('the group shows its title and every row', (tester) async {
      await pumpWithDriver(
        tester,
        await _driver(),
        const SettingsGroup(
          title: 'Entrada',
          rows: [
            SettingsRow(title: 'Teclado'),
            SettingsRow(title: 'Zona morta', subtitle: 'Ignora o tremor'),
          ],
        ),
      );
      expect(find.text('Entrada'), findsOneWidget);
      expect(find.text('Teclado'), findsOneWidget);
      expect(find.text('Zona morta'), findsOneWidget);
      expect(find.text('Ignora o tremor'), findsOneWidget);
    });

    testWidgets('a row with onTap reacts to the tap, and is at least 48 high '
        'even with only a title', (tester) async {
      var taps = 0;
      await pumpWithDriver(
        tester,
        await _driver(),
        SettingsGroup(
          title: 'Geral',
          rows: [SettingsRow(title: 'Sobre', onTap: () => taps++)],
        ),
      );
      expect(
        tester.getSize(find.byType(SettingsRow)).height,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(find.text('Sobre'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('the trailing widget sits on the right of the title', (
      tester,
    ) async {
      await pumpWithDriver(
        tester,
        await _driver(),
        const SettingsGroup(
          title: 'Geral',
          rows: [SettingsRow(title: 'Zona morta', trailing: Text('12%'))],
        ),
      );
      expect(
        tester.getTopLeft(find.text('12%')).dx,
        greaterThan(tester.getTopRight(find.text('Zona morta')).dx),
      );
    });

    testWidgets('tapping the switch in a row toggles it', (tester) async {
      final seen = <bool>[];
      await pumpWithDriver(
        tester,
        await _driver(),
        SettingsGroup(
          title: 'Geral',
          rows: [
            SettingsRow(
              title: 'Teclado',
              trailing: AmberSwitch(value: false, onChanged: seen.add),
            ),
          ],
        ),
      );
      await tester.tap(find.byType(AmberSwitch));
      await tester.pump();
      expect(seen, [true]);
    });

    testWidgets('a switch row is one control for screen readers: named by its '
        'title, with the on/off state and the tap', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpWithDriver(
        tester,
        await _driver(),
        SettingsGroup(
          title: 'Geral',
          rows: [
            SettingsRow(
              title: 'Teclado',
              subtitle: 'Dirige com as setas',
              trailing: AmberSwitch(value: true, onChanged: (_) {}),
            ),
          ],
        ),
      );
      expect(
        tester.getSemantics(find.byType(SettingsRow)),
        isSemantics(
          label: 'Teclado\nDirige com as setas',
          hasToggledState: true,
          isToggled: true,
          hasTapAction: true,
        ),
      );
      // One tappable node, and it is the named one: no unnamed switch left over.
      final tappable = find.semantics.byAction(SemanticsAction.tap).evaluate();
      expect(tappable, hasLength(1));
      expect(tappable.single.label, 'Teclado\nDirige com as setas');
      handle.dispose();
    });

    testWidgets('a value row reads its value with its title', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpWithDriver(
        tester,
        await _driver(),
        SettingsGroup(
          title: 'Geral',
          rows: [
            SettingsRow(
              title: 'Zona morta',
              trailing: const Text('12%'),
              onTap: () {},
            ),
          ],
        ),
      );
      expect(
        tester.getSemantics(find.byType(SettingsRow)),
        isSemantics(
          label: 'Zona morta\n12%',
          isButton: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a long title and subtitle wrap without overflow in a narrow '
        'phone', (tester) async {
      await pumpWithDriver(
        tester,
        await _driver(),
        SettingsGroup(
          title: 'Geral',
          rows: [
            SettingsRow(
              title: 'Um título bem comprido para uma linha de ajuste estreita',
              subtitle: 'Uma descrição também comprida, que explica o que a opção faz',
              trailing: AmberSwitch(value: true, onChanged: (_) {}),
            ),
          ],
        ),
        size: const Size(320, 568),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('AmbientBackdrop', () {
    testWidgets('with EffectsScope(particles: false) the sweep leaves no '
        'frame scheduled', (tester) async {
      await pumpWithDriver(
        tester,
        await _driver(),
        const AmbientBackdrop(sweep: true),
      );
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pump(const Duration(seconds: 30));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('with reduce motion on, the sweep stays still even if the '
        'particles are on', (tester) async {
      await pumpWithDriver(
        tester,
        await _driver(),
        const EffectsScope(
          particles: true,
          child: AmbientBackdrop(sweep: true),
        ),
        reduceMotion: true,
      );
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pump(const Duration(seconds: 30));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('without sweep nothing animates even if the particles are on', (
      tester,
    ) async {
      await pumpWithDriver(
        tester,
        await _driver(),
        const EffectsScope(particles: true, child: AmbientBackdrop()),
      );
      await tester.pump(const Duration(seconds: 30));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('with the effects on, the sweep does cross the screen and '
        'rests between crossings', (tester) async {
      await pumpWithDriver(
        tester,
        await _driver(),
        const EffectsScope(
          particles: true,
          child: AmbientBackdrop(sweep: true),
        ),
      );
      var sawFrames = false;
      var sawRest = false;
      // Walk three full intervals; a crossing needs frames, the rest between
      // two crossings must not.
      for (var i = 0; i < 3 * 9 * 4; i++) {
        await tester.pump(const Duration(milliseconds: 250));
        if (tester.binding.hasScheduledFrame) {
          sawFrames = true;
        } else {
          sawRest = true;
        }
      }
      expect(sawFrames, isTrue, reason: 'the band is animated');
      expect(sawRest, isTrue, reason: 'no frames while the band is away');
    });

    testWidgets('turning the effects off stops a sweep that was running', (
      tester,
    ) async {
      final driver = await _driver();
      Widget app(bool particles) => EffectsScope(
        particles: particles,
        child: const AmbientBackdrop(sweep: true),
      );
      await pumpWithDriver(tester, driver, app(true));
      await tester.pump(const Duration(seconds: 3)); // mid-crossing
      expect(tester.binding.hasScheduledFrame, isTrue);
      await pumpWithDriver(tester, driver, app(false));
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pump(const Duration(seconds: 30));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('fills its parent and ignores touches', (tester) async {
      var taps = 0;
      await pumpWithDriver(
        tester,
        await _driver(),
        Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
              ),
            ),
            const Positioned.fill(child: AmbientBackdrop()),
          ],
        ),
        size: const Size(800, 360),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(AmbientBackdrop)),
        const Size(800, 360),
      );
      await tester.tapAt(const Offset(400, 180));
      expect(taps, 1);
    });
  });
}
