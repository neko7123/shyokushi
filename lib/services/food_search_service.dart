import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/nutrition.dart';

/// Network is used only for user-initiated food searches. Diary records remain on-device.
class FoodSearchService {
  FoodSearchService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  String countryCode = 'JP';
  static const _usdaKey = String.fromEnvironment(
    'USDA_API_KEY',
    defaultValue: 'DEMO_KEY',
  );

  Future<List<FoodCandidate>> search(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.length < 2) return [];
    final futures = <Future<List<FoodCandidate>>>[
      _searchOpenFoodFacts(query),
      _searchUsda(query),
    ];
    final settled = await Future.wait(
      futures.map((f) async {
        try {
          return await f;
        } catch (_) {
          return <FoodCandidate>[];
        }
      }),
    );
    final results = settled.expand((r) => r).toList();
    final seen = <String>{};
    return results
        .where((food) {
          final key = '${food.name.toLowerCase()}|${food.source}';
          return seen.add(key);
        })
        .take(30)
        .toList();
  }

  Future<List<FoodCandidate>> _searchOpenFoodFacts(String query) async {
    final subdomain =
        const {
          'JP': 'jp',
          'US': 'us',
          'CA': 'ca',
          'GB': 'uk',
          'KR': 'kr',
          'CN': 'cn',
        }[countryCode] ??
        'world';
    List<FoodCandidate> regional = [];
    try {
      regional = await _searchOpenFoodFactsAt(subdomain, query);
    } catch (_) {
      // Keep the worldwide catalogue as a fallback when a regional host is unavailable.
    }
    if (subdomain == 'world' || regional.length >= 8) return regional;
    try {
      return [...regional, ...await _searchOpenFoodFactsAt('world', query)];
    } catch (_) {
      return regional;
    }
  }

  Future<List<FoodCandidate>> _searchOpenFoodFactsAt(
    String subdomain,
    String query,
  ) async {
    final uri = Uri.https('$subdomain.openfoodfacts.org', '/api/v2/search', {
      'search_terms': query,
      'page_size': '20',
      'fields': 'product_name,brands,code,nutriments,quantity',
    });
    final response = await _client
        .get(
          uri,
          headers: {
            'User-Agent':
                'NutriDiary/0.1 (personal offline-first nutrition diary)',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) return [];
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final products = json['products'];
    if (products is! List) return [];
    final items = <FoodCandidate>[];
    for (final item in products.whereType<Map<String, dynamic>>()) {
      final name = '${item['product_name'] ?? ''}'.trim();
      final nut = item['nutriments'];
      if (name.isEmpty || nut is! Map<String, dynamic>) continue;
      final caloriesKcal = _firstNumber(nut, ['energy-kcal_100g']);
      final energyKj = _firstNumber(nut, ['energy-kj_100g']);
      final calories =
          caloriesKcal ?? (energyKj == null ? null : energyKj / 4.184);
      if (calories == null || calories < 0) continue;
      final protein = _firstNumber(nut, ['proteins_100g']);
      final carbs = _firstNumber(nut, ['carbohydrates_100g']);
      final fat = _firstNumber(nut, ['fat_100g']);
      final fiber = _firstNumber(nut, ['fiber_100g']);
      final sugar = _firstNumber(nut, ['sugars_100g']);
      final missing = <String>{
        if (protein == null) 'protein',
        if (carbs == null) 'carbs',
        if (fat == null) 'fat',
        if (fiber == null) 'fiber',
        if (sugar == null) 'sugar',
      };
      items.add(
        FoodCandidate(
          name: name,
          brand:
              '${item['brands'] ?? ''}'.trim().isEmpty
                  ? null
                  : '${item['brands']}',
          barcode:
              '${item['code'] ?? ''}'.trim().isEmpty ? null : '${item['code']}',
          referenceId:
              '${item['code'] ?? ''}'.trim().isEmpty ? null : '${item['code']}',
          nutritionPer100g: Nutrition(
            calories: calories,
            protein: protein ?? 0,
            carbs: carbs ?? 0,
            fat: fat ?? 0,
            fiber: fiber ?? 0,
            sugar: sugar ?? 0,
          ),
          source: 'Open Food Facts',
          dataQuality:
              missing.isEmpty
                  ? 'Community-reported; verify label when accuracy matters'
                  : 'Missing fields: ${missing.join(', ')}. Enter a value for each before saving.',
          missingNutrients: missing,
        ),
      );
    }
    return items;
  }

  Future<List<FoodCandidate>> _searchUsda(String query) async {
    final uri = Uri.https('api.nal.usda.gov', '/fdc/v1/foods/search', {
      'api_key': _usdaKey,
      'query': query,
      'pageSize': '15',
    });
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) return [];
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final foods = json['foods'];
    if (foods is! List) return [];
    final items = <FoodCandidate>[];
    for (final food in foods.whereType<Map<String, dynamic>>()) {
      final name = '${food['description'] ?? ''}'.trim();
      final nutrients = food['foodNutrients'];
      if (name.isEmpty || nutrients is! List) continue;
      double? findNutrient(List<int> ids, List<String> labels) {
        for (final raw in nutrients.whereType<Map<String, dynamic>>()) {
          final id = raw['nutrientId'] ?? raw[' nutrientId'];
          final n = raw['nutrientName']?.toString().toLowerCase() ?? '';
          if ((id is num && ids.contains(id.toInt())) ||
              labels.any(n.contains)) {
            final v = raw['value'];
            if (v is num) return v.toDouble();
          }
        }
        return null;
      }

      final energy = findNutrient([1008], ['energy']);
      if (energy == null || energy < 0) continue;
      final protein = findNutrient([1003], ['protein']);
      final carbs = findNutrient([1005], ['carbohydrate, by difference']);
      final fat = findNutrient([1004], ['total lipid (fat)']);
      final fiber = findNutrient([1079], ['fiber, total dietary']);
      final sugar = findNutrient([2000], ['sugars, total']);
      final missing = <String>{
        if (protein == null) 'protein',
        if (carbs == null) 'carbs',
        if (fat == null) 'fat',
        if (fiber == null) 'fiber',
        if (sugar == null) 'sugar',
      };
      items.add(
        FoodCandidate(
          name: name,
          nutritionPer100g: Nutrition(
            calories: energy,
            protein: protein ?? 0,
            carbs: carbs ?? 0,
            fat: fat ?? 0,
            fiber: fiber ?? 0,
            sugar: sugar ?? 0,
          ),
          source: 'USDA FoodData Central',
          referenceId:
              '${food['fdcId'] ?? ''}'.trim().isEmpty
                  ? null
                  : '${food['fdcId']}',
          dataQuality:
              missing.isEmpty
                  ? 'FoodData Central entry; confirm food state and serving basis'
                  : 'Missing fields: ${missing.join(', ')}. Enter a value for each before saving.',
          missingNutrients: missing,
        ),
      );
    }
    return items;
  }

  double? _firstNumber(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final v = map[key];
      if (v is num) return v.toDouble();
      if (v is String) {
        final parsed = double.tryParse(v);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }
}
