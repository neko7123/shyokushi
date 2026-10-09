import 'dart:convert';

class Nutrition {
  const Nutrition({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.sugar = 0,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;

  Nutrition operator +(Nutrition other) => Nutrition(
    calories: calories + other.calories,
    protein: protein + other.protein,
    carbs: carbs + other.carbs,
    fat: fat + other.fat,
    fiber: fiber + other.fiber,
    sugar: sugar + other.sugar,
  );

  Nutrition operator *(double factor) => Nutrition(
    calories: calories * factor,
    protein: protein * factor,
    carbs: carbs * factor,
    fat: fat * factor,
    fiber: fiber * factor,
    sugar: sugar * factor,
  );

  Map<String, dynamic> toMap() => {
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'fiber': fiber,
    'sugar': sugar,
  };

  factory Nutrition.fromMap(Map<String, dynamic> map) => Nutrition(
    calories: _asDouble(map['calories']),
    protein: _asDouble(map['protein']),
    carbs: _asDouble(map['carbs']),
    fat: _asDouble(map['fat']),
    fiber: _asDouble(map['fiber']),
    sugar: _asDouble(map['sugar']),
  );

  static double _asDouble(dynamic value) => value is num ? value.toDouble() : 0;
}

class FoodCandidate {
  const FoodCandidate({
    required this.name,
    required this.nutritionPer100g,
    required this.source,
    this.brand,
    this.barcode,
    this.referenceId,
    this.dataQuality = 'unknown',
    this.missingNutrients = const {},
  });

  final String name;
  final Nutrition nutritionPer100g;
  final String source;
  final String? brand;
  final String? barcode;
  final String? referenceId;
  final String dataQuality;
  final Set<String> missingNutrients;
}

class FoodEntry {
  const FoodEntry({
    required this.id,
    required this.loggedAt,
    required this.name,
    required this.meal,
    required this.grams,
    required this.nutritionPer100g,
    required this.source,
    this.mealId,
    this.referenceId,
    this.photoPath,
    this.notes = '',
    this.isPlanned = false,
  });

  final String id;
  final DateTime loggedAt;
  final String name;
  final String meal;
  final double grams;
  final Nutrition nutritionPer100g;
  final String source;
  final String? mealId;
  final String? referenceId;
  final String? photoPath;
  final String notes;
  final bool isPlanned;

  Nutrition get nutrition => nutritionPer100g * (grams / 100);

  Map<String, dynamic> toMap() => {
    'id': id,
    'loggedAt': loggedAt.toIso8601String(),
    'name': name,
    'meal': meal,
    'grams': grams,
    'calories100g': nutritionPer100g.calories,
    'protein100g': nutritionPer100g.protein,
    'carbs100g': nutritionPer100g.carbs,
    'fat100g': nutritionPer100g.fat,
    'fiber100g': nutritionPer100g.fiber,
    'sugar100g': nutritionPer100g.sugar,
    'source': source,
    'mealId': mealId,
    'referenceId': referenceId,
    'photoPath': photoPath,
    'notes': notes,
    'isPlanned': isPlanned ? 1 : 0,
  };

  factory FoodEntry.fromMap(Map<String, dynamic> map) => FoodEntry(
    id: map['id'] as String,
    loggedAt: DateTime.tryParse('${map['loggedAt']}') ?? DateTime.now(),
    name: '${map['name'] ?? 'Food'}',
    meal: '${map['meal'] ?? 'Snack'}',
    grams: _d(map['grams']),
    nutritionPer100g: Nutrition(
      calories: _d(map['calories100g']),
      protein: _d(map['protein100g']),
      carbs: _d(map['carbs100g']),
      fat: _d(map['fat100g']),
      fiber: _d(map['fiber100g']),
      sugar: _d(map['sugar100g']),
    ),
    source: '${map['source'] ?? 'Manual'}',
    mealId: map['mealId'] as String?,
    referenceId: map['referenceId'] as String?,
    photoPath: map['photoPath'] as String?,
    notes: '${map['notes'] ?? ''}',
    isPlanned: map['isPlanned'] == 1 || map['isPlanned'] == true,
  );

  static double _d(dynamic v) => v is num ? v.toDouble() : 0;
}

class WeightLog {
  const WeightLog({
    required this.id,
    required this.loggedAt,
    required this.kg,
    this.notes = '',
  });
  final String id;
  final DateTime loggedAt;
  final double kg;
  final String notes;

  Map<String, dynamic> toMap() => {
    'id': id,
    'loggedAt': loggedAt.toIso8601String(),
    'kg': kg,
    'notes': notes,
  };

  factory WeightLog.fromMap(Map<String, dynamic> m) => WeightLog(
    id: '${m['id']}',
    loggedAt: DateTime.tryParse('${m['loggedAt']}') ?? DateTime.now(),
    kg: m['kg'] is num ? (m['kg'] as num).toDouble() : 0,
    notes: '${m['notes'] ?? ''}',
  );
}

class UserProfile {
  const UserProfile({
    this.age = 28,
    this.sex = 'male',
    this.heightCm = 172,
    this.weightKg = 70,
    this.activity = 'moderate',
    this.goalType = 'maintain',
    this.targetWeightKg = 70,
    this.targetDate,
  });

  final int age;
  final String sex;
  final double heightCm;
  final double weightKg;
  final String activity;
  final String goalType;
  final double targetWeightKg;
  final DateTime? targetDate;

  UserProfile copyWith({
    int? age,
    String? sex,
    double? heightCm,
    double? weightKg,
    String? activity,
    String? goalType,
    double? targetWeightKg,
    DateTime? targetDate,
  }) => UserProfile(
    age: age ?? this.age,
    sex: sex ?? this.sex,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    activity: activity ?? this.activity,
    goalType: goalType ?? this.goalType,
    targetWeightKg: targetWeightKg ?? this.targetWeightKg,
    targetDate: targetDate ?? this.targetDate,
  );

  Map<String, dynamic> toMap() => {
    'age': age,
    'sex': sex,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'activity': activity,
    'goalType': goalType,
    'targetWeightKg': targetWeightKg,
    'targetDate': targetDate?.toIso8601String(),
  };

  factory UserProfile.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return UserProfile(
        targetDate: DateTime.now().add(const Duration(days: 90)),
      );
    }
    return UserProfile(
      age: (map['age'] as num?)?.toInt() ?? 28,
      sex: '${map['sex'] ?? 'male'}',
      heightCm: _d(map['heightCm'], 172),
      weightKg: _d(map['weightKg'], 70),
      activity: '${map['activity'] ?? 'moderate'}',
      goalType: '${map['goalType'] ?? 'maintain'}',
      targetWeightKg: _d(map['targetWeightKg'], 70),
      targetDate:
          DateTime.tryParse('${map['targetDate'] ?? ''}') ??
          DateTime.now().add(const Duration(days: 90)),
    );
  }

  static double _d(dynamic value, double fallback) =>
      value is num ? value.toDouble() : fallback;
}

class GoalAssessment {
  const GoalAssessment({
    required this.bmr,
    required this.tdee,
    required this.dailyTarget,
    required this.weeklyChangeKg,
    required this.isPlausible,
    required this.message,
    required this.daysToGoal,
  });
  final double bmr;
  final double tdee;
  final double dailyTarget;
  final double weeklyChangeKg;
  final bool isPlausible;
  final String message;
  final int daysToGoal;
}

String prettyJson(Object? value) =>
    const JsonEncoder.withIndent('  ').convert(value);
