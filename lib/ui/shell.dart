import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'cockpit/cockpit.dart';
import 'common/ambient.dart';
import 'common/glass.dart';
import 'garage/car_sheet.dart';
import 'garage/garage_column.dart';
import 'settings/settings_page.dart';
import 'strings.dart';
import 'theme/tokens.dart';

/// The first widget of the app (spec 5.1 and 6): there is no tab bar, the
/// cockpit is the screen and everything else leaves from it.
///
/// The layout comes from the size of the window (`layoutFor`):
/// - desktop (900 or more): the garage column and the cockpit side by side,
///   with the light of the window behind both. The garage is the column, so
///   the name of the car in the header is not a button;
/// - the rest: the cockpit alone, and the name of the car opens the sheet of
///   cars.
///
/// The gear calls [openSettings].
class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final desktop = layoutFor(MediaQuery.sizeOf(context)) == LayoutKind.desktop;

    // The cockpit paints its own light over its own area. On the desktop the
    // column is beside it, and its glass needs a light to blur: the window's.
    final Widget body = desktop
        ? Stack(
            fit: StackFit.expand,
            children: [
              const AmbientBackdrop(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const GarageColumn(),
                  Expanded(
                    child: Cockpit(onSettings: () => openSettings(context)),
                  ),
                ],
              ),
            ],
          )
        : Cockpit(
            onSettings: () => openSettings(context),
            onCarTap: () => _openCars(context),
          );

    // The garage column has rows with ink, which need a Material under them.
    return Material(color: AppColors.bg, child: body);
  }
}

/// Whether the screen that [context] is on is the one in front. A sheet, the
/// settings or a dialog on top of it make it not, and a tap that gets through
/// to it meanwhile (two taps before a frame, one while the screen below is
/// still showing as the top one goes away) must not open a second one.
bool _isInFront(BuildContext context) =>
    ModalRoute.of(context)?.isCurrent ?? true;

/// Opens the sheet of cars, unless something is already in front of the
/// cockpit, so sheets never pile up.
void _openCars(BuildContext context) {
  if (!_isInFront(context)) return;
  showCarSheet(context);
}

/// Opens the settings (spec 5.1), unless something is already in front of
/// the cockpit.
///
/// - Desktop (900 or more wide): a panel of 380 on the right, over the
///   cockpit dimmed to 65%. A click on the dimmed part closes it, and so does
///   Esc. The pages switch inside the panel, which has a `Navigator` of its
///   own, so the cockpit stays in sight.
/// - The other layouts: a screen over the cockpit, with the ambient light
///   behind it. Each page is a new route, and the back of the system works.
///
/// The pages draw their own way back when they can go back (`Navigator`), so
/// nothing here draws a second one.
void openSettings(BuildContext context) {
  if (!_isInFront(context)) return;
  if (layoutFor(MediaQuery.sizeOf(context)) == LayoutKind.desktop) {
    _openDrawer(context);
    return;
  }
  final navigator = Navigator.of(context);
  void open(Widget page) => navigator.push(_screenRoute(page));
  open(SettingsPage(open: open));
}

/// A screen of the phone, tablet and landscape layouts: [page] over the
/// ambient light (the pages paint no background of their own).
Route<void> _screenRoute(Widget page) => MaterialPageRoute<void>(
  builder: (_) =>
      Stack(fit: StackFit.expand, children: [const AmbientBackdrop(), page]),
);

/// Width of the panel of the settings on the desktop.
const double _drawerWidth = 380;

/// The cockpit behind the panel, dimmed: black at 35% (spec 5.1).
const Color _scrim = Color.fromRGBO(0, 0, 0, 0.35);

void _openDrawer(BuildContext context) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: _scrim,
    // State changes take AppMotion.state (spec 3.4); with the system's
    // "reduce motion" the panel and the dimming are in place at once.
    transitionDuration: reduceMotion ? Duration.zero : AppMotion.state,
    pageBuilder: (_, animation, _) =>
        _SettingsDrawer(animation: animation, reduceMotion: reduceMotion),
  );
}

/// The panel of the settings on the desktop: frosted glass of 380 on the
/// right edge, with a `Navigator` of its own for the pages.
///
/// Esc closes the whole panel, from any page. The one case it does not is the
/// Esc that ends a capture of an input or a teaching: that belongs to the
/// driver, which cancels it, and the panel stays. Nothing else is taken from
/// the keyboard (the driving keys are the driver's), and when the panel is
/// closed there is nothing here.
class _SettingsDrawer extends StatefulWidget {
  const _SettingsDrawer({required this.animation, required this.reduceMotion});

  /// The coming and going of the panel: it slides in from the right by its
  /// own width (the dimming behind it follows the same animation).
  final Animation<double> animation;
  final bool reduceMotion;

  @override
  State<_SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<_SettingsDrawer> {
  final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();

  /// A page inside the panel. The pages have no background of their own and
  /// sit on the glass, so one cannot slide over the other: the old one fades
  /// out, then the new one fades in.
  Route<void> _pageRoute(Widget page) {
    final time = widget.reduceMotion ? Duration.zero : AppMotion.state;
    return PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => page,
      transitionDuration: time,
      reverseTransitionDuration: time,
      transitionsBuilder: (_, animation, secondary, child) => FadeTransition(
        opacity: animation.drive(
          CurveTween(curve: const Interval(0.3, 1, curve: Curves.easeOut)),
        ),
        child: FadeTransition(
          opacity: secondary.drive(
            Tween<double>(
              begin: 1,
              end: 0,
            ).chain(CurveTween(curve: const Interval(0, 0.3))),
          ),
          child: child,
        ),
      ),
    );
  }

  void _open(Widget page) => _navigator.currentState?.push(_pageRoute(page));

  @override
  Widget build(BuildContext context) {
    final driver = DriverScope.of(context);
    final route = ModalRoute.of(context);
    final navigator = Navigator.of(context);

    // The driver listens to the keyboard on its own, before the focus tree,
    // and the Esc that ends a capture of an input or a teaching is its: by
    // the time the shortcut below runs, the driver has already stopped. So
    // the shortcut is only there while neither is going on, as of the last
    // frame, which is what the screen showed when the key was pressed.
    final teaching = driver.teaching;
    final busy = driver.capturing != null || (teaching?.finished == false);

    void close() {
      // Once, and only while the panel is the front screen.
      if (route?.isCurrent ?? false) navigator.pop();
    }

    return Align(
      alignment: Alignment.centerRight,
      child: SlideTransition(
        position: widget.animation.drive(
          Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOut)),
        ),
        child: SizedBox(
          width: _drawerWidth,
          height: double.infinity,
          child: CallbackShortcuts(
            bindings: {
              if (!busy)
                const SingleActivator(LogicalKeyboardKey.escape): close,
            },
            child: _DrawerSurface(
              // The system back closes a page of the panel before the panel.
              child: NavigatorPopHandler(
                onPopWithResult: (_) => _navigator.currentState?.maybePop(),
                child: Navigator(
                  key: _navigator,
                  onGenerateRoute: (_) => _pageRoute(SettingsPage(open: _open)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The frosted surface of the panel (spec 3.3): a 14 px blur of what is
/// behind, a dark veil so the texts stay legible over the cockpit, the 4%
/// glass fill, an 8% outline and a line of light on the top edge. The corners
/// on the inner edge have a radius of 24.
class _DrawerSurface extends StatelessWidget {
  const _DrawerSurface({required this.child});

  final Widget child;

  static const double radius = 24;
  static const BorderRadius _shape = BorderRadius.horizontal(
    left: Radius.circular(radius),
  );

  /// White at 6.5%: the same line of light as `Glass`.
  static const Color _lightLine = Color.fromRGBO(255, 255, 255, 0.065);

  /// The background at 86% under the glass fill.
  static final Color _fill = Color.alphaBlend(
    AppColors.glass,
    AppColors.bg.withValues(alpha: 0.86),
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: _shape,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: Glass.blur, sigmaY: Glass.blur),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: _fill,
            shape: const RoundedRectangleBorder(
              borderRadius: _shape,
              side: BorderSide(color: AppColors.glassEdge),
            ),
          ),
          child: Stack(
            children: [
              child,
              Positioned(
                top: 1,
                left: radius * 0.5,
                right: radius * 0.5,
                height: 1,
                child: const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.fromRGBO(255, 255, 255, 0),
                          _lightLine,
                          _lightLine,
                          Color.fromRGBO(255, 255, 255, 0),
                        ],
                        stops: [0, 0.2, 0.8, 1],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
