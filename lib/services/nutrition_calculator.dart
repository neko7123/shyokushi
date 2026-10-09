import 'dart:math' show min;
import '../models/nutrition.dart';

class NutritionCalculator {
  static const activityFactors = <String, double>{
    'sedentary': 1.2,
    'light': 1.375,
    'moderate': 1.55,
    'high': 1.725,
    'veryHigh': 1.9,
  };

  /// Mifflin-St Jeor resting energy estimate. It is a starting estimate, not a measurement.
  static double bmr(UserProfile p) {
    final base = 10 * p.weightKg + 6.25 * p.heightCm - 5 * p.age;
    switch (p.sex) {
      case 'female':
        return base - 161;
      case 'other':
        return base - 78; // midpoint of common male/female equation constants
      default:
        return base + 5;
    }
  }

  static double tdee(UserProfile p) =>
      bmr(p) * (activityFactors[p.activity] ?? 1.55);

  /// A conservative guardrail, not a medical diagnosis or guarantee of outcomes.
  /// Conservative heuristic: loss <= 1% body weight/week (also capped at 0.68 kg/week); gain <= 0.5% (also capped at 0.45 kg/week).
  static GoalAssessment assess(UserProfile p, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    final chosenDate = p.targetDate ?? todayDay.add(const Duration(days: 90));
    final targetDay = DateTime(
      chosenDate.year,
      chosenDate.month,
      chosenDate.day,
    );
    final days = targetDay.difference(todayDay).inDays;
    final maintenance = tdee(p);
    final deltaKg = p.targetWeightKg - p.weightKg;
    if (p.age < 18) {
      return GoalAssessment(
        bmr: bmr(p),
        tdee: maintenance,
        dailyTarget: maintenance,
        weeklyChangeKg: 0,
        isPlausible: false,
        message:
            'Adult calorie and weight-goal estimates are not appropriate for users under 18. Use a qualified clinician for a plan.',
        daysToGoal: days,
      );
    }
    if (days <= 0) {
      return GoalAssessment(
        bmr: bmr(p),
        tdee: maintenance,
        dailyTarget: maintenance,
        weeklyChangeKg: 0,
        isPlausible: false,
        message: 'Choose a target date in the future.',
        daysToGoal: days,
      );
    }
    if (p.weightKg <= 0 || p.targetWeightKg <= 0 || p.heightCm <= 0) {
      return GoalAssessment(
        bmr: bmr(p),
        tdee: maintenance,
        dailyTarget: maintenance,
        weeklyChangeKg: 0,
        isPlausible: false,
        message: 'Enter valid height and weight values first.',
        daysToGoal: days,
      );
    }
    if (p.goalType == 'maintain') {
      return GoalAssessment(
        bmr: bmr(p),
        tdee: maintenance,
        dailyTarget: maintenance.roundToDouble(),
        weeklyChangeKg: 0,
        isPlausible: true,
        message:
            'Maintenance is an estimate. Compare the 2–4 week weight trend with your intake and adjust gradually.',
        daysToGoal: days,
      );
    }
    if ((p.goalType == 'gain' && deltaKg <= 0) ||
        (p.goalType == 'lose' && deltaKg >= 0)) {
      return GoalAssessment(
        bmr: bmr(p),
        tdee: maintenance,
        dailyTarget: maintenance.roundToDouble(),
        weeklyChangeKg: 0,
        isPlausible: false,
        message:
            p.goalType == 'gain'
                ? 'A gain goal should have a target weight above your current weight.'
                : 'A loss goal should have a target weight below your current weight.',
        daysToGoal: days,
      );
    }
    if (deltaKg.abs() < 0.05) {
      return GoalAssessment(
        bmr: bmr(p),
        tdee: maintenance,
        dailyTarget: maintenance.roundToDouble(),
        weeklyChangeKg: 0,
        isPlausible: true,
        message:
            'The target is almost the same as your current weight; maintenance is a practical starting point.',
        daysToGoal: days,
      );
    }
    final actualWeekly = deltaKg.abs() / days * 7;
    final maxWeekly =
        p.goalType == 'lose'
            ? min(p.weightKg * 0.01, 0.68)
            : min(p.weightKg * 0.005, 0.45);
    final plausible = actualWeekly <= maxWeekly;
    // 7,700 kcal/kg is a coarse static approximation, not a dynamic body-weight model.
    final dailyAdjustment = (deltaKg * 7700 / days).clamp(-750.0, 500.0);
    final target = maintenance + dailyAdjustment;
    final message =
        !plausible
            ? 'This timeline implies ${actualWeekly.toStringAsFixed(2)} kg/week. For this starter app, choose a slower target (up to about ${(maxWeekly).toStringAsFixed(2)} kg/week by this conservative heuristic).'
            : target < 1200
            ? 'The estimated intake is unusually low. Do not use this as a prescription; revise the goal or consult a qualified clinician.'
            : p.goalType == 'gain'
            ? 'A modest surplus is generally more practical than aggressive bulking. Reassess using your multi-week weight trend.'
            : 'A gradual pace is easier to sustain. Reassess using your multi-week weight trend.';
    return GoalAssessment(
      bmr: bmr(p),
      tdee: maintenance,
      dailyTarget: target.roundToDouble(),
      weeklyChangeKg: actualWeekly,
      isPlausible: plausible && target >= 1200,
      message: message,
      daysToGoal: days,
    );
  }

  static Nutrition total(Iterable<FoodEntry> entries) => entries
      .where((e) => !e.isPlanned)
      .fold(const Nutrition(), (sum, item) => sum + item.nutrition);

  static Nutrition plannedTotal(Iterable<FoodEntry> entries) => entries
      .where((e) => e.isPlanned)
      .fold(const Nutrition(), (sum, item) => sum + item.nutrition);
}
