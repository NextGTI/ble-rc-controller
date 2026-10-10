import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import 'cars_panel.dart';
import 'controllers_page.dart';
import 'controls_page.dart';
import 'drive_page.dart';
import 'motion.dart';
import 'settings_page.dart';

/// Wide windows: car list on the left, tabs on the right.
/// Narrow screens (phones): bottom navigation with all five pages.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _wide = 0; // 0 drive, 1 buttons, 2 controllers, 3 settings
  int _narrow = 1; // 0 cars, 1 drive, 2 buttons, 3 controllers, 4 settings

  static const _wideBreakpoint = 820.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;

    if (wide) {
      const pages = [DrivePage(), ControlsPage(), ControllersPage(), SettingsPage()];
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              const SizedBox(width: 300, child: CarsPanel()),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: SegmentedButton<int>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(value: 0, icon: const Icon(Icons.sports_esports_outlined), label: Text(l.navDrive)),
                          ButtonSegment(value: 1, icon: const Icon(Icons.keyboard_outlined), label: Text(l.navControls)),
                          ButtonSegment(value: 2, icon: const Icon(Icons.gamepad_outlined), label: Text(l.navControllers)),
                          ButtonSegment(value: 3, icon: const Icon(Icons.settings_outlined), label: Text(l.navSettings)),
                        ],
                        selected: {_wide},
                        onSelectionChanged: (s) => setState(() => _wide = s.first),
                      ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: motion(context, 240),
                        transitionBuilder: fadeSlide,
                        layoutBuilder: fillStack,
                        child: KeyedSubtree(key: ValueKey('wide$_wide'), child: pages[_wide]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    const pages = [CarsPanel(), DrivePage(), ControlsPage(), ControllersPage(), SettingsPage()];
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: motion(context, 240),
          transitionBuilder: fadeSlide,
          layoutBuilder: fillStack,
          child: KeyedSubtree(key: ValueKey('narrow$_narrow'), child: pages[_narrow]),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _narrow,
        onDestinationSelected: (i) => setState(() => _narrow = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.directions_car_outlined), label: l.navCars),
          NavigationDestination(icon: const Icon(Icons.sports_esports_outlined), label: l.navDrive),
          NavigationDestination(icon: const Icon(Icons.keyboard_outlined), label: l.navControls),
          NavigationDestination(icon: const Icon(Icons.gamepad_outlined), label: l.navControllers),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), label: l.navSettings),
        ],
      ),
    );
  }
}
