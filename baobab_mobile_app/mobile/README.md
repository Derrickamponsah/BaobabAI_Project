# Baobab Mobile (Flutter)

1. `flutter create .`   (generates android/ and ios/ folders)
2. `flutter pub get`
3. Set the API URL in `lib/config.dart`.
4. Add permissions — see `../docs/ANDROID_PERMISSIONS.md`.
5. `flutter run`

Source layout: `lib/screens` (UI), `lib/services` (auth + API),
`lib/models` (JSON models), `lib/widgets`, `lib/theme`.
