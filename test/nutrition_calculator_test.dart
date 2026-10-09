import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_diary/models/nutrition.dart';
import 'package:nutri_diary/services/nutrition_calculator.dart';

void main() {
  group('NutritionCalculator', () {
    test('scales nutrients by portion weight', () {
      final food = FoodEntry(
        id: 'test',
        loggedAt: DateTime(2026, 1, 1),
        name: 'Rice',
        meal: 'Lunch',
        grams: 150,
        nutritionPer100g: const Nutrition(
          calories: 130,
          protein: 2.7,
          carbs: 28,
          fat: 0.3,
        ),
        source: 'test',
      );
      expect(food.nutrition.calories, closeTo(195, 0.001));
      expect(food.nutrition.protein, closeTo(4.05, 0.001));
    });

    test('rejects implausibly fast weight gain', () {
      final profile = UserProfile(
        age: 30,
        sex: 'male',
        heightCm: 175,
        weightKg: 70,
        activity: 'moderate',
        goalType: 'gain',
        targetWeightKg: 85,
        targetDate: DateTime(2026, 11, 8),
      );
      final assessment = NutritionCalculator.assess(
        profile,
        now: DateTime(2026, 10, 9),
      );
      expect(assessment.isPlausible, isFalse);
      expect(assessment.message, contains('kg/week'));
    });

    test('maintenance uses estimated TDEE', () {
      final profile = UserProfile(
        age: 30,
        sex: 'female',
        heightCm: 165,
        weightKg: 60,
        activity: 'light',
        goalType: 'maintain',
        targetWeightKg: 60,
        targetDate: DateTime(2027, 1, 1),
      );
      final assessment = NutritionCalculator.assess(
        profile,
        now: DateTime(2026, 10, 9),
      );
      expect(assessment.isPlausible, isTrue);
      expect(assessment.dailyTarget, assessment.tdee.roundToDouble());
    });
  });
}
