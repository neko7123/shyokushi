# 食誌 ShyokuShi

### A quiet space for your daily food journal.

**食誌 (ShyokuShi)** is a personal food diary and nutrition tracker built with Flutter. Record what you eat, review nutritional estimates, plan upcoming meals, and follow your weight history — while keeping your personal diary on your device.

<p align="center">
  <img src="assets/shiyokushi_logo.svg" alt="食誌 ShyokuShi logo" width="180">
</p>

<p align="center">
  <strong>Eat mindfully. Track honestly. Keep your data yours.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-Framework-02569B?logo=flutter&logoColor=white" alt="Built with Flutter">
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white" alt="Android">
  <img src="https://img.shields.io/badge/Storage-Local--first-4A6741" alt="Local-first storage">
  <img src="https://img.shields.io/badge/Privacy-No%20account%20required-6B8E72" alt="No account required">
</p>

---

## Overview

食誌 is designed for people who want a practical way to understand their eating habits without handing their personal diary to a cloud service.

It brings food logging, calorie and macronutrient tracking, meal planning, weight history, and encrypted data exports into one personal application.

Rather than pretending every food estimate is exact, 食誌 lets you review nutritional information, choose from food database results, and enter your own values when needed.

### What you can do

- Record meals with multiple food items, quantities, notes, and optional photos.
- Calculate calories and available macronutrients from recorded food values.
- Search food databases or enter nutrition information manually.
- Plan meals and preview projected daily calorie intake.
- Track body weight and review historical changes.
- Estimate daily energy needs based on your profile and goal.
- Export and restore your diary using encrypted backups.
- Use the app without creating an online account.

## Privacy by design

食誌 is **local-first**, with no cloud diary or automatic synchronization in the current version.

| Privacy feature | Current behavior |
|---|---|
| Account | No account required |
| Diary storage | Stored in app storage on the device |
| Profile and goals | Stored locally |
| Food photos | Stored locally with their entries |
| Cloud synchronization | Not implemented |
| Advertising and analytics | No advertising or analytics system in this version |
| Online food search | Search queries are sent to the selected external food-data providers |
| Photo recognition | No AI-based food recognition or automatic portion estimation |
| Live database encryption | The app-managed database is not separately encrypted |
| Backup protection | Exported backups are encrypted and require their generated key to restore |

**An important distinction:** local storage does not mean every file on the device is independently encrypted. The app-managed database is not separately encrypted, so protect your device and use encrypted backups when exporting personal records.

Food search is an online operation. Search terms may be transmitted to Open Food Facts or USDA FoodData Central. Your diary, profile, and photos are not sent as part of the food-search request.

For details, see the privacy notice and terms available in the application.

## Features

### 1. Daily dashboard

Get an overview of your recorded intake without navigating through every meal.

- Calories logged versus your estimated daily target.
- Protein, carbohydrate, and fat totals.
- Calorie history over a week, month, quarter, or year.
- Period totals and daily averages.
- Visual summaries based on your recorded entries.

The dashboard reflects the data you enter. Missing or incomplete food information can affect the totals.

### 2. Food diary

Maintain a date-based record of what you eat.

- Group foods into meals.
- Add several ingredients to one meal.
- Record quantities in grams.
- Attach an optional meal photo.
- Add notes about ingredients or preparation.
- Edit and delete recorded entries.
- Navigate between dates and revisit earlier meals.
- Review daily calories and available nutrients.

### 3. Food search and nutrition data

Find food information through supported online sources or enter it manually.

**Supported data providers:**

- [Open Food Facts](https://world.openfoodfacts.org/) — packaged foods and product information.
- [USDA FoodData Central](https://fdc.nal.usda.gov/) — food composition and supported branded-food records.

Features include:

- Search across supported food databases.
- Review matching results.
- Select a food record to populate available nutrient values.
- Enter custom nutrition values when a suitable record is unavailable.
- Record nutrition values per 100 g and apply them to the quantity eaten.
- Select a country or regional food-reference preference.

Available country settings include Japan, the United States, Canada, the United Kingdom, South Korea, China, and Other.

Regional preferences help guide catalogue searches; they do not guarantee that a result is approved by a national health authority or represents an official regional recommendation.

Food records can be incomplete, outdated, or inaccurate. Check product labels and preparation details where possible.

### 4. Meal planning

Plan what you intend to eat before adding it to your actual diary.

- Add foods as planned entries.
- Calculate projected daily intake from logged and planned food.
- Compare projected calories with your estimated daily target.
- Review the effect of a proposed meal on your daily total.
- Mark planned food as eaten when appropriate.
- Edit or remove planned entries.

Planned food and consumed food have different meanings. Review the projected total before converting a planned entry into a diary record.

### 5. Weight and progress tracking

Keep a personal record of body-weight changes.

- Record weight measurements.
- Review the latest recorded weight.
- View weight history.
- See the change across your recorded range.
- Calculate an estimated BMI when sufficient profile information is available.

Adult BMI categories are not displayed for users under 18. BMI is a screening measure, not a direct measurement of body fat or muscle mass.

Progress charts reflect the measurements you record and should not be interpreted as medical assessments.

### 6. Personal profile and goals

Configure the profile information used for goal estimates.

- Record age, height, weight, sex-related inputs, and activity level where applicable.
- Choose weight loss, weight gain, or maintenance.
- Set a target weight and target date.
- Review estimated calorie requirements.
- Receive warnings for targets that appear unrealistic under the app's estimation rules.

These values are estimates based on general formulas and simplified assumptions. Actual energy needs and weight changes vary between individuals.

食誌 is a personal tracking tool, not a medical service or a substitute for individualized nutrition advice.

### 7. Personalization

Make the interface fit your preferences.

- Set a display name.
- Choose English, Japanese, Chinese, or Korean.
- Select System, Light, or Dark appearance.
- Follow the device appearance setting when System mode is selected.
- Use the 食誌 leaf branding throughout the application.

### 8. Encrypted backups and restore

Keep a portable copy of your personal records.

- Export an encrypted backup.
- Include diary entries, planned entries, profile and preference data, weight history, and available meal photos.
- Save Android backups in `Downloads/ShyokuShi`.
- Receive a generated 10-character backup key after export.
- Restore supported encrypted backups using the corresponding key.
- Import supported legacy JSON backups.

**Backups are important, but restoration replaces existing data.** Export your current diary before importing a backup you are unsure about.

Keep the backup key separately from the backup file. The application cannot recover a lost key.

Backup encryption protects the exported copy; it does not mean the live database is separately encrypted.

## Screenshots

The screenshots below are intended to show the real application interface. Add your own screenshots to `assets/screenshots/` before enabling this section.

<!--
Uncomment the images after adding the corresponding files.

<p align="center">
  <img src="assets/screenshots/home.png" width="230" alt="Daily dashboard">
  <img src="assets/screenshots/diary.png" width="230" alt="Food diary">
  <img src="assets/screenshots/planner.png" width="230" alt="Meal planner">
</p>

<p align="center">
  <img src="assets/screenshots/progress.png" width="230" alt="Weight progress">
  <img src="assets/screenshots/food-search.png" width="230" alt="Food search">
  <img src="assets/screenshots/settings.png" width="230" alt="Application settings">
</p>
-->

Suggested screenshots:

| File | Screen |
|---|---|
| `home.png` | Daily calories and macronutrients |
| `diary.png` | Food entries grouped by meal |
| `planner.png` | Planned meals and projected calories |
| `progress.png` | Weight history and progress |
| `food-search.png` | Food search and nutrient details |
| `settings.png` | Language, appearance, and preferences |

Screenshots should use sample data rather than personal health records.

## Technology

食誌 is built with Flutter and Dart.

The project uses local application storage for diary records and supports external food-data providers for online search.

The exact dependency versions, Android requirements, and platform compatibility are defined by the project's Flutter configuration. Consult `pubspec.yaml` and the Android project files for implementation details.

## Getting started

### Requirements

- Flutter SDK compatible with the project.
- Dart SDK version required by the Flutter project.
- Android SDK and Android build tools.
- A compatible Android device or emulator.
- Internet access for online food searches.

### Run from source

Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/shiyokushi.git
cd shiyokushi
```

Install dependencies:

```bash
flutter pub get
```

Check the development environment:

```bash
flutter doctor
```

Run the application on a connected Android device:

```bash
flutter devices
flutter run
```

### Build a release APK

```bash
flutter build apk --release
```

The APK is normally generated at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Install it on a connected Android device using:

```bash
flutter install
```

For direct distribution, share the generated APK through a trusted channel. Android may require permission to install apps from that source.

### iOS status

The application is developed with Flutter, but an iOS build must be compiled and tested using the Apple development toolchain on macOS.

Do not assume iOS compatibility merely because the project uses Flutter. Verify all required plugins, native permissions, storage behavior, backup restoration, and signing before distributing an iOS build.

## Data sources and attribution

Food information may come from third-party databases. Their records can differ in coverage, completeness, and accuracy.

- [Open Food Facts](https://world.openfoodfacts.org/) — packaged-food database.
- [USDA FoodData Central](https://fdc.nal.usda.gov/) — food composition database.

These are independent services, not endorsements of 食誌.

Review the applicable provider terms, licenses, attribution requirements, and data-retention restrictions when distributing the application or modifying its data integrations.

## Known limitations

The current version has several deliberate limitations:

- Food searches require internet access.
- A search result may not exactly match the food, brand, recipe, or preparation method consumed.
- Nutrient values may be incomplete or inaccurate.
- Country selection does not guarantee official national nutrition data.
- Food photos are stored with entries but are not analyzed by an AI model.
- Portion weights must be supplied or otherwise determined by the user; the app does not automatically measure them from photographs.
- The live local database is not separately encrypted.
- Exported backups require their generated key for restoration.
- Importing a backup replaces existing diary records and should be preceded by a separate export.
- Calorie requirements, BMI, and goal projections are estimates and are not medical advice.
- iOS availability requires a separate platform build and validation process.

## Privacy and responsible use

食誌 is intended for personal food journaling and wellness tracking.

It does not diagnose, prevent, or treat disease. Calorie estimates, nutrition values, BMI, and weight projections should not be treated as precise measurements or medical recommendations.

Consult a qualified healthcare professional for medical concerns or individualized dietary guidance.

## Contributing

食誌 is currently developed as a personal project.

If the repository is made public and contributions are welcome, please open an issue to discuss substantial changes before submitting a pull request.

When contributing:

- Keep personal data out of test fixtures and commits.
- Never commit API secrets or signing credentials.
- Preserve the local-first privacy model unless a change is explicitly documented.
- Include tests for changes to nutrition calculations and backup behavior.
- Document any new external data transmission.
- Respect the terms and licenses of external data sources.

## License

No license has been specified yet.

If this project is published publicly, add a `LICENSE` file stating how others may use, modify, and distribute the code. Until a license is selected, do not assume that public visibility grants permission to reuse the project.

## A note from the developer

食誌 is a personal project built around a simple idea: tracking what you eat should be useful, understandable, and under your control.

The goal is not to make nutrition feel like a competition or to pretend that every calorie can be measured perfectly. It is to provide a practical journal for learning from your own habits over time.

**食誌 — your food, your record, your pace.**

