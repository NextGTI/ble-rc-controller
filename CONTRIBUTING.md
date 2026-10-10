# Contributing

Thanks for helping! The most valuable contributions are **test reports from real hardware**: other car models, Android, Windows and other controllers.

## Reporting a problem

Open an issue with:

- your OS and version, and the car's Bluetooth name (e.g. `SL-SF-25`);
- the controller model, and what **Controllers → Input monitor** shows when you press the problem button;
- what you expected and what happened.

## Code

```bash
flutter pub get
flutter analyze
flutter test
```

- Keep `flutter analyze` clean and add a test for logic changes (`test/`).
- UI text goes in `tool/gen_arb.py` for **all three languages** (English, Spanish, Portuguese), then run `python3 tool/gen_arb.py && flutter gen-l10n`.
- The car protocol lives in `lib/core/protocol.dart` and `docs/PROTOCOL.md` (keep the three translated copies in sync).
- Please don't add code, assets or logos that belong to a car, toy or fuel brand. Brand names are fine only to describe compatibility.

## Adding support for another car

More cars are planned. To help, open an issue with:

- the car's Bluetooth name as advertised (e.g. `SL-…`) and its brand/model;
- the GATT services and characteristics (a BLE scanner app such as nRF Connect shows them);
- whether the car reacts to the 8-byte packet described in [docs/PROTOCOL.md](docs/PROTOCOL.md).

## Adding a controller

Most controllers are recognised by the built-in mapping database. If yours is not, use **Controllers → Teach this controller…** in the app. To make the fix permanent for everyone, open an issue with the vendor/product ID and the raw signals from the Input monitor.

## Releasing (maintainers)

Releases are created with your own `gh` login (never a CI bot) and a signed tag, so GitHub shows them as **Verified**.

1. One-time: create an SSH signing key, add it to GitHub as a *signing key*, and set `gpg.format ssh`, `user.signingkey`, `commit.gpgsign true`, `tag.gpgsign true`.
2. Bump `version:` in `pubspec.yaml`, add `release-notes/vX.Y.Z.md`, commit, push to `main`, wait for the **Build** workflow to pass.
3. Run `tool/release.sh`. It downloads the Android, macOS and Windows packages built by CI, creates a signed `vX.Y.Z` tag and publishes the release.

## Licence

By contributing you agree your work is released under the [MIT licence](LICENSE).
