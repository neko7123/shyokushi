# Nutri Diary — Flutter starter

An early **local-first** personal food diary for Android and iOS. Food logs, weight measurements, profile and goals are stored locally in SQLite. The app has optional user-initiated online searches for food composition data; it does not currently send diary records or food photos to a server.

> **Honesty about the photo feature:** this starter lets you attach a photo to an entry, but it does not yet recognize food or infer portion size from that photo. A photo by itself is not sufficient to calculate accurate calories for many meals. See `docs/PRODUCT_REVIEW.md` for the proposed recognition flow.

## What's included

- Five tab areas: Today, Food diary, Meal planner, Progress and Settings.
- Per-100 g nutrition scaling for calories, protein, carbohydrates, fat, fibre and sugar.
- Planned food is stored separately from eaten food, so the forecast can be compared with the daily target.
- Weight-goal estimates using Mifflin–St Jeor BMR, an activity multiplier and conservative deadline guardrails.
- Open Food Facts food search; optional USDA FoodData Central search using a developer-supplied API key.
- Food photos copied into app documents storage, not merely retained at their temporary picker path.
- Passphrase-encrypted backup and restore. Backups include the profile, entries, weight logs and photo bytes; legacy JSON backups can still be imported.
- A few unit tests for portion scaling and goal plausibility.

## Run it

You need a recent Flutter SDK with Dart 3.7 or later. Flutter is not vendored in this archive.

1. Extract this folder.
2. From this folder, generate the native Android and iOS runner folders:

   ```bash
   flutter create --project-name nutri_diary --platforms=android,ios .
   ```

   If your Flutter version overwrites `pubspec.yaml`, restore this archive's `pubspec.yaml` before continuing.

3. Install dependencies and run tests:

   ```bash
   flutter pub get
   flutter test
   flutter analyze
   flutter run
   ```

   To run the web version, use `flutter run -d edge` (or another browser device). Web data is stored in that browser's IndexedDB and is scoped to the site's origin, including its port. The SQLite WebAssembly and worker files in `web/` are required for web builds.

4. If you want USDA search, create a personal API key at [FoodData Central](https://fdc.nal.usda.gov/api-key-signup.html) and run:

   ```bash
   flutter run --dart-define=USDA_API_KEY=YOUR_KEY
   ```

   This key is compiled into the app and can be extracted from a client build. This is acceptable only as a personal-development convenience, not a production secret-management strategy. USDA's documentation explicitly warns against publishing keys. Without this key, Open Food Facts search still works when online and manually entered food is always available.

## Platform setup notes

- Make sure the Android app manifest contains `android.permission.INTERNET` for online search.
- For iOS, add user-facing `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` strings to `ios/Runner/Info.plist` for the photo feature. Test camera and photo picking on real devices.
- Do not assume Android backup automatically includes this app's SQLite database and photo directory in a portable way. Use the in-app export and keep a backup outside the device.
- Online lookup requests send the search term to Open Food Facts and, when configured, USDA. The app does not currently upload food photos for recognition.

## Current limitations

- This is a **starter**, not a medically validated nutrition product.
- The food database is not exhaustive. Search results may omit regional foods, recipes and poorly documented products.
- Search data can be incomplete or have the wrong preparation state (e.g., raw vs cooked). Verify the selected item and enter the actual consumed grams.
- Attaching a photo is only record-keeping; AI food detection and image-based gram estimation are not implemented.
- Goal calculations use a simplified static calorie model. Actual weight response adapts over time, and calories estimated by formulas are not precise measurements.
- Protein and muscle gain recommendations have not been individualized for medical history, kidney disease, pregnancy, medications, age under 18 or eating-disorder risk.
- Encrypted exports embed images; large photo histories can produce large backup files. The local SQLite database is in app-private storage but is not separately encrypted in this starter. Web storage uses browser IndexedDB.
- Country preference currently chooses a regional Open Food Facts site. Official country composition databases are not yet integrated, and app text is not fully translated; the language preference localizes Flutter's built-in controls.

## Project map

```text
lib/
  main.dart                      App shell and navigation
  models/nutrition.dart           Food entries, nutrition values, profile and goal models
  data/app_database.dart          Local SQLite storage and replacement import
  services/food_search_service.dart  Open Food Facts + optional USDA search
  services/nutrition_calculator.dart BMR, TDEE, food totals and goal guardrails
  services/backup_service.dart    JSON import/export with embedded photos
  ui/screens.dart                 Five app areas and entry/profile forms
test/
  nutrition_calculator_test.dart
```

## Food-data attribution / licensing

- USDA FoodData Central data is public domain under CC0 1.0; USDA requests source attribution. The API requires a key and has rate limits. Read [the USDA API guide](https://fdc.nal.usda.gov/api-guide/) before shipping an app that uses it.
- Open Food Facts has database and content licensing obligations, including ODbL share-alike provisions for the database and separate image licensing. Review [the Open Food Facts licensing guide](https://openfoodfacts.github.io/openfoodfacts-server/api/tutorials/license-be-on-the-legal-side/) before distributing an app or a derivative database.
- This app does not bundle or redistribute an entire third-party database.

## Next engineering milestones

1. Run the scaffold on both Android and iOS; fix platform-specific issues and test backup round-trips.
2. Add a persistent, searchable local food catalogue and favourites/recent foods.
3. Add recipe builder (ingredient quantities, cooked/raw states, cooked yield, per-serving nutrition) and barcode scanning.
4. Add weekly trends and separate calorie/protein targets with transparent provenance/confidence.
5. Add opt-in on-device image classification, then image-assisted ingredient suggestions and a user-confirmed portion step.
6. Only then consider an optional AI assistant. Keep remote inference off by default if strict local-only privacy is a requirement.
