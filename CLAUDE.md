# MedIntel — Flutter App (FYP-3)

## What this is
Cross-platform Flutter client for MedIntel, an AI prescription and pharmacy
platform. A separate Django web app (built by a teammate, not in this repo)
is the server-side counterpart. Final year project — defense is imminent, so
prefer small, safe, verifiable changes over refactors.

## Hard constraints
- NO external API keys anywhere. No Google Maps, no Google Places, no paid
  services. The Django side made "everything runs locally, no API keys" a
  defense point; the app must not contradict it.
- Do not add Firestore usage. Medicine schedules are moving server-side.
- Do not introduce new state management libraries. Provider only.
- Do not run `flutter clean` or delete build config without asking.
- Never commit `google-services.json` changes or API keys.

## Stack
- Flutter (SDK ^3.10.1), Material 3, Provider
- Firebase: Auth, Messaging (FCM). Firestore is legacy, being removed.
- sqflite for the offline medicine catalogue
- Theme lives in `lib/theme/app_theme.dart` — always use `AppColors`,
  `AppTextStyles`, `AppPrimaryButton`. Never hardcode colours or TextStyle.

## Layout
- `lib/screens/` — one file per screen, StatefulWidget, private `_build*`
  helper methods. Follow the existing file's structure when editing.
- `lib/services/` — data access. `mock_data.dart` holds `MockDataService`,
  which screens still call. New real data sources must expose the SAME method
  names and the SAME `Map<String, dynamic>` keys so screens don't change.
- `lib/models/` — plain Dart models, no codegen.
- `lib/widgets/` — shared widgets.
- `lib/navigation/app_navigation.dart` — named routes.

## Data contract (do not break)
Medicine maps use these keys: `id, name, brand, generic, category, dosage,
chemicalFormula, description, uses, howToUse, indications, sideEffects (List),
seriousSideEffects (List), warnings (List), alternatives (List<String>),
price (double), stock, inStock, imageUrl`.
Any new data source returns exactly these keys.

## Offline catalogue
`assets/db/medintel_catalog.db` is a read-only SQLite file with 18,793 real
Pakistani medicines exported from the Django `db_medicines.sqlite3`. It is
accessed only through `lib/services/medicine_catalog_service.dart`. Real prices
are PKR 310–4,950 (avg ~2,182) — any price filter default must be >= 5000.

## Backend integration (planned, not yet live)
The Django server has no REST API yet. All server calls go through a single
`ApiService` with an `AppConfig.useMock` flag. When `useMock` is true the app
falls back to `MockDataService`. Never scatter raw `http` calls across screens.

## Verification — run after every change
```
flutter analyze
flutter build apk --debug
```
Do not report a task complete until both succeed. If `flutter analyze` output
is long, fix only errors and warnings introduced by your change; the repo has
pre-existing info-level lints that are out of scope.

## Working style
- Work on one task at a time. Do not opportunistically refactor nearby code.
- Show a plan before touching more than two files.
- Prefer editing an existing file over creating a new one.
- If a change would touch build.gradle, AndroidManifest, or pubspec, explain
  why before doing it.
