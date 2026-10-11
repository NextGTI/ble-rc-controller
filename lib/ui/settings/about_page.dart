import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../l10n/gen/app_localizations.dart';
import '../common/glass.dart';
import '../common/metal_text.dart';
import '../theme/tokens.dart';
import 'page_frame.dart';

/// Where the code lives. Shown as text to select and copy: the app has no
/// package to open links with.
const String repositoryAddress = 'github.com/daniel-nextgti/ble-rc-controller';

/// The version of the app as the package says it: "1.0.2", or null when the
/// platform did not tell it (or told an empty one).
///
/// With [withBuild] the build number follows, "1.0.2 (7)", as it tells apart
/// two installs of one version; a package with no build number has none.
String? versionOf(PackageInfo? info, {bool withBuild = false}) {
  final version = info?.version ?? '';
  if (version.isEmpty) return null;
  final build = info!.buildNumber;
  return withBuild && build.isNotEmpty ? '$version ($build)' : version;
}

/// About the app (spec 5.4): its name and version, where the code is, the MIT
/// licence with the notice that the project is independent of any brand, and a
/// button for the licences of the packages it uses.
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  // Looked up once; the package keeps the answer, so this is cheap.
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SettingsFrame(
      title: l.aboutTitle,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: MetalText(
            l.appTitle,
            maxLines: 2,
            style: AppType.numeric(size: 36).copyWith(height: 1.15),
          ),
        ),
        FutureBuilder<PackageInfo>(
          future: _info,
          builder: (context, snapshot) {
            final version = versionOf(snapshot.data, withBuild: true);
            if (version == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Text(
                l.versionLabel(version),
                style: AppType.body(size: 15).copyWith(color: AppColors.text2),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        SettingsCard(
          items: [
            _Block(
              label: l.aboutRepository,
              child: SelectableText(
                repositoryAddress,
                style: AppType.body(size: 15).copyWith(color: AppColors.text),
              ),
            ),
            _Block(
              label: l.aboutLicenseMit,
              child: Text(
                l.disclaimer,
                style: AppType.body(size: 13.5)
                    .copyWith(color: AppColors.text2, height: 1.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Glass(
          onTap: () => _showLicenses(context, l),
          child: Center(
            child: Text(
              l.aboutLicenses,
              textAlign: TextAlign.center,
              style: AppType.body(size: 15).copyWith(color: AppColors.text),
            ),
          ),
        ),
      ],
    );
  }

  /// The licences are a full page, so it goes over the whole window and not
  /// inside the narrow side panel of the desktop.
  Future<void> _showLicenses(BuildContext context, AppLocalizations l) async {
    final version = await _info.then<String?>(
      (info) => versionOf(info, withBuild: true),
      onError: (_) => null,
    );
    if (!context.mounted) return;
    showLicensePage(
      context: context,
      applicationName: l.appTitle,
      applicationVersion: version,
      useRootNavigator: true,
    );
  }
}

/// A small label over what it names.
class _Block extends StatelessWidget {
  const _Block({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppType.body(size: 12).copyWith(color: AppColors.text3),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}
