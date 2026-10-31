# iOS: build, test and release

The iOS app is the same Flutter code as the other platforms. These notes cover
what is specific to Apple.

## Identity

| | |
|---|---|
| Bundle ID | `br.com.nextgti.blercontroller` (the same as Android and macOS) |
| Team | NextGTI (Apple Developer Program, organisation) |
| Minimum iOS | 15.0 |
| Devices | iPhone and iPad, portrait and landscape |
| Languages | English, Portuguese (Brazil), Spanish |

`ios/Runner/Info.plist` declares:
- the Bluetooth permission (`NSBluetoothAlwaysUsageDescription`); it is
  translated in `ios/Runner/*.lproj/InfoPlist.strings`;
- game controller support (`GCSupportsControllerUserInteraction`,
  `GCSupportedGameControllers`), so the App Store shows the controller badge;
- no non-exempt encryption (`ITSAppUsesNonExemptEncryption = NO`), which
  answers the export question for every build.

`ios/Runner/PrivacyInfo.xcprivacy` declares that the app tracks no one and
collects nothing. It also gives the reason for using `UserDefaults`
(CA92.1: settings that only the app reads).

The icon is a single 1024 px square without transparency
(`ios/Runner/Assets.xcassets/AppIcon.appiconset`), drawn by `tool/icon.html?m=ios`.

## Testing

The iOS Simulator has no Bluetooth: it shows the layouts and the
"Bluetooth unavailable" screen, but cannot reach a car. Driving needs an
iPhone or iPad:

```bash
flutter run -d <iPhone> --release
```

The first run on a device needs the NextGTI team selected in Xcode (open
`ios/Runner.xcworkspace` → Runner → Signing & Capabilities) and the device in
developer mode.

## Release

1. Raise `version:` in `pubspec.yaml`. The part after `+` is the build number;
   App Store Connect refuses a build number it has already seen.
2. Build the signed archive and the `.ipa`:

   ```bash
   flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
   ```

   This writes `build/ios/archive/Runner.xcarchive` and `build/ios/ipa/*.ipa`.
   Signing is automatic, with the NextGTI team signed in to Xcode
   (Xcode → Settings → Accounts).
3. Upload the build in one of three ways:
   - Xcode → Window → Organizer → the archive → **Distribute App** → App Store
     Connect.
   - The Transporter app, dragging in the `.ipa`.
   - From the command line, with the account signed in to Xcode: copy
     `ios/ExportOptions.plist`, set its `destination` to `upload`, then

     ```bash
     xcodebuild -exportArchive -archivePath build/ios/archive/Runner.xcarchive \
       -exportOptionsPlist <the copy> -exportPath /tmp/upload -allowProvisioningUpdates
     ```
4. In App Store Connect, pick the build in the version page, then send it to
   review. The required screenshots are iPhone "Dynamic Island, medium
   display" (1206 × 2622) and iPad 13" (2752 × 2064 in landscape);
   `marketing/app-store-shots.html` composes them. The page text, answers
   and review notes are kept outside Git, in `marketing/app-store/listing.md`.

The CI (`.github/workflows/build.yml`) builds iOS without signing on every
push, only to catch a change that breaks the iOS build.
