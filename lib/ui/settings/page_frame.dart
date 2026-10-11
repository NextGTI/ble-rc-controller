import 'package:flutter/material.dart';

import '../common/glass.dart';
import '../common/metal_text.dart';
import '../theme/tokens.dart';

/// The widest a settings screen grows. On a tablet or a desktop window the
/// rows would stretch across the whole width, so the screen is centred in a
/// column of this size; in the 380 side panel of the desktop it is the panel.
const double settingsMaxWidth = 560;

/// The frame every screen behind the gear has (spec 5.4 to 5.7): a header with
/// the [title] in the metal text of the titles, a body that scrolls and, when
/// [footer] is given, a strip that stays fixed under it.
///
/// The header has a way back only when the screen was pushed as a route
/// (`Navigator.canPop`): a "back" chevron, or a "close" cross on the first
/// screen ([root]). On the desktop the side panel has its own way back, so
/// nothing is drawn there.
///
/// The frame paints nothing behind itself and does not need a `Scaffold`: the
/// host gives the background (a pushed route puts the `AmbientBackdrop` behind
/// it, the side panel its own glass). It does give a `Material` to the ink and
/// the sliders inside, keeps clear of the notches and the status bar and stays
/// within [settingsMaxWidth].
class SettingsFrame extends StatelessWidget {
  const SettingsFrame({
    super.key,
    required this.title,
    required this.children,
    this.footer,
    this.root = false,
  });

  final String title;

  /// The body, in a list that scrolls.
  final List<Widget> children;

  /// A strip under the body that does not scroll.
  final Widget? footer;

  /// Whether this is the first screen, which closes instead of going back.
  final bool root;

  /// Side of the buttons of the header.
  static const double button = 48;

  @override
  Widget build(BuildContext context) {
    final pushed = Navigator.canPop(context);
    final material = MaterialLocalizations.of(context);
    final back = pushed && !root;
    final close = pushed && root;

    final heading = Semantics(
      header: true,
      child: MetalText(
        title,
        maxLines: 2,
        style: AppType.numeric(size: 28).copyWith(height: 1.15),
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: settingsMaxWidth),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      if (back)
                        _HeaderButton(
                          icon: Icons.chevron_left,
                          tooltip: material.backButtonTooltip,
                        ),
                      Expanded(
                        child: Align(
                          // Between the buttons when there is a way back, as in
                          // the approved sketch; on the left otherwise.
                          alignment: back
                              ? Alignment.center
                              : Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: back ? 8 : 4,
                            ),
                            child: heading,
                          ),
                        ),
                      ),
                      if (close)
                        _HeaderButton(
                          icon: Icons.close,
                          tooltip: material.closeButtonTooltip,
                        )
                      else if (back)
                        const SizedBox(width: button),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: children,
                  ),
                ),
                if (footer != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: footer,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A glass square with an icon that leaves the screen: 48 by 48.
class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.tooltip});

  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.maybePop(context),
      tooltip: tooltip,
      icon: Icon(icon, size: 22),
      style: IconButton.styleFrom(
        foregroundColor: AppColors.text2,
        backgroundColor: AppColors.glass,
        side: const BorderSide(color: AppColors.glassEdge),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        fixedSize: const Size.square(SettingsFrame.button),
        minimumSize: const Size.square(SettingsFrame.button),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
  }
}

/// One glass surface with [items] one under the other and a hairline between
/// them, as `SettingsGroup` does for its rows but without a title on top.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: SizedBox(
                  height: 1,
                  child: ColoredBox(color: AppColors.glassEdge),
                ),
              ),
            items[i],
          ],
        ],
      ),
    );
  }
}

/// The "›" at the end of a row that opens another screen.
class SettingsChevron extends StatelessWidget {
  const SettingsChevron({super.key});

  @override
  Widget build(BuildContext context) =>
      const Icon(Icons.chevron_right, size: 22, color: AppColors.text3);
}
