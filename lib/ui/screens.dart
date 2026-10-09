import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/app_database.dart';
import '../models/nutrition.dart';
import '../services/backup_service.dart';
import '../services/food_search_service.dart';
import '../services/nutrition_calculator.dart';
import 'app_text.dart';
import 'legal_documents.dart';

const _uuid = Uuid();

String _tr(BuildContext context, String value) =>
    AppText.translate(value, Localizations.localeOf(context).languageCode);

String _itemCount(int count, String languageCode) => switch (languageCode) {
  'ja' => '$count 品目',
  'zh' => '$count 项',
  'ko' => '$count개',
  _ => '$count items',
};

Widget _photoImage(
  String path, {
  double? height,
  double? width,
  BoxFit fit = BoxFit.cover,
}) {
  if (path.startsWith('data:image/')) {
    return Image.memory(
      base64Decode(path.substring(path.indexOf(',') + 1)),
      height: height,
      width: width,
      fit: fit,
    );
  }
  return Image.file(File(path), height: height, width: width, fit: fit);
}

String _dateLabel(DateTime date, String languageCode) {
  if (languageCode == 'ja') return '${date.year}年${date.month}月${date.day}日';
  if (languageCode == 'zh') return '${date.year}年${date.month}月${date.day}日';
  if (languageCode == 'ko') return '${date.year}년 ${date.month}월 ${date.day}일';
  return '${_month(date.month)} ${date.day}, ${date.year}';
}

String _month(int month) =>
    const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][month - 1];
String _countryLabel(String code) =>
    const {
      'JP': 'Japan',
      'US': 'United States',
      'CA': 'Canada',
      'GB': 'United Kingdom',
      'KR': 'South Korea',
      'CN': 'China',
      'OTHER': 'Other',
    }[code] ??
    'Japan';
String _languageLabel(String code) =>
    const {'en': 'English', 'ja': '日本語', 'zh': '中文', 'ko': '한국어'}[code] ??
    'English';
String _number(double value) =>
    value >= 100
        ? value.round().toString()
        : value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.db});
  final AppDatabase db;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _CalorieRange { week, month, quarter, year }

class _HomeScreenState extends State<HomeScreen> {
  _CalorieRange _range = _CalorieRange.week;

  Future<_HomeData> _load() async {
    final now = DateTime.now();
    final rows = await widget.db.allEntryMaps();
    final start = switch (_range) {
      _CalorieRange.week => DateTime(now.year, now.month, now.day - 6),
      _CalorieRange.month => DateTime(now.year, now.month, now.day - 29),
      _CalorieRange.quarter => DateTime(now.year, now.month - 2, 1),
      _CalorieRange.year => DateTime(now.year, now.month - 11, 1),
    };
    final daily = _range == _CalorieRange.week || _range == _CalorieRange.month;
    final count =
        daily
            ? (_range == _CalorieRange.week ? 7 : 30)
            : (_range == _CalorieRange.quarter ? 3 : 12);
    final totals = List<double>.filled(count, 0);
    for (final row in rows) {
      if ((row['isPlanned'] as num?)?.toInt() == 1) continue;
      final logged = DateTime.tryParse('${row['loggedAt']}');
      if (logged == null || logged.isBefore(start)) continue;
      final index =
          daily
              ? DateTime(
                logged.year,
                logged.month,
                logged.day,
              ).difference(start).inDays
              : (logged.year - start.year) * 12 + logged.month - start.month;
      if (index < 0 || index >= totals.length) continue;
      final grams = (row['grams'] as num?)?.toDouble() ?? 0;
      final kcal = (row['calories100g'] as num?)?.toDouble() ?? 0;
      totals[index] += grams * kcal / 100;
    }
    final todayEntries = <FoodEntry>[];
    for (final row in rows) {
      if (row['isPlanned'] == 1 || row['isPlanned'] == true) continue;
      final logged = DateTime.tryParse('${row['loggedAt']}');
      if (logged != null &&
          logged.year == now.year &&
          logged.month == now.month &&
          logged.day == now.day) {
        todayEntries.add(FoodEntry.fromMap(row));
      }
    }
    final rawProfile = await widget.db.readMeta('profile');
    final nutrition = NutritionCalculator.total(todayEntries);
    final profile = UserProfile.fromMap(rawProfile);
    final goal = NutritionCalculator.assess(profile);
    return _HomeData(
      totals,
      nutrition,
      goal.isPlausible ? goal.dailyTarget : goal.tdee,
      rawProfile != null,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_HomeData>(
    future: _load(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 40),
                const SizedBox(height: 12),
                const AppText('Could not load your home summary.'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const AppText('Try again'),
                ),
              ],
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final home = snapshot.data!;
      final values = home.calorieHistory;
      final total = values.fold<double>(0, (a, b) => a + b);
      final average = values.isEmpty ? 0.0 : total / values.length;
      final labels = switch (_range) {
        _CalorieRange.week => const [
          '7d',
          '6d',
          '5d',
          '4d',
          '3d',
          '2d',
          'Today',
        ],
        _CalorieRange.month => const [
          '30d',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '20d',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '10d',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          'Today',
        ],
        _CalorieRange.quarter => const ['2 mo ago', 'Last mo', 'This mo'],
        _CalorieRange.year => const [
          '11 mo',
          '',
          '',
          '8 mo',
          '',
          '',
          '5 mo',
          '',
          '',
          '2 mo',
          '',
          'This mo',
        ],
      };
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          _CaloriesCard(
            total: home.today.calories,
            target: home.target,
            remaining: home.target - home.today.calories,
            planned: 0,
            hasTarget: home.profileConfigured,
          ),
          const SizedBox(height: 12),
          _MacroStrip(nutrition: home.today),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AppText(
                  'Calories over time',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              PopupMenuButton<_CalorieRange>(
                tooltip: 'Choose graph period',
                onSelected: (value) => setState(() => _range = value),
                itemBuilder:
                    (context) => const [
                      PopupMenuItem(
                        value: _CalorieRange.week,
                        child: AppText('Week'),
                      ),
                      PopupMenuItem(
                        value: _CalorieRange.month,
                        child: AppText('Month'),
                      ),
                      PopupMenuItem(
                        value: _CalorieRange.quarter,
                        child: AppText('Quarter'),
                      ),
                      PopupMenuItem(
                        value: _CalorieRange.year,
                        child: AppText('Year'),
                      ),
                    ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(switch (_range) {
                        _CalorieRange.week => 'Week',
                        _CalorieRange.month => 'Month',
                        _CalorieRange.quarter => 'Quarter',
                        _CalorieRange.year => 'Year',
                      }),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down_rounded),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AppText(
            'A view of your logged food across the selected period.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'TOTAL',
                  value: '${_number(total)} kcal',
                  caption: 'In this period',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'DAILY AVERAGE',
                  value: '${_number(average)} kcal',
                  caption: 'Per day or month',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    'Logged calories',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(height: 190, child: _CalorieChart(values: values)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 14,
                    child: Stack(
                      children: [
                        for (var i = 0; i < labels.length; i++)
                          if (labels[i].isNotEmpty)
                            Align(
                              alignment: Alignment(
                                labels.length < 2
                                    ? 0
                                    : -1 + 2 * i / (labels.length - 1),
                                0,
                              ),
                              child: Text(
                                labels[i],
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 9,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (total == 0) ...[
            const SizedBox(height: 12),
            const _EmptyState(
              icon: Icons.show_chart_rounded,
              title: 'Your trend starts with a meal',
              text:
                  'Log food to see calorie totals by week, month, quarter and year.',
            ),
          ],
        ],
      );
    },
  );
}

class _HomeData {
  const _HomeData(
    this.calorieHistory,
    this.today,
    this.target,
    this.profileConfigured,
  );
  final List<double> calorieHistory;
  final Nutrition today;
  final double target;
  final bool profileConfigured;
}

class _CalorieChart extends StatelessWidget {
  const _CalorieChart({required this.values});
  final List<double> values;
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _CalorieChartPainter(values, Theme.of(context).colorScheme),
    child: const SizedBox.expand(),
  );
}

class _CalorieChartPainter extends CustomPainter {
  const _CalorieChartPainter(this.values, this.colors);
  final List<double> values;
  final ColorScheme colors;
  @override
  void paint(Canvas canvas, Size size) {
    final grid =
        Paint()
          ..color = colors.outlineVariant.withValues(alpha: .6)
          ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (values.isEmpty) return;
    final maxValue = (values.reduce((a, b) => a > b ? a : b) * 1.15).clamp(
      500.0,
      double.infinity,
    );
    final slot = size.width / values.length;
    final barWidth = (slot * .62).clamp(3.0, 22.0);
    final paint = Paint()..color = colors.primary;
    for (var i = 0; i < values.length; i++) {
      final h = (values[i] / maxValue * (size.height - 8)).clamp(
        2.0,
        size.height,
      );
      final x = i * slot + (slot - barWidth) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - h, barWidth, h),
          const Radius.circular(6),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CalorieChartPainter old) =>
      old.values != values || old.colors != colors;
}

List<List<FoodEntry>> _groupMeals(List<FoodEntry> entries) {
  final groups = <String, List<FoodEntry>>{};
  for (final entry in entries) {
    groups
        .putIfAbsent('${entry.mealId ?? entry.id}|${entry.meal}', () => [])
        .add(entry);
  }
  return groups.values.toList();
}

Future<void> _editEntry(
  BuildContext context,
  AppDatabase db,
  FoodSearchService foodSearch,
  FoodEntry entry,
  VoidCallback changed,
) async {
  final edited = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder:
        (_) => AddFoodSheet(
          db: db,
          foodSearch: foodSearch,
          loggedAt: entry.loggedAt,
          isPlanned: false,
          existing: entry,
        ),
  );
  if (edited == true) changed();
}

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({
    super.key,
    required this.db,
    required this.foodSearch,
    required this.onChanged,
  });
  final AppDatabase db;
  final FoodSearchService foodSearch;
  final VoidCallback onChanged;
  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  DateTime _date = DateTime.now();
  Future<List<FoodEntry>> _load() => widget.db.entriesOn(_date, planned: false);
  void _move(int days) => setState(
    () => _date = DateTime(_date.year, _date.month, _date.day + days),
  );
  @override
  Widget build(BuildContext context) => FutureBuilder<List<FoodEntry>>(
    future: _load(),
    builder: (context, snapshot) {
      final entries = snapshot.data ?? [];
      final total = NutritionCalculator.total(entries);
      return ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _move(-1),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        AppText(
                          _dateLabel(
                            _date,
                            Localizations.localeOf(context).languageCode,
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        AppText(
                          '${_number(total.calories)} kcal • ${_itemCount(entries.length, Localizations.localeOf(context).languageCode)}',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_date.isBefore(DateTime.now())) _move(1);
                    },
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                  IconButton(
                    onPressed: () async {
                      final chosen = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2018),
                        lastDate: DateTime.now(),
                      );
                      if (chosen != null) setState(() => _date = chosen);
                    },
                    icon: const Icon(Icons.calendar_month_rounded),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _MacroStrip(nutrition: total),
          const SizedBox(height: 18),
          if (entries.isEmpty)
            const _EmptyState(
              icon: Icons.menu_book_rounded,
              title: 'Nothing recorded for this day',
              text:
                  'Keep your diary useful, not perfect. Log the best estimate you have.',
            )
          else
            ..._groupMeals(entries).map(
              (meal) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _MealGroupTile(
                  entries: meal,
                  onEdit:
                      (entry) => _editEntry(
                        context,
                        widget.db,
                        widget.foodSearch,
                        entry,
                        () {
                          setState(() {});
                          widget.onChanged();
                        },
                      ),
                  onDelete: (entry) async {
                    await widget.db.deleteEntry(entry.id);
                    setState(() {});
                    widget.onChanged();
                  },
                ),
              ),
            ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () async {
              final added = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder:
                    (_) => AddFoodSheet(
                      db: widget.db,
                      foodSearch: widget.foodSearch,
                      loggedAt: _date,
                      isPlanned: false,
                    ),
              );
              if (added == true) {
                setState(() {});
                widget.onChanged();
              }
            },
            icon: const Icon(Icons.add_rounded),
            label: const AppText('Add to this day'),
          ),
        ],
      );
    },
  );
}

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({
    super.key,
    required this.db,
    required this.foodSearch,
    required this.onChanged,
  });
  final AppDatabase db;
  final FoodSearchService foodSearch;
  final VoidCallback onChanged;
  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  Future<_PlanData> _load() async {
    final actual = await widget.db.entriesOn(DateTime.now(), planned: false);
    final planned = await widget.db.entriesOn(DateTime.now(), planned: true);
    final profileMap = await widget.db.readMeta('profile');
    final profile = UserProfile.fromMap(profileMap);
    return _PlanData(
      actual,
      planned,
      NutritionCalculator.assess(profile),
      profileMap != null,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_PlanData>(
    future: _load(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final data = snapshot.data!;
      final eaten = NutritionCalculator.total(data.actual);
      final planned = NutritionCalculator.plannedTotal(data.planned);
      final target =
          data.goal.isPlausible ? data.goal.dailyTarget : data.goal.tdee;
      final projected = eaten + planned;
      final remaining = target - projected.calories;
      return ListView(
        padding: const EdgeInsets.all(18),
        children: [
          AppText(
            'Decide before dinner.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          AppText(
            'Add food you intend to eat. The forecast combines what you logged with what you plan.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          _CaloriesCard(
            total: projected.calories,
            target: target,
            remaining: remaining,
            planned: planned.calories,
            forecast: true,
            hasTarget: data.profileConfigured,
          ),
          const SizedBox(height: 14),
          _MacroStrip(nutrition: projected),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                'Planned food',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              AppText(
                _itemCount(
                  data.planned.length,
                  Localizations.localeOf(context).languageCode,
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (data.planned.isEmpty)
            const _EmptyState(
              icon: Icons.event_note_rounded,
              title: 'Plan a meal ahead',
              text:
                  'Search a food or add a manual estimate to see whether it fits your daily budget.',
            )
          else
            ...data.planned.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _EntryTile(
                  entry: entry,
                  onEdit: () async {
                    final edited = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder:
                          (_) => AddFoodSheet(
                            db: widget.db,
                            foodSearch: widget.foodSearch,
                            loggedAt: entry.loggedAt,
                            isPlanned: true,
                            existing: entry,
                          ),
                    );
                    if (edited == true) {
                      setState(() {});
                      widget.onChanged();
                    }
                  },
                  trailing: IconButton(
                    tooltip: 'Mark as eaten',
                    onPressed: () async {
                      await widget.db.setPlanned(entry.id, false);
                      setState(() {});
                      widget.onChanged();
                    },
                    icon: Icon(
                      Icons.check_circle_outline_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  onDelete: () async {
                    await widget.db.deleteEntry(entry.id);
                    setState(() {});
                    widget.onChanged();
                  },
                ),
              ),
            ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () async {
              final added = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder:
                    (_) => AddFoodSheet(
                      db: widget.db,
                      foodSearch: widget.foodSearch,
                      loggedAt: DateTime.now(),
                      isPlanned: true,
                    ),
              );
              if (added == true) {
                setState(() {});
                widget.onChanged();
              }
            },
            icon: const Icon(Icons.add_rounded),
            label: const AppText('Plan a food'),
          ),
          const SizedBox(height: 14),
          AppText(
            !data.profileConfigured
                ? 'Set up your body profile in Settings to get a personal daily target.'
                : remaining >= 0
                ? '${_number(remaining)} kcal remain after this plan.'
                : 'This plan is ${_number(remaining.abs())} kcal over the current estimate.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    },
  );
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.db, required this.onChanged});
  final AppDatabase db;
  final VoidCallback onChanged;
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Future<_ProgressData> _load() async {
    final rawProfile = await widget.db.readMeta('profile');
    var logs = await widget.db.weights();
    if (logs.isEmpty && rawProfile != null) {
      final profile = UserProfile.fromMap(rawProfile);
      final initialWeight = WeightLog(
        id: 'profile_initial_weight',
        loggedAt: DateTime.now(),
        kg: profile.weightKg,
        notes: 'Initial weight from body profile',
      );
      await widget.db.insertWeight(initialWeight);
      logs = [initialWeight];
    }
    return _ProgressData(
      logs,
      UserProfile.fromMap(rawProfile),
      rawProfile != null,
    );
  }

  Future<void> _addWeight() async {
    final ctrl = TextEditingController();
    final notes = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const AppText('Log body weight'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _tr(context, 'Weight (kg)'),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notes,
                  decoration: InputDecoration(
                    labelText: _tr(context, 'Note (optional)'),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const AppText('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final v = double.tryParse(ctrl.text.replaceAll(',', '.'));
                  if (v != null && v > 0 && v < 500) Navigator.pop(context, v);
                },
                child: const AppText('Save'),
              ),
            ],
          ),
    );
    if (result != null) {
      await widget.db.insertWeight(
        WeightLog(
          id: _uuid.v4(),
          loggedAt: DateTime.now(),
          kg: result,
          notes: notes.text.trim(),
        ),
      );
      final raw = await widget.db.readMeta('profile');
      if (raw != null) {
        final current = UserProfile.fromMap(raw);
        await widget.db.saveMeta(
          'profile',
          current.copyWith(weightKg: result).toMap(),
        );
      }
      if (mounted) setState(() {});
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_ProgressData>(
    future: _load(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final data = snapshot.data!;
      final logs = data.logs;
      final heightM = data.profile.heightCm / 100;
      double bmiFor(double kg) => kg / (heightM * heightM);
      final latest = logs.isEmpty ? null : logs.first;
      final oldest = logs.isEmpty ? null : logs.last;
      final change =
          latest != null && oldest != null ? latest.kg - oldest.kg : 0.0;
      return ListView(
        padding: const EdgeInsets.all(18),
        children: [
          AppText(
            'Measure trends, not single days.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          AppText(
            'Body weight moves with hydration, salt, digestion and other normal variation. Focus on the trend over weeks.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'LATEST',
                  value: latest == null ? '—' : '${_number(latest.kg)} kg',
                  caption:
                      latest == null
                          ? 'No readings yet'
                          : _dateLabel(
                            latest.loggedAt,
                            Localizations.localeOf(context).languageCode,
                          ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'RECORDED CHANGE',
                  value:
                      logs.length < 2
                          ? '—'
                          : '${change > 0 ? '+' : ''}${_number(change)} kg',
                  caption:
                      logs.length < 2
                          ? 'Add another reading'
                          : 'Across recorded range',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.accessibility_new_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const AppText('BMI'),
              subtitle: AppText(
                !data.profileConfigured
                    ? 'Add your height in Body profile to calculate BMI.'
                    : data.profile.age < 18
                    ? 'BMI categories for adults do not apply under age 18.'
                    : 'Based on your latest weight and height. BMI is a screening measure, not a diagnosis.',
              ),
              trailing: AppText(
                !data.profileConfigured || data.profile.age < 18
                    ? '—'
                    : _number(bmiFor(latest?.kg ?? data.profile.weightKg)),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _addWeight,
            icon: const Icon(Icons.monitor_weight_outlined),
            label: const AppText('Log body weight'),
          ),
          const SizedBox(height: 22),
          AppText(
            'Weight history',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          if (logs.isEmpty)
            const _EmptyState(
              icon: Icons.show_chart_rounded,
              title: 'Build a useful trend',
              text:
                  'Add weight measurements under similar conditions, such as in the morning, to make comparisons more useful.',
            )
          else
            ...logs.map(
              (log) => Card(
                child: ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.scale_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: AppText(
                    '${_number(log.kg)} kg',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  subtitle: AppText(
                    '${_dateLabel(log.loggedAt, Localizations.localeOf(context).languageCode)}${data.profileConfigured && data.profile.age >= 18 ? ' • BMI ${_number(bmiFor(log.kg))}' : ''}${log.notes.isEmpty ? '' : ' • ${log.notes}'}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: AppText(
                    '${log.loggedAt.hour.toString().padLeft(2, '0')}:${log.loggedAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.db,
    required this.backup,
    required this.onChanged,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.preferences,
    required this.displayName,
    required this.onDisplayNameChanged,
    required this.onPreferencesChanged,
  });
  final AppDatabase db;
  final BackupService backup;
  final VoidCallback onChanged;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final Map<String, dynamic> preferences;
  final ValueListenable<String> displayName;
  final Future<void> Function(String) onDisplayNameChanged;
  final Future<void> Function(Map<String, dynamic>) onPreferencesChanged;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<_SettingsData> _load() async {
    final raw = await widget.db.readMeta('profile');
    return _SettingsData(UserProfile.fromMap(raw), raw != null);
  }

  Future<void> _choosePreference(
    String key,
    String title,
    Map<String, String> options,
  ) async {
    final value = await showDialog<String>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: AppText(title),
            children:
                options.entries
                    .map(
                      (e) => SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, e.key),
                        child: AppText(e.value),
                      ),
                    )
                    .toList(),
          ),
    );
    if (!mounted || value == null) return;
    await widget.onPreferencesChanged({...widget.preferences, key: value});
  }

  Future<void> _editDisplayName() async {
    final controller = TextEditingController(
      text: '${widget.preferences['displayName'] ?? ''}',
    );
    final value = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const AppText('Your name'),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLength: 32,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name shown in the header',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const AppText('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const AppText('Save'),
              ),
            ],
          ),
    );
    controller.dispose();
    if (value == null || !mounted) return;
    try {
      await widget.onDisplayNameChanged(value);
    } catch (error) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const AppText('Name was not saved'),
              content: Text('$error'),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const AppText('Close'),
                ),
              ],
            ),
      );
    }
  }

  void _showPrivacyPolicy() => showDialog<void>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const AppText('Privacy policy'),
          content: SizedBox(
            width: 560,
            height: MediaQuery.sizeOf(context).height * .65,
            child: SingleChildScrollView(
              child: SelectableText(
                LegalDocuments.text(
                  Localizations.localeOf(context).languageCode,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const AppText('Close'),
            ),
          ],
        ),
  );

  Future<void> _editProfile(UserProfile profile) async {
    final updated = await showDialog<UserProfile>(
      context: context,
      builder: (_) => ProfileEditor(initial: profile),
    );
    if (updated != null) {
      await widget.db.saveMeta('profile', updated.toMap());
      widget.onChanged();
      if (mounted) setState(() {});
    }
  }

  Future<void> _import() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const AppText('Import diary data?'),
            content: const AppText(
              'Readable entries, planned meals, weight logs, profile and preferences will be added. Matching IDs are overwritten from the backup; unrelated records already on this device are kept.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const AppText('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const AppText('Continue'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final bytes = await widget.backup.pickBackup();
      if (bytes == null || !mounted) return;
      final passphrase =
          widget.backup.requiresPassphrase(bytes)
              ? await _backupPassphrase()
              : '';
      if (passphrase == null || !mounted) return;
      final result = await widget.backup.importBackup(passphrase, bytes);
      if (!mounted) return;
      if (result.preferences != null) {
        await widget.onPreferencesChanged(result.preferences!);
      }
      if (!mounted) return;
      widget.onChanged();
      final settingsSummary = [
        if (result.profileImported) 'profile and goals',
        if (result.preferencesImported) 'name and app preferences',
      ].join(', ');
      await showDialog<void>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const AppText('Import complete'),
              content: AppText(
                '${result.entryCount} food entries (${result.plannedCount} planned), '
                '${result.weightCount} weight records, and ${result.photoCount} photos imported. '
                '${settingsSummary.isEmpty ? 'No profile or app settings were found. ' : 'Updated $settingsSummary. '}'
                '${result.skippedCount} incomplete items or photos skipped.',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const AppText('Done'),
                ),
              ],
            ),
      );
    } catch (e) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const AppText('Import failed'),
                content: Text(
                  '$e',
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const AppText('Close'),
                  ),
                ],
              ),
        );
      }
    }
  }

  Future<String?> _backupPassphrase() async {
    final first = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const AppText('Unlock backup'),
            content: TextField(
              controller: first,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Backup key'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const AppText('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (first.text.isEmpty) {
                    return;
                  }
                  Navigator.pop(context, first.text);
                },
                child: const AppText('Open'),
              ),
            ],
          ),
    );
    first.dispose();
    return value;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_SettingsData>(
    future: _load(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final settings = snapshot.data!;
      final profile = settings.profile;
      final goal = NutritionCalculator.assess(profile);
      return ListView(
        padding: const EdgeInsets.all(18),
        children: [
          AppText(
            'Your data, your device.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          AppText(
            'Your food diary is stored in the app’s local SQLite database. Network access is used only when you search online food data.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('PERSONALIZATION'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: const AppText('Your name'),
                  subtitle: ValueListenableBuilder<String>(
                    valueListenable: widget.displayName,
                    builder:
                        (context, name, _) => Text(
                          name.isEmpty
                              ? 'Set the name shown in the app header'
                              : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _editDisplayName,
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.public_rounded),
                  title: const AppText('Country / food reference'),
                  subtitle: AppText(
                    "${_countryLabel(widget.preferences['country']?.toString() ?? 'JP')} · Regional and global product matches",
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap:
                      () => _choosePreference(
                        'country',
                        'Country / food reference',
                        const {
                          'JP': 'Japan',
                          'US': 'United States',
                          'CA': 'Canada',
                          'GB': 'United Kingdom',
                          'KR': 'South Korea',
                          'CN': 'China',
                          'OTHER': 'Other',
                        },
                      ),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: const AppText('Language'),
                  subtitle: AppText(
                    _languageLabel('${widget.preferences['language'] ?? 'en'}'),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap:
                      () => _choosePreference('language', 'Language', const {
                        'en': 'English',
                        'ja': '日本語',
                        'zh': '中文',
                        'ko': '한국어',
                      }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('APPEARANCE'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    'Color theme',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    widget.themeMode == ThemeMode.system
                        ? 'Following your device appearance'
                        : '${widget.themeMode.name[0].toUpperCase()}${widget.themeMode.name.substring(1)} appearance',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto_rounded),
                          label: AppText('System'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_rounded),
                          label: AppText('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_rounded),
                          label: AppText('Dark'),
                        ),
                      ],
                      selected: {widget.themeMode},
                      onSelectionChanged:
                          (modes) => widget.onThemeModeChanged(modes.first),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('PROFILE & GOAL'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.person_outline_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const AppText(
                    'Body profile',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: AppText(
                    settings.profileConfigured
                        ? '${profile.age} years • ${_number(profile.heightCm)} cm • ${_number(profile.weightKg)} kg'
                        : 'Tap to enter your measurements',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _editProfile(profile),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(
                    Icons.flag_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const AppText(
                    'Weight goal',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: AppText(
                    settings.profileConfigured
                        ? '${profile.goalType == 'gain'
                            ? 'Gain'
                            : profile.goalType == 'lose'
                            ? 'Lose'
                            : 'Maintain'} • target ${_number(profile.targetWeightKg)} kg • ${_dateLabel(profile.targetDate ?? DateTime.now(), Localizations.localeOf(context).languageCode)}'
                        : 'Set your goal and a realistic target date',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _editProfile(profile),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 15),
                  child: _TargetInsight(
                    goal: goal,
                    plannedCalories: 0,
                    plannedCount: 0,
                    hasProfile: settings.profileConfigured,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('PRIVACY'),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const AppText('Privacy policy'),
              subtitle: const AppText(
                'What stays on this device and what is sent during search',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _showPrivacyPolicy,
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('BACKUP & RESTORE'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.ios_share_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const AppText(
                    'Export a backup',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const AppText(
                    'Passphrase-encrypted file includes diary, goals, weight and photos',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    try {
                      final backup = await widget.backup.exportToDownloads();
                      if (!context.mounted) return;
                      await showDialog<void>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const AppText('Backup saved'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const AppText(
                                    'Saved to Downloads/ShyokuShi. Write down this 10-character key. You need it to restore the backup.',
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${backup.entryCount} food entries and ${backup.photoCount} photos included.',
                                    style: TextStyle(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SelectableText(
                                          backup.key,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Copy key',
                                        icon: const Icon(Icons.copy_rounded),
                                        onPressed: () async {
                                          await Clipboard.setData(
                                            ClipboardData(text: backup.key),
                                          );
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: AppText(
                                                  'Key copied. Store it somewhere safe.',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const AppText('Done'),
                                ),
                              ],
                            ),
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: AppText('Export failed: $e')),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(
                    Icons.file_download_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const AppText(
                    'Import a backup',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const AppText(
                    'Restores encrypted backups; legacy JSON is also supported',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _import,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('FOOD DATA & PRIVACY'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SourceLine(
                    name: 'Open Food Facts',
                    detail:
                        'Community-sourced packaged-food data. Attribution: Open Food Facts. Database is under ODbL; review reuse/share-alike and image terms before redistribution.',
                  ),
                  const SizedBox(height: 12),
                  const _SourceLine(
                    name: 'USDA FoodData Central',
                    detail:
                        'Generic and branded food data (CC0). USDA requests source attribution. Optional API key enables lookup in this build.',
                  ),
                  const SizedBox(height: 12),
                  const _SourceLine(
                    name: 'Photos',
                    detail:
                        'Stored locally with entries. This version does not upload photos or run AI recognition.',
                  ),
                  const SizedBox(height: 12),
                  AppText(
                    'Online searches send the search term to the chosen data provider. Do not enter sensitive information in a food search.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed:
                  () => launchUrl(Uri.parse('https://github.com/neko7123')),
              child: const Text('Built by Neko'),
            ),
          ),
        ],
      );
    },
  );
}

class ProfileEditor extends StatefulWidget {
  const ProfileEditor({super.key, required this.initial});
  final UserProfile initial;
  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  late final _age = TextEditingController(text: widget.initial.age.toString());
  late final _height = TextEditingController(
    text: widget.initial.heightCm.toString(),
  );
  late final _weight = TextEditingController(
    text: widget.initial.weightKg.toString(),
  );
  late final _target = TextEditingController(
    text: widget.initial.targetWeightKg.toString(),
  );
  late final _date = TextEditingController(
    text: _dateIso(
      widget.initial.targetDate ?? DateTime.now().add(const Duration(days: 90)),
    ),
  );
  late String _sex = widget.initial.sex;
  late String _activity = widget.initial.activity;
  late String _goal = widget.initial.goalType;
  String _dateIso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _target.dispose();
    _date.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const AppText('Profile & goal'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _age,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: _tr(context, 'Age')),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _sex,
              decoration: InputDecoration(
                labelText: _tr(context, 'Sex used for estimate'),
              ),
              items: const [
                DropdownMenuItem(value: 'male', child: AppText('Male')),
                DropdownMenuItem(value: 'female', child: AppText('Female')),
                DropdownMenuItem(
                  value: 'other',
                  child: AppText(
                    'Other / midpoint',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _sex = v ?? 'other'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _height,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: _tr(context, 'Height (cm)'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _weight,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: _tr(context, 'Current weight (kg)'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _activity,
              decoration: InputDecoration(
                labelText: _tr(context, 'Activity level'),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'sedentary',
                  child: AppText('Sedentary'),
                ),
                DropdownMenuItem(
                  value: 'light',
                  child: AppText('Light activity'),
                ),
                DropdownMenuItem(value: 'moderate', child: AppText('Moderate')),
                DropdownMenuItem(value: 'high', child: AppText('High')),
                DropdownMenuItem(
                  value: 'veryHigh',
                  child: AppText('Very high'),
                ),
              ],
              onChanged: (v) => setState(() => _activity = v ?? 'moderate'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _goal,
              decoration: InputDecoration(labelText: _tr(context, 'Goal')),
              items: const [
                DropdownMenuItem(
                  value: 'maintain',
                  child: AppText('Maintain weight'),
                ),
                DropdownMenuItem(
                  value: 'gain',
                  child: AppText('Gain weight / muscle'),
                ),
                DropdownMenuItem(value: 'lose', child: AppText('Lose weight')),
              ],
              onChanged: (v) => setState(() => _goal = v ?? 'maintain'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _target,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: _tr(context, 'Target weight (kg)'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _date,
                    decoration: InputDecoration(
                      labelText: _tr(context, 'Target date (YYYY-MM-DD)'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppText(
              'Estimates are intended for adults and are not medical advice. Muscle gain cannot be predicted from calories alone.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const AppText('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          final age = int.tryParse(_age.text);
          final height = double.tryParse(_height.text.replaceAll(',', '.'));
          final weight = double.tryParse(_weight.text.replaceAll(',', '.'));
          final target = double.tryParse(_target.text.replaceAll(',', '.'));
          final date = DateTime.tryParse(_date.text.trim());
          if (age == null ||
              age < 1 ||
              age > 110 ||
              height == null ||
              height < 80 ||
              height > 250 ||
              weight == null ||
              weight < 20 ||
              weight > 500 ||
              target == null ||
              target < 20 ||
              target > 500 ||
              date == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: AppText('Check age, height, weights and target date.'),
              ),
            );
            return;
          }
          final updated = UserProfile(
            age: age,
            sex: _sex,
            heightCm: height,
            weightKg: weight,
            activity: _activity,
            goalType: _goal,
            targetWeightKg: target,
            targetDate: date,
          );
          final assessment = NutritionCalculator.assess(updated);
          if (!assessment.isPlausible) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: AppText(
                  '${assessment.message} Saved for tracking; the daily target stays at the maintenance estimate until the goal is adjusted.',
                ),
                duration: const Duration(seconds: 6),
              ),
            );
          }
          Navigator.pop(context, updated);
        },
        child: const AppText('Save profile'),
      ),
    ],
  );
}

class _MealIngredientDraft {
  _MealIngredientDraft();

  final String id = _uuid.v4();
  final name = TextEditingController();
  final grams = TextEditingController(text: '100');
  final kcal = TextEditingController();
  final protein = TextEditingController();
  final carbs = TextEditingController();
  final fat = TextEditingController();
  final fiber = TextEditingController();
  final sugar = TextEditingController();
  String source = 'Manual';
  String? referenceId;
  String quality = '';
  Set<String> missing = {};

  void dispose() {
    name.dispose();
    grams.dispose();
    kcal.dispose();
    protein.dispose();
    carbs.dispose();
    fat.dispose();
    fiber.dispose();
    sugar.dispose();
  }
}

class AddFoodSheet extends StatefulWidget {
  const AddFoodSheet({
    super.key,
    required this.db,
    required this.foodSearch,
    required this.loggedAt,
    required this.isPlanned,
    this.existing,
  });
  final AppDatabase db;
  final FoodSearchService foodSearch;
  final DateTime loggedAt;
  final bool isPlanned;
  final FoodEntry? existing;
  @override
  State<AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<AddFoodSheet> {
  final _ingredients = <_MealIngredientDraft>[];
  final _searchingIngredients = <String>{};
  final _ingredientResults = <String, List<FoodCandidate>>{};
  final _ingredientSearchTimers = <String, Timer>{};
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  final _query = TextEditingController();
  late final _grams = TextEditingController(
    text: widget.existing?.grams.toString() ?? '100',
  );
  late final _kcal = TextEditingController(
    text: widget.existing?.nutritionPer100g.calories.toString() ?? '',
  );
  late final _protein = TextEditingController(
    text: widget.existing?.nutritionPer100g.protein.toString() ?? '',
  );
  late final _carbs = TextEditingController(
    text: widget.existing?.nutritionPer100g.carbs.toString() ?? '',
  );
  late final _fat = TextEditingController(
    text: widget.existing?.nutritionPer100g.fat.toString() ?? '',
  );
  late final _fiber = TextEditingController(
    text: widget.existing?.nutritionPer100g.fiber.toString() ?? '',
  );
  late final _sugar = TextEditingController(
    text: widget.existing?.nutritionPer100g.sugar.toString() ?? '',
  );
  late final _notes = TextEditingController(text: widget.existing?.notes ?? '');
  late String _meal = widget.existing?.meal ?? 'Dinner';
  late String _source = widget.existing?.source ?? 'Manual';
  String _quality = '';
  String? _photoPath;
  String? _referenceId;
  List<FoodCandidate> _results = [];
  bool _searching = false;
  String? _searchMessage;
  bool _saving = false;
  Timer? _searchDebounce;
  int _searchRequest = 0;

  @override
  void initState() {
    super.initState();
    _photoPath = widget.existing?.photoPath;
    _referenceId = widget.existing?.referenceId;
    if (widget.existing == null) {
      _ingredients.add(_MealIngredientDraft());
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    for (final timer in _ingredientSearchTimers.values) {
      timer.cancel();
    }
    _name.dispose();
    _query.dispose();
    _grams.dispose();
    _kcal.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    _fiber.dispose();
    _sugar.dispose();
    _notes.dispose();
    for (final ingredient in _ingredients) {
      ingredient.dispose();
    }
    super.dispose();
  }

  Future<void> _search() async {
    if (_query.text.trim().length < 2) return;
    final request = ++_searchRequest;
    setState(() {
      _searching = true;
      _searchMessage = null;
    });
    final results = await widget.foodSearch.search(_query.text);
    if (!mounted || request != _searchRequest) return;
    setState(() {
      _results = results;
      _searching = false;
      _searchMessage =
          results.isEmpty
              ? 'No online matches. Try another spelling or enter nutrition manually.'
              : null;
    });
  }

  void _queueSearch(String value) {
    _searchDebounce?.cancel();
    if (value.trim().length < 2) {
      ++_searchRequest;
      setState(() {
        _results = [];
        _searchMessage = null;
        _searching = false;
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 450), _search);
  }

  Future<void> _searchIngredient(_MealIngredientDraft ingredient) async {
    final query = ingredient.name.text.trim();
    if (query.length < 2) return;
    setState(() => _searchingIngredients.add(ingredient.id));
    final results = await widget.foodSearch.search(query);
    if (!mounted) return;
    setState(() {
      _searchingIngredients.remove(ingredient.id);
      if (ingredient.name.text.trim() == query) {
        _ingredientResults[ingredient.id] = results;
      }
    });
  }

  void _queueIngredientSearch(_MealIngredientDraft ingredient, String value) {
    _ingredientSearchTimers.remove(ingredient.id)?.cancel();
    if (value.trim().length < 2) {
      setState(() => _ingredientResults.remove(ingredient.id));
      return;
    }
    _ingredientSearchTimers[ingredient.id] = Timer(
      const Duration(milliseconds: 450),
      () => _searchIngredient(ingredient),
    );
  }

  void _selectIngredient(
    _MealIngredientDraft ingredient,
    FoodCandidate selected,
  ) {
    setState(() {
      _ingredientResults.remove(ingredient.id);
      ingredient.name.text = selected.name;
      ingredient.kcal.text = selected.nutritionPer100g.calories.toStringAsFixed(
        1,
      );
      ingredient.protein.text =
          selected.missingNutrients.contains('protein')
              ? ''
              : selected.nutritionPer100g.protein.toStringAsFixed(1);
      ingredient.carbs.text =
          selected.missingNutrients.contains('carbs')
              ? ''
              : selected.nutritionPer100g.carbs.toStringAsFixed(1);
      ingredient.fat.text =
          selected.missingNutrients.contains('fat')
              ? ''
              : selected.nutritionPer100g.fat.toStringAsFixed(1);
      ingredient.fiber.text =
          selected.missingNutrients.contains('fiber')
              ? ''
              : selected.nutritionPer100g.fiber.toStringAsFixed(1);
      ingredient.sugar.text =
          selected.missingNutrients.contains('sugar')
              ? ''
              : selected.nutritionPer100g.sugar.toStringAsFixed(1);
      ingredient.source = selected.source;
      ingredient.referenceId = selected.referenceId;
      ingredient.quality = selected.dataQuality;
      ingredient.missing = selected.missingNutrients;
    });
  }

  void _addIngredient() {
    setState(() => _ingredients.add(_MealIngredientDraft()));
  }

  double _draftValue(TextEditingController controller) =>
      _value(controller) ?? 0;

  Nutrition get _mealNutrition =>
      _ingredients.fold(const Nutrition(), (total, ingredient) {
        final grams = _draftValue(ingredient.grams);
        return total +
            Nutrition(
                  calories: _draftValue(ingredient.kcal),
                  protein: _draftValue(ingredient.protein),
                  carbs: _draftValue(ingredient.carbs),
                  fat: _draftValue(ingredient.fat),
                  fiber: _draftValue(ingredient.fiber),
                  sugar: _draftValue(ingredient.sugar),
                ) *
                (grams / 100);
      });

  bool get _hasUnknownNutrition => _ingredients.any(
    (item) =>
        item.missing.isNotEmpty ||
        [
          item.protein,
          item.carbs,
          item.fat,
          item.fiber,
          item.sugar,
        ].any((field) => field.text.trim().isEmpty),
  );

  void _select(FoodCandidate item) {
    _name.text = item.name;
    _kcal.text = item.nutritionPer100g.calories.toStringAsFixed(1);
    _protein.text =
        item.missingNutrients.contains('protein')
            ? ''
            : item.nutritionPer100g.protein.toStringAsFixed(1);
    _carbs.text =
        item.missingNutrients.contains('carbs')
            ? ''
            : item.nutritionPer100g.carbs.toStringAsFixed(1);
    _fat.text =
        item.missingNutrients.contains('fat')
            ? ''
            : item.nutritionPer100g.fat.toStringAsFixed(1);
    _fiber.text =
        item.missingNutrients.contains('fiber')
            ? ''
            : item.nutritionPer100g.fiber.toStringAsFixed(1);
    _sugar.text =
        item.missingNutrients.contains('sugar')
            ? ''
            : item.nutritionPer100g.sugar.toStringAsFixed(1);
    _source = item.source;
    _referenceId = item.referenceId;
    _quality = item.dataQuality;
    FocusScope.of(context).unfocus();
    setState(() => _results = []);
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const AppText('Take a photo'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const AppText('Choose from gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1800,
    );
    if (picked == null) return;
    if (kIsWeb) {
      final encoded = base64Encode(await picked.readAsBytes());
      if (mounted) {
        setState(() => _photoPath = 'data:image/jpeg;base64,$encoded');
      }
      return;
    }
    final appDir = await widget.db.localDirectory;
    final photos = Directory(p.join(appDir.path, 'food_photos'));
    await photos.create(recursive: true);
    final ext =
        p.extension(picked.path).isEmpty ? '.jpg' : p.extension(picked.path);
    final copy = await File(
      picked.path,
    ).copy(p.join(photos.path, '${_uuid.v4()}$ext'));
    if (mounted) setState(() => _photoPath = copy.path);
  }

  double? _value(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));
  Future<void> _save() async {
    if (widget.existing == null) return _saveMeal();
    final name = _name.text.trim();
    final grams = _value(_grams),
        kcal = _value(_kcal),
        protein = _value(_protein),
        carbs = _value(_carbs),
        fat = _value(_fat),
        fiber = _value(_fiber),
        sugar = _value(_sugar);
    if (name.isEmpty ||
        grams == null ||
        grams <= 0 ||
        kcal == null ||
        protein == null ||
        carbs == null ||
        fat == null ||
        fiber == null ||
        sugar == null ||
        [kcal, protein, carbs, fat, fiber, sugar].any((v) => v < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText(
            'Enter a food name, positive grams and valid non-negative nutrition values.',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final stamp = DateTime(
      widget.loggedAt.year,
      widget.loggedAt.month,
      widget.loggedAt.day,
      now.hour,
      now.minute,
      now.second,
    );
    await widget.db.insertEntry(
      FoodEntry(
        id: widget.existing?.id ?? _uuid.v4(),
        loggedAt: widget.existing?.loggedAt ?? stamp,
        name: name,
        meal: _meal,
        grams: grams,
        nutritionPer100g: Nutrition(
          calories: kcal,
          protein: protein,
          carbs: carbs,
          fat: fat,
          fiber: fiber,
          sugar: sugar,
        ),
        source: _source,
        referenceId: _referenceId,
        mealId: widget.existing?.mealId,
        photoPath: _photoPath,
        notes: _notes.text.trim(),
        isPlanned: widget.isPlanned,
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _saveMeal() async {
    if (_saving) return;
    final invalid = _ingredients.any((item) {
      final grams = _value(item.grams);
      final calories = _value(item.kcal);
      final nutrients = [
        calories,
        _value(item.protein),
        _value(item.carbs),
        _value(item.fat),
        _value(item.fiber),
        _value(item.sugar),
      ];
      return item.name.text.trim().isEmpty ||
          grams == null ||
          !grams.isFinite ||
          grams <= 0 ||
          calories == null ||
          !calories.isFinite ||
          calories < 0 ||
          nutrients.any(
            (value) => value != null && (!value.isFinite || value < 0),
          );
    });
    if (_ingredients.isEmpty || invalid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText(
            'Add each food, enter its grams, and check the nutrition values.',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final stamp = DateTime(
      widget.loggedAt.year,
      widget.loggedAt.month,
      widget.loggedAt.day,
      now.hour,
      now.minute,
      now.second,
    );
    final notes = _notes.text.trim();
    final mealId = _uuid.v4();
    final entries =
        _ingredients.map((item) {
          return FoodEntry(
            id: _uuid.v4(),
            loggedAt: stamp,
            name: item.name.text.trim(),
            meal: _meal,
            grams: _value(item.grams)!,
            nutritionPer100g: Nutrition(
              calories: _draftValue(item.kcal),
              protein: _draftValue(item.protein),
              carbs: _draftValue(item.carbs),
              fat: _draftValue(item.fat),
              fiber: _draftValue(item.fiber),
              sugar: _draftValue(item.sugar),
            ),
            source: item.source,
            referenceId: item.referenceId,
            mealId: mealId,
            photoPath: _photoPath,
            notes: notes,
            isPlanned: widget.isPlanned,
          );
        }).toList();
    try {
      await widget.db.insertEntries(entries);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: AppText('Could not save this meal. Please try again.'),
          ),
        );
      }
    }
  }

  Widget _numField(
    String label,
    TextEditingController controller, {
    String unit = 'g',
    ValueChanged<String>? onChanged,
  }) => TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: _tr(context, label),
      suffixText: unit,
    ),
  );

  Widget _buildMealEditor(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: true,
    body: Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppText(
              widget.isPlanned ? 'Plan a meal' : 'Log a meal',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 5),
            AppText(
              'Add the foods on your plate one by one. A photo is a reference; it cannot estimate ingredients or grams.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: AppText(
                _photoPath == null
                    ? 'Add meal photo (optional)'
                    : 'Change meal photo',
              ),
            ),
            if (_photoPath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _photoImage(
                    _photoPath!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _meal,
              decoration: InputDecoration(labelText: _tr(context, 'Meal')),
              items: const [
                DropdownMenuItem(
                  value: 'Breakfast',
                  child: AppText('Breakfast'),
                ),
                DropdownMenuItem(value: 'Lunch', child: AppText('Lunch')),
                DropdownMenuItem(value: 'Dinner', child: AppText('Dinner')),
                DropdownMenuItem(value: 'Snack', child: AppText('Snack')),
              ],
              onChanged: (value) => setState(() => _meal = value ?? 'Dinner'),
            ),
            const SizedBox(height: 14),
            const _SectionLabel('ADD WHAT WAS ON YOUR PLATE'),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: _addIngredient,
              icon: const Icon(Icons.add_rounded),
              label: const AppText('Add food item'),
            ),
            const SizedBox(height: 8),
            for (final ingredient in _ingredients)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_ingredients.length > 1)
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            tooltip: 'Remove food item',
                            visualDensity: VisualDensity.compact,
                            onPressed:
                                () => setState(() {
                                  _ingredientSearchTimers
                                      .remove(ingredient.id)
                                      ?.cancel();
                                  _ingredientResults.remove(ingredient.id);
                                  _ingredients.remove(ingredient);
                                  ingredient.dispose();
                                }),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: ingredient.name,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _searchIngredient(ingredient),
                              onChanged: (value) {
                                _queueIngredientSearch(ingredient, value);
                                setState(() {
                                  if (ingredient.source != 'Manual') {
                                    for (final field in [
                                      ingredient.kcal,
                                      ingredient.protein,
                                      ingredient.carbs,
                                      ingredient.fat,
                                      ingredient.fiber,
                                      ingredient.sugar,
                                    ]) {
                                      field.clear();
                                    }
                                  }
                                  ingredient.source = 'Manual';
                                  ingredient.referenceId = null;
                                  ingredient.quality = '';
                                  ingredient.missing = {};
                                });
                              },
                              decoration: InputDecoration(
                                labelText: _tr(
                                  context,
                                  'Food (e.g. cooked rice)',
                                ),
                                prefixIcon: const Icon(
                                  Icons.restaurant_rounded,
                                ),
                                suffixIcon: IconButton(
                                  tooltip: 'Search food nutrition',
                                  onPressed:
                                      _searchingIngredients.contains(
                                            ingredient.id,
                                          )
                                          ? null
                                          : () => _searchIngredient(ingredient),
                                  icon:
                                      _searchingIngredients.contains(
                                            ingredient.id,
                                          )
                                          ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : const Icon(Icons.search_rounded),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 112,
                            child: TextField(
                              controller: ingredient.grams,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: _tr(context, 'Amount'),
                                suffixText: 'g',
                              ),
                            ),
                          ),
                        ],
                      ),
                      if ((_ingredientResults[ingredient.id] ?? []).isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 190),
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount:
                                _ingredientResults[ingredient.id]!.length,
                            separatorBuilder:
                                (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item =
                                  _ingredientResults[ingredient.id]![index];
                              return ListTile(
                                dense: true,
                                title: AppText(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: AppText(
                                  '${item.source} · ${_number(item.nutritionPer100g.calories)} kcal / 100 g',
                                ),
                                onTap:
                                    () => _selectIngredient(ingredient, item),
                              );
                            },
                          ),
                        ),
                      if (_searchingIngredients.contains(ingredient.id))
                        const LinearProgressIndicator(minHeight: 2),
                      if (ingredient.source != 'Manual')
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: AppText(
                            '${ingredient.source}${ingredient.referenceId == null ? '' : ' · Ref ${ingredient.referenceId}'} · ${ingredient.quality}',
                            style: TextStyle(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        title: const AppText('Nutrition per 100 g'),
                        subtitle: const AppText(
                          'Filled from search, or edit manually',
                        ),
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _numField(
                                  'Calories',
                                  ingredient.kcal,
                                  unit: 'kcal',
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _numField(
                                  'Protein',
                                  ingredient.protein,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _numField(
                                  'Carbs',
                                  ingredient.carbs,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _numField(
                                  'Fat',
                                  ingredient.fat,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _numField(
                                  'Fiber',
                                  ingredient.fiber,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _numField(
                                  'Sugar',
                                  ingredient.sugar,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 6),
            TextField(
              controller: _notes,
              decoration: InputDecoration(
                labelText: _tr(context, 'Meal notes (optional)'),
                prefixIcon: const Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    'MEAL TOTAL  ·  ${_number(_mealNutrition.calories)} kcal',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    'Protein ${_number(_mealNutrition.protein)} g  ·  Carbs ${_number(_mealNutrition.carbs)} g  ·  Fat ${_number(_mealNutrition.fat)} g',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  if (_hasUnknownNutrition)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: AppText(
                        'At least one food has missing nutrients. Check its nutrition before relying on this total.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
        child: FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: AppText(
            _saving
                ? 'Saving…'
                : widget.isPlanned
                ? 'Save planned meal'
                : 'Add meal to diary',
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (widget.existing == null) return _buildMealEditor(context);
    return _buildSingleFoodEditor(context);
  }

  Widget _buildSingleFoodEditor(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: true,
    body: Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppText(
              widget.existing != null
                  ? 'Edit food'
                  : widget.isPlanned
                  ? 'Plan a food'
                  : 'Log a food',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 5),
            AppText(
              'Search online databases or enter your own values. Values below are per 100 g.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _query,
                    textInputAction: TextInputAction.search,
                    onChanged: _queueSearch,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: _tr(context, 'Search rice, ramen, yogurt…'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _searching ? null : _search,
                  child:
                      _searching
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const AppText('Search'),
                ),
              ],
            ),
            if (_searchMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: AppText(
                  _searchMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
            if (_results.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                constraints: const BoxConstraints(maxHeight: 190),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final item = _results[i];
                    return ListTile(
                      dense: true,
                      title: AppText(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: AppText(
                        '${item.source} • ${_number(item.nutritionPer100g.calories)} kcal / 100 g',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onTap: () => _select(item),
                    );
                  },
                ),
              ),
            const SizedBox(height: 14),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: _tr(context, 'Food / dish name'),
                prefixIcon: const Icon(Icons.restaurant_rounded),
              ),
            ),
            if (_source != 'Manual')
              Padding(
                padding: const EdgeInsets.only(top: 7, left: 3, right: 3),
                child: AppText(
                  'Source: $_source${_referenceId == null ? '' : ' · Ref $_referenceId'}. ${_quality.isEmpty ? 'Check preparation state and nutrition values before saving.' : _quality}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _numField('Amount eaten / planned', _grams)),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _meal,
                    decoration: InputDecoration(
                      labelText: _tr(context, 'Meal'),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Breakfast',
                        child: AppText('Breakfast'),
                      ),
                      DropdownMenuItem(value: 'Lunch', child: AppText('Lunch')),
                      DropdownMenuItem(
                        value: 'Dinner',
                        child: AppText('Dinner'),
                      ),
                      DropdownMenuItem(value: 'Snack', child: AppText('Snack')),
                    ],
                    onChanged: (v) => setState(() => _meal = v ?? 'Dinner'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _numField('Calories / 100 g', _kcal, unit: 'kcal'),
                ),
                const SizedBox(width: 10),
                Expanded(child: _numField('Protein / 100 g', _protein)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _numField('Carbs / 100 g', _carbs)),
                const SizedBox(width: 10),
                Expanded(child: _numField('Fat / 100 g', _fat)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _numField('Fiber / 100 g', _fiber)),
                const SizedBox(width: 10),
                Expanded(child: _numField('Sugar / 100 g', _sugar)),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notes,
              decoration: InputDecoration(
                labelText: _tr(context, 'Notes / preparation (optional)'),
                prefixIcon: const Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: AppText(
                _photoPath == null
                    ? 'Attach food photo (saved locally)'
                    : 'Change attached photo',
              ),
            ),
            if (_photoPath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _photoImage(
                    _photoPath!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(15),
              ),
              child: AppText(
                'For ${_number(_value(_grams) ?? 0)} g: ${_number((_value(_kcal) ?? 0) * (_value(_grams) ?? 0) / 100)} kcal  •  P ${_number((_value(_protein) ?? 0) * (_value(_grams) ?? 0) / 100)} g  •  C ${_number((_value(_carbs) ?? 0) * (_value(_grams) ?? 0) / 100)} g  •  F ${_number((_value(_fat) ?? 0) * (_value(_grams) ?? 0) / 100)} g',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
        child: FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: AppText(
            _saving
                ? 'Saving…'
                : widget.existing != null
                ? 'Save changes'
                : widget.isPlanned
                ? 'Save planned food'
                : 'Add to diary',
          ),
        ),
      ),
    ),
  );
}

class _ProgressData {
  const _ProgressData(this.logs, this.profile, this.profileConfigured);
  final List<WeightLog> logs;
  final UserProfile profile;
  final bool profileConfigured;
}

class _PlanData {
  const _PlanData(this.actual, this.planned, this.goal, this.profileConfigured);
  final List<FoodEntry> actual;
  final List<FoodEntry> planned;
  final GoalAssessment goal;
  final bool profileConfigured;
}

class _SettingsData {
  const _SettingsData(this.profile, this.profileConfigured);
  final UserProfile profile;
  final bool profileConfigured;
}

class _CaloriesCard extends StatelessWidget {
  const _CaloriesCard({
    required this.total,
    required this.target,
    required this.remaining,
    required this.planned,
    this.forecast = false,
    this.hasTarget = true,
  });
  final double total, target, remaining, planned;
  final bool forecast;
  final bool hasTarget;
  @override
  Widget build(BuildContext context) {
    final totalProgress =
        !hasTarget || target <= 0
            ? 0.0
            : (total / target).clamp(0.0, 1.0).toDouble();
    final plannedProgress =
        !hasTarget || target <= 0
            ? 0.0
            : (planned / target).clamp(0.0, totalProgress).toDouble();
    final actualProgress = totalProgress - plannedProgress;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF214F40), Color(0xFF347A60)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18214F40),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText(
                  forecast ? 'PROJECTED DAILY INTAKE' : 'CALORIES EATEN TODAY',
                  style: const TextStyle(
                    color: Color(0xFFD7E8DE),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Icon(
                forecast
                    ? Icons.event_available_rounded
                    : Icons.local_fire_department_rounded,
                color: const Color(0xFFD7E8DE),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText(
                _number(total),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 39,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 7, bottom: 5),
                child: AppText(
                  'kcal',
                  style: TextStyle(
                    color: Color(0xFFD7E8DE),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              AppText(
                hasTarget ? 'of ${_number(target)}' : 'target not set',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder:
                (context, constraints) => ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: SizedBox(
                    height: 9,
                    width: constraints.maxWidth,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ColoredBox(
                            color: Colors.white.withValues(alpha: .2),
                          ),
                        ),
                        if (actualProgress > 0)
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: constraints.maxWidth * actualProgress,
                            child: const ColoredBox(color: Color(0xFFE5DDAF)),
                          ),
                        if (plannedProgress > 0)
                          Positioned(
                            left: constraints.maxWidth * actualProgress,
                            top: 0,
                            bottom: 0,
                            width: constraints.maxWidth * plannedProgress,
                            child: const ColoredBox(color: Color(0xFF8BE0C2)),
                          ),
                      ],
                    ),
                  ),
                ),
          ),
          if (forecast && planned > 0)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE5DDAF),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const AppText(
                    'Eaten',
                    style: TextStyle(color: Color(0xFFD7E8DE), fontSize: 11),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF8BE0C2),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const AppText(
                    'Planned',
                    style: TextStyle(color: Color(0xFFD7E8DE), fontSize: 11),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 13),
          Row(
            children: [
              Icon(
                hasTarget && remaining < 0
                    ? Icons.warning_amber_rounded
                    : Icons.flag_outlined,
                size: 17,
                color: const Color(0xFFE5DDAF),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: AppText(
                  !hasTarget
                      ? 'Set your profile in Settings for a personal target'
                      : remaining >= 0
                      ? '${_number(remaining)} kcal ${forecast ? 'remaining in forecast' : 'to target'}'
                      : '${_number(remaining.abs())} kcal over estimate',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (hasTarget && planned > 0)
                AppText(
                  '+${_number(planned)} planned',
                  style: const TextStyle(
                    color: Color(0xFFD7E8DE),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroStrip extends StatelessWidget {
  const _MacroStrip({required this.nutrition});
  final Nutrition nutrition;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MacroValue(
                label: 'Protein',
                value: nutrition.protein,
                color: const Color(0xFF41846A),
              ),
            ),
            Expanded(
              child: _MacroValue(
                label: 'Carbs',
                value: nutrition.carbs,
                color: const Color(0xFFD9A345),
              ),
            ),
            Expanded(
              child: _MacroValue(
                label: 'Fat',
                value: nutrition.fat,
                color: const Color(0xFFCF7867),
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1),
        ),
        Row(
          children: [
            Expanded(
              child: AppText(
                'Fiber  ${_number(nutrition.fiber)} g',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: AppText(
                'Sugar  ${_number(nutrition.sugar)} g',
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _MacroValue extends StatelessWidget {
  const _MacroValue({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(height: 6),
      AppText(
        '${_number(value)} g',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w800,
          fontSize: 17,
        ),
      ),
      const SizedBox(height: 2),
      AppText(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
    ],
  );
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
    this.trailing,
  });
  final FoodEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final photo = entry.photoPath;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Container(
                width: 48,
                height: 48,
                color: Theme.of(context).colorScheme.secondaryContainer,
                child:
                    photo != null &&
                            (photo.startsWith('data:image/') ||
                                File(photo).existsSync())
                        ? _photoImage(photo, fit: BoxFit.cover)
                        : Icon(
                          Icons.restaurant_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  AppText(
                    '${entry.meal} • ${_number(entry.grams)} g • ${entry.source}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    '${_number(entry.nutrition.calories)} kcal  ·  P ${_number(entry.nutrition.protein)} g  ·  C ${_number(entry.nutrition.carbs)} g  ·  F ${_number(entry.nutrition.fat)} g',
                    maxLines: 2,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            IconButton(
              onPressed: onEdit,
              tooltip: 'Edit entry',
              icon: Icon(
                Icons.edit_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            IconButton(
              onPressed: onDelete,
              tooltip: 'Delete entry',
              icon: Icon(
                Icons.close_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealGroupTile extends StatelessWidget {
  const _MealGroupTile({
    required this.entries,
    required this.onEdit,
    required this.onDelete,
  });
  final List<FoodEntry> entries;
  final ValueChanged<FoodEntry> onEdit;
  final ValueChanged<FoodEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    final total = NutritionCalculator.total(entries);
    final first = entries.first;
    final languageCode = Localizations.localeOf(context).languageCode;
    final mealName = AppText.translate(first.meal, languageCode);
    final photoPaths =
        entries
            .map((entry) => entry.photoPath)
            .whereType<String>()
            .where((path) => path.isNotEmpty)
            .toList();
    final photoPath = photoPaths.isEmpty ? null : photoPaths.first;
    final hasPhoto =
        photoPath != null &&
        (photoPath.startsWith('data:image/') ||
            (!kIsWeb && File(photoPath).existsSync()));
    final itemWord = switch (languageCode) {
      'ja' => '品目',
      'zh' => '项',
      'ko' => '개',
      _ => 'items',
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 58,
            height: 48,
            child:
                hasPhoto
                    ? _photoImage(photoPath, fit: BoxFit.cover)
                    : ColoredBox(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: Icon(
                        Icons.restaurant_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
          ),
        ),
        title: AppText(
          '$mealName — ${_dateLabel(first.loggedAt, languageCode)}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: AppText(
          '${entries.length} $itemWord · ${_number(total.calories)} kcal · P ${_number(total.protein)} g · C ${_number(total.carbs)} g · F ${_number(total.fat)} g',
        ),
        children: [
          for (final entry in entries)
            ListTile(
              dense: true,
              title: AppText(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: AppText(
                '${_number(entry.grams)} g · ${_number(entry.nutrition.calories)} kcal',
              ),
              trailing: Wrap(
                spacing: 0,
                children: [
                  IconButton(
                    tooltip: 'Edit food',
                    onPressed: () => onEdit(entry),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                  IconButton(
                    tooltip: 'Remove food',
                    onPressed: () => onDelete(entry),
                    icon: const Icon(Icons.close_rounded, size: 19),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TargetInsight extends StatelessWidget {
  const _TargetInsight({
    required this.goal,
    required this.plannedCalories,
    required this.plannedCount,
    this.hasProfile = true,
  });
  final GoalAssessment goal;
  final double plannedCalories;
  final int plannedCount;
  final bool hasProfile;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color:
          hasProfile && goal.isPlausible
              ? Theme.of(context).colorScheme.secondaryContainer
              : Theme.of(context).colorScheme.tertiaryContainer,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          hasProfile && goal.isPlausible
              ? Icons.track_changes_rounded
              : Icons.info_outline_rounded,
          color:
              hasProfile && goal.isPlausible
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onTertiaryContainer,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                !hasProfile
                    ? 'Set up your body profile'
                    : goal.isPlausible
                    ? 'Estimated daily target: ${_number(goal.dailyTarget)} kcal'
                    : 'Goal needs review',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              AppText(
                !hasProfile
                    ? 'The calorie number is not personalized yet. Enter age, height, current weight, activity level and goal in Settings.'
                    : goal.isPlausible
                    ? goal.message
                    : '${goal.message} The planner uses the maintenance estimate (${_number(goal.tdee)} kcal/day) until the timeline is adjusted.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                  fontSize: 12,
                ),
              ),
              if (plannedCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: AppText(
                    'Forecast includes $plannedCount planned items (+${_number(plannedCalories)} kcal).',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.caption,
  });
  final String label, value, caption;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: .9,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          AppText(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          AppText(
            caption,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => AppText(
    text,
    style: TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w800,
      fontSize: 10,
      letterSpacing: 1.4,
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.text,
  });
  final IconData icon;
  final String title, text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 12),
        AppText(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        AppText(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

class _SourceLine extends StatelessWidget {
  const _SourceLine({required this.name, required this.detail});
  final String name, detail;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        Icons.verified_outlined,
        color: Theme.of(context).colorScheme.primary,
        size: 18,
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              name,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            AppText(
              detail,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
