import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/driver.dart';
import '../../input/controller_profile.dart';
import '../../input/pad_input.dart';
import '../../l10n/gen/app_localizations.dart';
import '../common/glass.dart';
import '../common/notice.dart';
import '../strings.dart';
import '../theme/tokens.dart';
import 'gamepad_drawing.dart';
import 'page_frame.dart';

/// The five groups the 18 steps come in, in the order they are asked.
enum _Group { face, shoulders, middle, sticks, dpad }

_Group _groupOf(String stepId) {
  switch (stepId) {
    case 'a' || 'b' || 'x' || 'y':
      return _Group.face;
    case 'leftBumper' || 'rightBumper' || 'leftTrigger' || 'rightTrigger':
      return _Group.shoulders;
    case 'back' || 'start':
      return _Group.middle;
    case 'axis:leftStickX' ||
        'axis:leftStickY' ||
        'axis:rightStickX' ||
        'axis:rightStickY':
      return _Group.sticks;
    case 'dpadUp' || 'dpadDown' || 'dpadLeft' || 'dpadRight':
      return _Group.dpad;
  }
  throw ArgumentError.value(stepId, 'stepId', 'is not a teach step');
}

/// The name of the group that the teach step [stepId] is in: "Botões de ação",
/// "Ombros e gatilhos", "Botões do meio", "Analógicos" or "Direcional".
String teachGroupOf(AppLocalizations l, String stepId) =>
    switch (_groupOf(stepId)) {
      _Group.face => l.teachGroupFace,
      _Group.shoulders => l.teachGroupShoulders,
      _Group.middle => l.teachGroupMiddle,
      _Group.sticks => l.teachGroupSticks,
      _Group.dpad => l.teachGroupDpad,
    };

/// What the tag of a step that was learned says: the short name of the input
/// that the step teaches ([stepId], one of the ids of `teachSteps`).
///
/// A stick axis is named for the direction it was pushed in: "right" for the
/// horizontal axis and "up" for the vertical, which is what the step asked
/// for. The name without a direction (`padLeftStick`) is the click of the
/// stick, a different input.
String teachTagOf(AppLocalizations l, String stepId) => switch (stepId) {
  'axis:leftStickX' => l.padLeftStickRight,
  'axis:leftStickY' => l.padLeftStickUp,
  'axis:rightStickX' => l.padRightStickRight,
  'axis:rightStickY' => l.padRightStickUp,
  _ => l.pad(PadInput.values.byName(stepId)),
};

/// The wizard that teaches the app a controller it does not know (spec 5.7).
///
/// It shows the session the driver holds (`driver.teaching`) one step at a
/// time: the drawing of the controller with the part of the step lit, the
/// question in large type with the names the brands give the button, the step
/// and its group, and the inputs already learned in this group. "Pular" skips
/// the step; "Cancelar" ends the session. When the last step is over the
/// driver has saved the mapping, and "Pronto" closes the wizard.
///
/// The page is the session's window and nothing more: it begins nothing and
/// decides nothing. When the session ends, by "Cancelar", "Pronto", the Esc
/// that the driver takes on the desktop or a new session, the page closes
/// itself. And when the page goes away by any other way (back, the system
/// back, the panel closed from outside) it ends the session, so the driver is
/// never left teaching to nobody.
///
/// Losing the controller does not end it: the page says there is none and
/// leaves "Cancelar" at hand.
class TeachPage extends StatefulWidget {
  const TeachPage({super.key});

  @override
  State<TeachPage> createState() => _TeachPageState();
}

class _TeachPageState extends State<TeachPage> {
  Driver? _driver;

  /// The session this page was opened for. The page keeps showing it while it
  /// slides out, after the driver has let go of it.
  TeachSession? _session;

  bool _closing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final driver = DriverScope.of(context);
    _driver = driver;
    _session ??= driver.teaching;
  }

  /// Whether the driver is still on this page's session.
  bool get _live {
    final session = _session;
    return session != null && identical(_driver?.teaching, session);
  }

  /// Ends the session if it is still going on: a finished one is closed (its
  /// mapping is already saved), any other is cancelled.
  void _end() {
    final driver = _driver;
    final session = _session;
    if (driver == null || session == null || !_live) return;
    if (session.finished) {
      driver.finishTeaching();
    } else {
      driver.cancelTeaching();
    }
  }

  /// Closes the page once the frame is done, as the session is over.
  void _closeSoon() {
    if (_closing) return;
    _closing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ModalRoute.of(context)?.isCurrent ?? false) {
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  void dispose() {
    // A page that is taken off the screen without being popped (the panel is
    // closed from outside) ends its session too. Not now: the tree is locked
    // and the driver would tell it to rebuild.
    if (_live) scheduleMicrotask(_end);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driver = DriverScope.of(context);
    final l = AppLocalizations.of(context);
    final session = _session;

    // The session is over, or there never was one: nothing here is of use.
    if (_live) {
      _closing = false;
    } else {
      _closeSoon();
    }
    if (session == null) return const SizedBox.shrink();

    final finished = session.finished;
    final noController = driver.controllers.isEmpty;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _end();
      },
      child: SettingsFrame(
        title: l.teachTitle,
        closeLeading: true,
        footer: _Actions(
          buttons: finished
              ? [_ActionButton(label: l.done, onTap: _end, primary: true)]
              : [
                  _ActionButton(label: l.skip, onTap: driver.skipTeachStep),
                  _ActionButton(label: l.cancel, onTap: _end),
                ],
        ),
        children: [
          if (noController)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Notice(
                title: l.noControllerShort,
                body: l.noControllerHint,
              ),
            ),
          if (finished) _Finished(message: l.teachDone) else _Step(session),
        ],
      ),
    );
  }
}

/// The step the session is on.
class _Step extends StatelessWidget {
  const _Step(this.session);

  final TeachSession session;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final step = session.current;
    final hint = l.teachHint(step.id);
    final done = _doneTags(l);

    final drawing = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: GamepadDrawing(highlight: gamepadPartFor(step.id)),
      ),
    );
    // A new step is read out by a screen reader without being looked for.
    final question = Semantics(
      container: true,
      liveRegion: true,
      child: Column(
        children: [
          Text(
            l.teach(step.id),
            textAlign: TextAlign.center,
            style: AppType.numeric(size: 26)
                .copyWith(color: AppColors.text, height: 1.15),
          ),
          if (hint != null) ...[
            const SizedBox(height: 8),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: AppType.body(size: 13.5)
                  .copyWith(color: AppColors.text2, height: 1.4),
            ),
          ],
        ],
      ),
    );
    final progress = _Progress(
      step: l.teachStep(session.index + 1, teachSteps.length),
      group: teachGroupOf(l, step.id),
      fraction: (session.index + 1) / teachSteps.length,
    );
    final tags = done.isEmpty
        ? null
        : Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final label in done) _DoneTag(label: label)],
          );

    // On a phone turned sideways the window is too short for the drawing and
    // the question one over the other: the question would be below the fold.
    // Side by side, both are in sight, as the step asks for them.
    final sideways =
        layoutFor(MediaQuery.sizeOf(context)) == LayoutKind.landscape;
    if (sideways) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: drawing),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                question,
                const SizedBox(height: 20),
                progress,
                if (tags != null) ...[const SizedBox(height: 12), tags],
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        drawing,
        const SizedBox(height: 24),
        question,
        const SizedBox(height: 24),
        progress,
        if (tags != null) ...[const SizedBox(height: 16), tags],
      ],
    );
  }

  /// The tags of what was learned in the group of the current step, in the
  /// order the steps are asked. A step that was skipped has none.
  List<String> _doneTags(AppLocalizations l) {
    final group = _groupOf(session.current.id);
    final learned = {
      for (final mappings in session.draft.values)
        for (final m in mappings) m.role,
    };
    return [
      for (final step in teachSteps)
        if (_groupOf(step.id) == group && learned.contains(step.id))
          teachTagOf(l, step.id),
    ];
  }
}

/// "Passo n de 18" and the group on one line, and a thin bar under them that
/// fills as the steps go by.
class _Progress extends StatelessWidget {
  const _Progress({
    required this.step,
    required this.group,
    required this.fraction,
  });

  final String step;
  final String group;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final label = AppType.body(size: 12).copyWith(color: AppColors.text3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MergeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step, style: label),
              const SizedBox(width: 12),
              Expanded(
                child: Text(group, textAlign: TextAlign.end, style: label),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ExcludeSemantics(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: SizedBox(
              height: 2,
              child: ColoredBox(
                color: AppColors.traceWeak,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: fraction),
                    duration: Glass.timeOf(context),
                    curve: Glass.curve,
                    builder: (context, value, _) => FractionallySizedBox(
                      widthFactor: value,
                      heightFactor: 1,
                      child: const ColoredBox(color: AppColors.amber),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A small tag with a tick: an input the wizard has learned.
class _DoneTag extends StatelessWidget {
  const _DoneTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.glassEdge),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check, size: 13, color: AppColors.text2),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: AppType.body(size: 12).copyWith(color: AppColors.text2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The end: all the steps are over and the mapping is saved.
class _Finished extends StatelessWidget {
  const _Finished({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const _Tick(),
        const SizedBox(height: 24),
        Semantics(
          container: true,
          liveRegion: true,
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: AppType.numeric(size: 26)
                .copyWith(color: AppColors.text, height: 1.15),
          ),
        ),
      ],
    );
  }
}

/// A tick in a ring of the active glass: the mapping was saved.
class _Tick extends StatelessWidget {
  const _Tick();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.amber.withValues(alpha: 0.10),
              AppColors.amber.withValues(alpha: 0.03),
            ],
          ),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.35)),
        ),
        child: const SizedBox.square(
          dimension: 72,
          child: Icon(Icons.check, size: 32, color: AppColors.amber),
        ),
      ),
    );
  }
}

/// The strip under the page: its [buttons] side by side, of the same width.
class _Actions extends StatelessWidget {
  const _Actions({required this.buttons});

  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: buttons[i]),
        ],
      ],
    );
  }
}

/// A glass button at least 48 high. The main one, "Pronto", is amber; the
/// others are quiet.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 14,
      active: primary,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            // The active glass colours its text amber.
            style: AppType.body(size: 15)
                .copyWith(color: primary ? null : AppColors.text2),
          ),
        ),
      ),
    );
  }
}
