# Product & engineering review — Nutri Diary

**Prepared:** 9 October 2026  
**Target:** personal-use app, Flutter on Android and iOS, local-first storage  
**Status:** starter implementation, not a clinically validated health product

## Executive review

The product concept is viable if the core promise is reframed from “a photo accurately tells me everything I ate” to “a fast, editable nutrition diary that combines trusted composition data, measured portions, meal planning and progressively better photo assistance.” The calorie calculation is mostly straightforward once food identity, preparation state, recipe composition and edible weight are known. Those inputs are the hard part.

No single public database covers every branded product, household recipe, regional dish, restaurant serving and preparation method worldwide. A food label/database lookup can often handle packaged products; generic composition tables handle ingredients; recipes must be calculated from their ingredients; a photo model can suggest likely visible foods but often cannot infer hidden oil, sauce, sugar, broth composition, density, or precise grams. The app should never silently convert a low-confidence image guess into a “measured” nutrition fact.

**Recommended product principle:** optimize for *honest, fast correction*. Show the source, preparation state, amount, and confidence; make changing the portion or ingredients quicker than starting over.

## Recommended navigation

Five bottom tabs are enough for the first release. Avoid a large dashboard with every metric and avoid adding an AI-chat tab before the underlying log is trustworthy.

| Tab | Job | Core contents |
|---|---|---|
| **Today** | Answer “where am I versus today's plan?” | Calories eaten/remaining, macros, goal target, today's meals, quick add |
| **Diary** | Accurate historical record | Day picker, breakfast/lunch/dinner/snack groups, entry edit/delete, attached photos and notes |
| **Plan** | Answer “if I eat this tonight, where will I end up?” | Planned items, actual + planned forecast, remaining/over target, edit or mark as eaten |
| **Progress** | Evaluate trends instead of reacting to daily noise | Weight log, weekly average, goal pace, calorie/protein adherence and later waist/training metrics |
| **Settings** | Own the profile and data | Profile/activity, goal/deadline, units, data providers/privacy, export/import, attribution and about |

### Modal/screen flows, not bottom tabs

- **Add food:** search, recent/favourite, barcode, take/select photo, create recipe, manual entry.
- **Review food:** name candidate, cooked/raw state, amount in grams or household unit, nutrition source, editable ingredient list, confidence warnings.
- **Profile setup:** age (adult gate), height, current weight, sex/equation preference, activity, goal and date.
- **Recipe editor:** ingredient weights, cooking method, total finished yield and number of servings.

A settings entry should explain local storage vs network activity. “Local only” and “uses an API” are compatible only when stated precisely: diary data can remain local while an explicit food-search request sends a query string to a provider. Sending a photo or profile to remote AI would be a separate privacy decision.

## Food data strategy

Use a provider adapter so the app is not tightly coupled to any one service. Record the source and source ID on each selected food; store the nutrition snapshot used at the time of logging so an upstream data update does not silently rewrite a person's history.

### 1. USDA FoodData Central — primary generic composition source

The FDC REST API supports searching and retrieving food details. The data types include Foundation Foods, FNDDS, branded foods and legacy records. USDA lists the data as public domain under CC0 and asks for attribution; its API guide says an API key is required and describes a default limit of 1,000 requests per hour per IP. This is a strong first source for ordinary ingredients and many US-labeled products, but it is not a universal world-food catalogue. Food preparation and record type need to be checked for every result.

- [API guide and licensing](https://fdc.nal.usda.gov/api-guide/)
- [Data type documentation](https://fdc.nal.usda.gov/data-documentation/)

**Implementation note:** a key compiled into a Flutter client is not secret. A personal build can use `--dart-define`, but a shared or public build should not rely on client-side secrecy; use a controlled backend or a distribution model with appropriately managed credentials. API availability also means food search cannot work offline unless the app has already stored a local result or a curated dataset.

### 2. Open Food Facts — packaged and barcode foods

Open Food Facts is useful as an international, community-maintained source of packaged-food labels and barcode-linked products. It is not a guaranteed-complete ingredient composition table. Coverage and data quality vary by country, product, language and contributor. Missing nutrient values should be represented as *unknown*, not as zero. A barcode hit may represent a product variant or serving basis that still requires review.

- [Search API reference](https://openfoodfacts.github.io/documentation/docs/Product-Opener/v2/search/get-search/)
- [Licensing and reuse](https://openfoodfacts.github.io/openfoodfacts-server/api/tutorials/license-be-on-the-legal-side/)
- [ODbL summary](https://opendatacommons.org/licenses/odbl/summary/)

**License caution:** Open Food Facts describes separate terms for the database, its individual contents, and product images. If a future version bundles or redistributes derived catalogue data, evaluate the ODbL attribution/share-alike implications before doing so. This personal prototype only queries the service; it does not bundle their full database.

### 3. Country/region-specific composition tables

Regional tables matter if “world foods” is an actual product requirement. Examples include the [Japanese Standard Tables of Food Composition](https://www.mext.go.jp/a_menu/syokuhinseibun/mext_01110.html), UK [Composition of Foods Integrated Dataset](https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid), and French [Ciqual](https://ciqual.anses.fr/). Do not assume all tables share a license, serving convention, energy calculation method, language or update cadence. Review each source's data license, schema, provenance and update process before bundling it.

### 4. Text/recipe parsing providers

Edamam offers food search, natural-language food logging and recipe nutrition analysis. Its own docs describe ingredient/measure extraction, cooking-related adjustments for certain recipes, and a beta image-to-nutrition endpoint. But its API plans have pricing, required attribution and caching/reuse limits; its nutrition API page explicitly restricts what some plans may cache. This makes it a possible optional remote provider, not a safe foundation for a wholly offline catalogue without checking the exact commercial terms.

- [Food Database API](https://developer.edamam.com/food-database-api-docs)
- [Nutrition Analysis API](https://developer.edamam.com/edamam-docs-nutrition-api)
- [Plans and caching terms](https://developer.edamam.com/edamam-nutrition-api)

Nutritionix also exposes natural-language food analysis, but API access and permitted usage should be reviewed at integration time rather than assumed to be a free personal endpoint: [Natural API docs](https://github.com/nutritionix/api-documentation/blob/master/v2/natural.md).

### Comparison and decision

| Option | Strongest use | Offline suitability | Main risk/trade-off | Recommendation |
|---|---|---|---|---|
| FoodData Central | Generic ingredients and some branded products | Good if a permitted local subset/snapshot is imported | API key for hosted lookup; US-centric gaps and preparation mismatches | First generic data source; cache selected nutrition snapshots |
| Open Food Facts | Packaged foods and barcodes across markets | Good if selected records are stored; whole-database bundling needs license review | Variable completeness and community-entered values; ODbL duties | Keep for online search/barcode and show provenance |
| Regional composition tables | Local cuisines and ingredient names | Potentially excellent if terms permit bundling | Different licenses, data conventions and schemas | Add by locale after license review |
| Edamam or similar NLP service | Ingredient parsing, natural-language quantities, recipe estimates | Poor unless terms explicitly permit retained data and local copy | Paid plans, attribution, caching, data-sharing | Optional later; don't make core logging depend on it |
| Hand-curated local foods | Favourite meals and personal accuracy | Excellent | Requires maintenance; limited breadth | Build a local favourites/recipes catalogue early |

### Data-model requirements

Every food record should eventually hold:

- `sourceProvider`, `sourceId`, `sourceVersion`/`retrievedAt`, attribution/license metadata;
- canonical name, display/localized names, brand/barcode when present;
- raw/cooked/prepared state and edible portion basis;
- nutrient values **and a field-level known/missing flag** rather than treating absent values as zero;
- quantity/measure conversions with source provenance;
- confidence or quality flags, plus user overrides;
- a nutrition snapshot copied into each diary entry at log time.

The starter omits search results with no positive energy value, but maps absent macro fields to zero for display/entry convenience; that is a known simplification that must be replaced by nullable nutrient fields before claiming robust data quality.

## Food photo recognition: realistic design

### Why the single-photo premise fails

A photo can support recognition of visible food categories, but it does not directly reveal weight. Two bowls of ramen can look similar yet differ substantially because of noodle quantity, broth, oil, chashu, egg, toppings and how much broth is consumed. Rice photographs have depth/scale ambiguity. Curries, stews, mixed rice, sauces and foods under other foods are especially hard. Perspective, lighting, occlusion, plate size and camera angle further alter apparent amount. Food labels and user confirmation are still needed.

Systematic reviews of image-based dietary assessment and portion-size estimation document variable validity, a limited number of high-quality validation studies, and meaningful variation by tool and population. Photo atlases can improve estimates in some contexts, but user-level estimates still vary; recent reviews particularly flag amorphous foods and liquids as harder cases.

- [Systematic review: portion-size estimation tools](https://pubmed.ncbi.nlm.nih.gov/31999347/)
- [Systematic review/meta-analysis: image-based dietary assessment validity](https://pubmed.ncbi.nlm.nih.gov/32839035/)
- [Systematic review: food-recognition systems in dietary assessment](https://pubmed.ncbi.nlm.nih.gov/35803496/)
- [2026 scoping review: food atlases as portion aids](https://pubmed.ncbi.nlm.nih.gov/41533754/)

### Recommended user flow

1. User takes a pre-meal photo (pre/post photos are even better when estimating intake rather than what was served).
2. A model offers several food/ingredient hypotheses, not a final nutrient claim.
3. User confirms the dish and ingredients, including preparation (fried/boiled, sauce, oil, toppings, broth consumed).
4. App asks for quantity with fast controls: grams, number of pieces, cup/bowl and a visually calibrated portion guide. Ask the user to confirm grams when accuracy matters.
5. Recipe/food engine calculates nutrients using source-labelled values.
6. UI displays estimate ranges or a confidence label when weight/ingredients are uncertain; user can correct it.
7. Save the selected data snapshot and corrections. Corrections become opt-in training/analytics data only if privacy is explicitly addressed.

### On-device AI vs remote AI

If keeping the app genuinely local-only is non-negotiable, investigate an on-device image classifier/segmentation model and keep candidate labels + selected food data local. But model inference being on-device does not solve portion-weight estimation or regional coverage. A future remote multimodal model could offer better flexible interpretation, but the user must explicitly opt in because sending an image to an API is no longer local-only. Keep the AI provider behind a clean interface so it can be switched off or replaced.

**Do not market any image estimate as exact.** The safest useful wording is “estimated; review ingredients and portion.”

## Calorie and goal algorithms

### Baseline energy estimate

The starter implements the Mifflin–St Jeor equation to estimate resting energy expenditure:

- Common male equation: `10 × kg + 6.25 × cm − 5 × age + 5`
- Common female equation: `10 × kg + 6.25 × cm − 5 × age − 161`
- The UI's “other / midpoint” uses an arithmetic midpoint for an estimate; it is not a distinct validated equation.

It multiplies this resting estimate by a user-selected activity factor to estimate total daily energy expenditure (TDEE). These values are estimates, not measurements. The user should compare the estimate with at least a few weeks of tracked intake and weight trends and adjust carefully.

For planning, the starter uses a simplified static approximation of about 7,700 kcal per kg body-weight change. This is intentionally a first-pass heuristic; it does **not** model the body's dynamic adaptation over time. NIDDK's Body Weight Planner exists because weight response over time is more complicated than a fixed calorie-to-weight conversion.

- [NIDDK Body Weight Planner](https://www.niddk.nih.gov/health-information/weight-management/body-weight-planner)
- [CDC gradual weight-loss guidance](https://www.cdc.gov/healthy-weight-growth/losing-weight/)
- [NHS healthy weight-gain guidance](https://www.nhs.uk/live-well/healthy-weight/managing-your-weight/healthy-ways-to-gain-weight/)

### Goal feasibility guardrails

The starter rejects deadlines where the implied weekly rate exceeds a conservative, explicit heuristic: up to 1% of current body weight per week for loss (also capped at 0.68 kg/week) and 0.5% per week for gain (also capped at 0.45 kg/week). It also rejects a goal date in the past and a target weight in the wrong direction. These are product guardrails—not official universal medical limits. A future version should present a range of feasible dates/intakes, not merely reject the user, and should have stronger special-population handling.

The starter caps calorie adjustments to avoid extreme numeric recommendations and warns if the calculated target is unusually low. This still is not a personalized clinical prescription. Before any public release, define supported ages and exclusions; avoid prescribing targets for minors, pregnancy/breastfeeding, relevant medical conditions, eating-disorder risk, or medically supervised nutrition goals. In these cases route to a clinician rather than optimizing a timeline.

### Muscle gain is a separate layer

Weight gain is not synonymous with muscle gain. To represent a muscle-building goal responsibly, the product will eventually need resistance-training context, protein targets, recovery and body-composition caveats. The ISSN position stand reports that 1.4–2.0 g protein/kg/day is sufficient for most exercising individuals, but protein targets should not be presented as universally appropriate for every medical circumstance.

- [ISSN protein and exercise position stand (2017)](https://pubmed.ncbi.nlm.nih.gov/28642676/)

For a first release, expose protein totals and a user-editable target as a tracker, not a promise to predict kilograms of muscle gained.

## Offline-first Flutter architecture

The starter follows the broad offline-first direction recommended by Flutter: local data is the source of truth for the diary, and remote requests add food candidates when the user explicitly searches.

- **Presentation:** Flutter Material 3 screens and forms.
- **Domain:** immutable models, nutrition scaling, goal math and feasibility checks.
- **Local data:** SQLite via `sqflite`; tables for `food_entries`, `weight_logs` and `app_meta`.
- **Food provider layer:** `FoodSearchService` calls Open Food Facts and optionally USDA; future provider interfaces can add local search and recipe parsing.
- **Media:** photos are copied to app documents storage and referenced from entries.
- **Backup:** versioned JSON with metadata, entry/weight records and embedded photo bytes; import validates format then replaces the database in a transaction.

- [Flutter offline-first architecture guidance](https://docs.flutter.dev/app-architecture/design-patterns/offline-first)
- [sqflite plugin](https://pub.dev/packages/sqflite)
- [image_picker](https://pub.dev/packages/image_picker)
- [file_picker](https://pub.dev/packages/file_picker)

### Gaps to address next

1. Replace the UI-heavy file with feature modules and repositories as behavior grows.
2. Add a true `Food` table and local FTS/search index, plus recent foods, favourites, custom foods and reusable recipes.
3. Make all nutrient fields nullable/known-aware; current starter treats missing data as zero, which is not robust enough for authoritative nutrition logging.
4. Add migrations, schema version tests, duplicate/invalid backup handling, large-photo backup tests and restore rollback tests.
5. Encrypt sensitive local profile/diary storage if the personal threat model requires it; at minimum, ensure backups are stored deliberately and explain that JSON backups are not encrypted by default.
6. Avoid embedding an API key in a public client. Add request timeouts, rate-limit handling, provider status, attribution and optional offline search.
7. Add a `MealRecipe`/`RecipeIngredient` model and compute servings from raw ingredients plus final cooked yield, accounting for water gain/loss. Do not double-count oil or sauce.
8. Add unit conversion with canonical gram weights for the user's locale. A “bowl”, “piece” or “one package” is not a universal mass.
9. Add automated coverage for goal-direction errors, dates, under-18 profiles, calorie lower-bound warnings, kcal/macronutrient aggregation, missing nutrients and importing malformed files.
10. Add device-level tests for Android and iOS camera/library permissions, migration behavior, share sheet, file picker and photo persistence.

## MVP acceptance criteria

- A user can log food in under 20 seconds from recent/favourite/search/manual paths.
- An entry shows amount, preparation notes, source and nutrients; changing grams immediately recalculates totals.
- Planned food never counts as eaten until the user marks it eaten.
- Today's totals are reproducible from stored entry snapshots, independent of API availability.
- Implausible dates/rates do not receive a confident calorie target.
- Export → clear/reinstall → import restores log history, profile, weight measurements and attached photos, including a valid backup with zero food entries.
- Airplane mode supports opening history, adding manual foods, goal calculations, weight logs and export; only online search is unavailable.
- Privacy copy explicitly distinguishes local storage, online search requests, and any later AI opt-in.

## Decision

Proceed with the Flutter/local SQLite foundation. Do not spend early effort on “support every food in the world” or automatic image calories. First make the data model, manual correction, recipe math, local persistence, backup restoration and trend-driven goal adjustment trustworthy. Broaden food coverage with regional sources and AI assistance after that foundation is measurable and stable.
