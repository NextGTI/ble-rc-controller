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
- Please don't add code, assets or trademarks that belong to a car, toy or fuel brand.

## Adding a controller

Most controllers are recognised by the built-in mapping database. If yours is not, use **Controllers → Teach this controller…** in the app. To make the fix permanent for everyone, open an issue with the vendor/product ID and the raw signals from the Input monitor.

## Licence

By contributing you agree your work is released under the [MIT licence](LICENSE).
