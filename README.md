# 食誌 ShyokuShi 🍃

### A quiet space for your daily food journal.

<p align="center">
  <img src="assets/shiyokushi_logo.svg" alt="食誌 ShyokuShi logo" width="180">
</p>

<p align="center">
  <strong>Eat mindfully. Track honestly. Keep your data yours.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-Framework-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white" alt="Android">
  <img src="https://img.shields.io/badge/Storage-Local--first-4A6741" alt="Local-first">
  <img src="https://img.shields.io/badge/Privacy-No%20account%20required-6B8E72" alt="No account required">
  <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="MIT License">
</p>

---

## 🌿 About

**食誌 (ShyokuShi)** is a personal food diary and nutrition tracker built with Flutter and Dart.

Record what you eat, explore nutritional estimates, plan upcoming meals, and track your weight history—all in one calm, personal space.

ShyokuShi is designed around a simple idea: understanding your eating habits should be useful, approachable, and respectful of your privacy.

## ✨ Features

### 🏠 Daily dashboard
- View calories consumed against your estimated daily target.
- Track protein, carbohydrates, and fat.
- Explore calorie history by week, month, quarter, or year.
- Review period totals and daily averages.

### 🍱 Food diary
- Record multiple foods in each meal.
- Enter quantities in grams and nutritional values.
- Add optional meal photos and notes.
- Browse previous days and review your meals.
- Edit or delete diary entries.

### 🔎 Food search
- Search supported food databases.
- Review available nutrition information.
- Enter food and nutrient values manually when needed.
- Choose a regional food-reference preference for Japan, the United States, Canada, the United Kingdom, South Korea, China, or Other.

**Supported food-data providers:**
- [Open Food Facts](https://world.openfoodfacts.org/)
- [USDA FoodData Central](https://fdc.nal.usda.gov/)

Food records can be incomplete or inaccurate. Check packaging and product information when possible.

### 📅 Meal planner
- Plan foods before recording them as eaten.
- Preview projected daily calorie intake.
- Combine logged and planned food in your forecast.
- Mark planned entries as eaten when appropriate.

### 📈 Weight and progress tracking
- Record body-weight measurements.
- Review historical changes.
- View progress over your recorded date range.
- Calculate BMI when sufficient profile information is available.

### 🎯 Personal goals
- Configure your profile and activity level.
- Choose weight loss, weight gain, or maintenance goals.
- Review estimated daily calorie needs.
- Set a target weight and date.
- Receive warnings about targets that may be unrealistic.

Calorie and weight projections are estimates, not medical advice.

### 🎨 Personalization
- English, Japanese, Chinese, and Korean interface options.
- Light, dark, and system appearance modes.
- Custom display name.
- A clean interface featuring the 食誌 branding.

### 🔐 Encrypted backups
- Export your records to an encrypted backup.
- Restore supported encrypted backups using the generated key.
- Import supported legacy JSON backups.
- Preserve available diary, profile, preference, weight-history, and meal-photo data in supported exports.

**Important:** Keep your backup key safe. Importing a backup replaces existing records, so export your current data first.

---

## 📱 Screenshots

Take a look inside ShyokuShi.

<p align="center">
  <img src="assets/screenshots/home.png" width="240" alt="ShyokuShi daily dashboard">
  &nbsp;&nbsp;
  <img src="assets/screenshots/diary.png" width="240" alt="ShyokuShi food diary">
  &nbsp;&nbsp;
  <img src="assets/screenshots/planner.png" width="240" alt="ShyokuShi meal planner">
</p>

<p align="center">
  <img src="assets/screenshots/progress.png" width="240" alt="ShyokuShi weight progress">
  &nbsp;&nbsp;
  <img src="assets/screenshots/food-search.png" width="240" alt="ShyokuShi food search">
  &nbsp;&nbsp;
  <img src="assets/screenshots/settings.png" width="240" alt="ShyokuShi settings">
</p>

<sub>📸 Screenshots should be saved in <code>assets/screenshots/</code> using the filenames shown above. Remove any image references for screenshots you have not added yet.</sub>

---

## 🔒 Privacy first

ShyokuShi follows a **local-first approach** to personal food journaling.

| Privacy feature | Current behavior |
|---|---|
| Account required | No |
| Diary and profile storage | Local on your device |
| Food photos | Stored locally |
| Cloud diary synchronization | Not implemented |
| Advertising and analytics | None in this version |
| Online food search | Queries are sent to the selected food-data provider |
| AI food-photo recognition | Not implemented |
| Live database encryption | Not separately encrypted |
| Exported backups | Encrypted; require the generated key to restore |

### 🛡️ What this means

- Your diary, profile, and photos are not sent as part of food-search requests.
- Food searches require an internet connection and transmit search terms to the relevant external provider.
- The live application database is **not separately encrypted**. Protect your device and keep exported backups secure.
- Backup encryption protects the exported copy; it does not encrypt the live database.

For more details, consult the privacy notice and terms available in the application.

---

## 🛠️ Built with

- **[Flutter](https://flutter.dev/)** — cross-platform application framework.
- **[Dart](https://dart.dev/)** — application programming language.
- **[Open Food Facts](https://world.openfoodfacts.org/)** — packaged-food information.
- **[USDA FoodData Central](https://fdc.nal.usda.gov/)** — food composition data.

Food-data providers are independent services and do not endorse ShyokuShi. Their data may vary in coverage, completeness, and accuracy. Review their applicable terms and attribution requirements when distributing the application.

---

## 🚀 Getting started

### Prerequisites

Make sure you have installed:

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Dart SDK compatible with your Flutter version
- Android SDK and build tools
- Android device or emulator
- Git

Internet access is needed for online food searches.

### 1. Clone the repository

Replace `YOUR_USERNAME` with your GitHub username.

```bash
git clone https://github.com/YOUR_USERNAME/shiyokushi.git
cd shiyokushi
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Check your development environment

```bash
flutter doctor
```

### 4. Run the application

Connect an Android device or start an emulator.

```bash
flutter devices
flutter run
```

### 📦 Build a release APK

```bash
flutter build apk --release
```

The generated APK is normally located at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

To install the release build on a connected device, use:

```bash
flutter install
```

Android may require permission to install APKs from your chosen source.

### 🍎 iOS status

The project uses Flutter, but building and validating an iOS release requires macOS and Apple's development toolchain. iOS compatibility should not be assumed until the application and its plugins have been tested on that platform.

---

## ⚠️ Current limitations

- Food searches require internet access.
- Food database results may not exactly match the food or preparation method consumed.
- Nutrition values depend on the information available or entered.
- Country preferences do not guarantee official national nutrition data.
- Food photos are not analyzed by an AI model.
- The application does not automatically estimate food portions from photographs.
- The live local database is not separately encrypted.
- Lost backup keys cannot be recovered by the application.
- Importing a backup replaces existing records.
- Calorie needs, BMI, and weight projections are estimates, not medical assessments.
- iOS requires a separate build and validation process.

---

## 🩺 Responsible use

ShyokuShi is a personal tracking and wellness tool. It does not diagnose, prevent, or treat medical conditions and is not a substitute for professional healthcare or individualized nutrition advice.

Nutrition estimates and progress charts should be interpreted with care. Consult a qualified healthcare professional for medical concerns or personalized dietary guidance.

---

## 🤝 Contributing

ShyokuShi is currently a personal project. Contributions and constructive feedback are welcome if the repository is open to community participation.

Before submitting a substantial change, consider opening an issue to discuss the proposed improvement.

Please help maintain the project's quality and privacy principles:

- 🧪 Add tests for nutrition calculations and backup behavior.
- 🔐 Never commit passwords, API secrets, signing keys, or personal backups.
- 🧹 Keep personal health records out of screenshots, test fixtures, and commits.
- 📝 Document new external data transmissions.
- 🌱 Preserve the local-first approach unless a change is explicitly documented.
- 📚 Respect third-party data terms and licenses.

---

## 📄 License

ShyokuShi is licensed under the **MIT License**. See the [`LICENSE`](LICENSE) file for the complete license text.

The MIT License permits use, copying, modification, merging, publishing, distribution, sublicensing, and sale of copies of the software, subject to its conditions, including preservation of the copyright and permission notice.

The software is provided **"as is"**, without warranty, as described in the license.

The MIT license for this repository does not automatically grant rights to third-party trademarks, data, or assets that may have separate license terms.

---

## 🍃 A note from the developer

ShyokuShi was built around a simple belief: tracking what you eat should help you understand your habits, not make food feel like a competition.

It is a personal journal for noticing patterns, learning over time, and making informed choices at your own pace.

**食誌 — your food, your record, your pace.** 🌿
