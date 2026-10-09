import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'data/app_database.dart';
import 'services/backup_service.dart';
import 'services/food_search_service.dart';
import 'ui/screens.dart';
import 'ui/app_text.dart';
import 'ui/legal_documents.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.database;
  final appearance = await AppDatabase.instance.readMeta('appearance');
  final savedMode = appearance?['themeMode'];
  final preferences = await AppDatabase.instance.readMeta('preferences') ?? {};
  final firstLaunch =
      await AppDatabase.instance.readMeta('setupComplete') == null;
  final consent = await AppDatabase.instance.readMeta('legalConsent');
  final consentRequired = consent?['version'] != LegalDocuments.version;
  final mode = ThemeMode.values.firstWhere(
    (value) => value.name == savedMode,
    orElse: () => ThemeMode.system,
  );
  runApp(
    NutriDiaryApp(
      initialThemeMode: mode,
      initialPreferences: preferences,
      firstLaunch: firstLaunch,
      consentRequired: consentRequired,
    ),
  );
}

class NutriDiaryApp extends StatefulWidget {
  const NutriDiaryApp({
    super.key,
    this.initialThemeMode = ThemeMode.system,
    this.initialPreferences = const {},
    this.firstLaunch = false,
    this.consentRequired = false,
  });

  final ThemeMode initialThemeMode;
  final Map<String, dynamic> initialPreferences;
  final bool firstLaunch;
  final bool consentRequired;

  @override
  State<NutriDiaryApp> createState() => _NutriDiaryAppState();
}

class _NutriDiaryAppState extends State<NutriDiaryApp> {
  late ThemeMode _themeMode = widget.initialThemeMode;
  late Map<String, dynamic> _preferences = Map.of(widget.initialPreferences);
  Timer? _splashTimer;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _splashTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    await AppDatabase.instance.saveMeta('appearance', {'themeMode': mode.name});
  }

  Future<void> _setPreferences(Map<String, dynamic> preferences) async {
    setState(() => _preferences = Map.of(preferences));
    await AppDatabase.instance.saveMeta('preferences', preferences);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '食誌',
      debugShowCheckedModeBanner: false,
      locale: Locale('${_preferences['language'] ?? 'en'}'),
      supportedLocales: const [
        Locale('en'),
        Locale('ja'),
        Locale('zh'),
        Locale('ko'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home:
          _showSplash
              ? const _LaunchSplash()
              : AppShell(
                themeMode: _themeMode,
                onThemeModeChanged: _setThemeMode,
                preferences: _preferences,
                onPreferencesChanged: _setPreferences,
                firstLaunch: widget.firstLaunch,
                consentRequired: widget.consentRequired,
              ),
    );
  }
}

ThemeData _buildTheme(Brightness brightness) {
  const leaf = Color(0xFF48C765);
  final dark = brightness == Brightness.dark;
  final colors = ColorScheme.fromSeed(
    seedColor: leaf,
    brightness: brightness,
  ).copyWith(
    primary: dark ? const Color(0xFFA7EF79) : const Color(0xFF258A43),
    onPrimary: dark ? const Color(0xFF152017) : Colors.white,
    secondary: dark ? const Color(0xFF91D9AE) : const Color(0xFF4C9F62),
    surface: dark ? const Color(0xFF17201A) : const Color(0xFFFBFFFA),
    onSurface: dark ? const Color(0xFFEAF2E9) : const Color(0xFF18382F),
    onSurfaceVariant: dark ? const Color(0xFFB3C0B5) : const Color(0xFF66766B),
    outlineVariant: dark ? const Color(0xFF35443A) : const Color(0xFFDCE8DC),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    brightness: brightness,
    scaffoldBackgroundColor:
        dark ? const Color(0xFF0D130F) : const Color(0xFFF1F8EF),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.surface.withValues(alpha: .76),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 23,
        fontWeight: FontWeight.w800,
        color: colors.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: colors.surface.withValues(alpha: dark ? .94 : .86),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: .55)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.surface.withValues(alpha: .78),
      surfaceTintColor: Colors.transparent,
      indicatorColor: colors.primary.withValues(alpha: dark ? .22 : .16),
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight:
              states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF202B23) : const Color(0xFFF6FAF4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: colors.outlineVariant.withValues(alpha: .6),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surface.withValues(alpha: .96),
      modalBackgroundColor: colors.surface.withValues(alpha: .96),
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _LaunchSplash extends StatefulWidget {
  const _LaunchSplash();

  @override
  State<_LaunchSplash> createState() => _LaunchSplashState();
}

class _LaunchSplashState extends State<_LaunchSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder:
              (context, child) => Opacity(
                opacity: Curves.easeOut.transform(_controller.value),
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - _controller.value)),
                  child: Transform.scale(
                    scale:
                        .88 +
                        .12 * Curves.easeOutBack.transform(_controller.value),
                    child: child,
                  ),
                ),
              ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: .22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: .14),
                      blurRadius: 34,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CustomPaint(
                  size: const Size(56, 56),
                  painter: _LeafMarkPainter(colors.primary),
                ),
              ),
              const SizedBox(height: 20),
              AppText(
                '食誌',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 31,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 5,
                ),
              ),
              const SizedBox(height: 5),
              AppText(
                'A GENTLER WAY TO KEEP TRACK',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeafMarkPainter extends CustomPainter {
  const _LeafMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    final stem =
        Path()
          ..moveTo(size.width * .5, size.height * .84)
          ..cubicTo(
            size.width * .5,
            size.height * .62,
            size.width * .5,
            size.height * .36,
            size.width * .56,
            size.height * .17,
          );
    canvas.drawPath(stem, paint);
    final leftLeaf =
        Path()
          ..moveTo(size.width * .49, size.height * .62)
          ..cubicTo(
            size.width * .18,
            size.height * .62,
            size.width * .16,
            size.height * .36,
            size.width * .21,
            size.height * .32,
          )
          ..cubicTo(
            size.width * .38,
            size.height * .31,
            size.width * .48,
            size.height * .42,
            size.width * .49,
            size.height * .62,
          );
    canvas.drawPath(leftLeaf, paint);
    final rightLeaf =
        Path()
          ..moveTo(size.width * .52, size.height * .44)
          ..cubicTo(
            size.width * .55,
            size.height * .18,
            size.width * .81,
            size.height * .12,
            size.width * .84,
            size.height * .16,
          )
          ..cubicTo(
            size.width * .84,
            size.height * .35,
            size.width * .68,
            size.height * .45,
            size.width * .52,
            size.height * .44,
          );
    canvas.drawPath(rightLeaf, paint);
  }

  @override
  bool shouldRepaint(_LeafMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}

String _headerDate(DateTime date, String languageCode) {
  if (languageCode == 'ja') {
    return '${date.year}年 ${date.month}月 ${date.day}日';
  }
  if (languageCode == 'zh') {
    return '${date.year}年${date.month}月${date.day}日';
  }
  if (languageCode == 'ko') {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
  const months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.preferences,
    required this.onPreferencesChanged,
    this.firstLaunch = false,
    this.consentRequired = false,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final Map<String, dynamic> preferences;
  final Future<void> Function(Map<String, dynamic>) onPreferencesChanged;
  final bool firstLaunch;
  final bool consentRequired;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _selected = 0;
  late final ValueNotifier<String> _displayName = ValueNotifier(
    '${widget.preferences['displayName'] ?? ''}',
  );
  DateTime _displayDate = DateTime.now();
  Timer? _dateRefreshTimer;
  final _db = AppDatabase.instance;
  final _foodSearch = FoodSearchService();
  late final _backup = BackupService(_db);
  bool _setupPromptShown = false;

  Future<void> _saveDisplayName(String name) async {
    final preferences = {...widget.preferences, 'displayName': name.trim()};
    await _db.saveMeta('preferences', preferences);
    if (mounted) _displayName.value = name.trim();
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final restoredName = '${widget.preferences['displayName'] ?? ''}';
    if (restoredName != _displayName.value) {
      _displayName.value = restoredName;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dateRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshDate(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _showStartupPrompts());
  }

  Future<void> _showStartupPrompts() async {
    if (_setupPromptShown || !mounted) return;
    _setupPromptShown = true;
    if (widget.consentRequired || widget.firstLaunch) {
      final accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => LegalConsentDialog(
              language: Localizations.localeOf(context).languageCode,
            ),
      );
      if (accepted != true || !mounted) return;
      await _db.saveMeta('legalConsent', {
        'version': LegalDocuments.version,
        'acceptedAt': DateTime.now().toIso8601String(),
      });
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    if ((widget.firstLaunch || _displayName.value.trim().isEmpty) && mounted) {
      final controller = TextEditingController();
      final name = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: const AppText('What should we call you?'),
              content: TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                maxLength: 32,
                decoration: const InputDecoration(labelText: 'Your name'),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    Navigator.pop(context, value.trim());
                  }
                },
              ),
              actions: [
                FilledButton(
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      Navigator.pop(context, controller.text.trim());
                    }
                  },
                  child: const AppText('Continue'),
                ),
              ],
            ),
      );
      controller.dispose();
      if (name != null && mounted) {
        try {
          await _saveDisplayName(name);
        } catch (error) {
          _displayName.value = name;
          await Future<void>.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            await showDialog<void>(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const AppText('Name was not saved'),
                    content: Text('$error'),
                    actions: [
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const AppText('Continue'),
                      ),
                    ],
                  ),
            );
          }
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    if (!widget.firstLaunch || !mounted) return;
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const AppText('Set up your private diary'),
            content: const AppText(
              kIsWeb
                  ? 'Your diary will be stored in this browser’s private site storage (IndexedDB). Clearing browser site data can delete it. Create an encrypted backup to move it to another device.'
                  : '食誌 will create its data folder inside the app’s private storage. Other ordinary apps cannot browse this folder. Use encrypted backups to move your diary to another device.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const AppText('Continue'),
              ),
            ],
          ),
    );
    if (accepted == true && mounted) {
      await _db.saveMeta('setupComplete', {'done': true});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshDate();
  }

  void _refreshDate() {
    final now = DateTime.now();
    if (now.year != _displayDate.year ||
        now.month != _displayDate.month ||
        now.day != _displayDate.day) {
      setState(() => _displayDate = now);
    }
  }

  @override
  void dispose() {
    _dateRefreshTimer?.cancel();
    _displayName.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    _foodSearch.countryCode = '${widget.preferences['country'] ?? 'JP'}';
    final languageCode = Localizations.localeOf(context).languageCode;
    final titles =
        [
          'Home',
          'Diary',
          'Plan',
          'Progress',
          'Settings',
        ].map((title) => AppText.translate(title, languageCode)).toList();
    final colors = Theme.of(context).colorScheme;
    final pages = [
      HomeScreen(key: const ValueKey('home'), db: _db),
      DiaryScreen(
        key: const ValueKey('diary'),
        db: _db,
        foodSearch: _foodSearch,
        onChanged: _changed,
      ),
      PlannerScreen(
        key: const ValueKey('planner'),
        db: _db,
        foodSearch: _foodSearch,
        onChanged: _changed,
      ),
      ProgressScreen(
        key: const ValueKey('progress'),
        db: _db,
        onChanged: _changed,
      ),
      SettingsScreen(
        key: const ValueKey('settings'),
        db: _db,
        backup: _backup,
        onChanged: _changed,
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        preferences: {...widget.preferences, 'displayName': _displayName.value},
        displayName: _displayName,
        onDisplayNameChanged: _saveDisplayName,
        onPreferencesChanged: widget.onPreferencesChanged,
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CustomPaint(
                  size: const Size(24, 24),
                  painter: _LeafMarkPainter(colors.primary),
                ),
              ),
            ),
            const SizedBox(width: 9),
            AppText(
              '食誌',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 9),
            Container(height: 20, width: 1, color: colors.outlineVariant),
            const SizedBox(width: 9),
            Flexible(
              child: ValueListenableBuilder<String>(
                valueListenable: _displayName,
                builder:
                    (context, name, _) => AppText(
                      name.isEmpty ? titles[_selected] : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              ),
            ),
          ],
        ),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: ColoredBox(color: colors.surface.withValues(alpha: .72)),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: AppText(
                _headerDate(_displayDate, languageCode),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .5,
                  color: colors.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(child: IndexedStack(index: _selected, children: pages)),
      floatingActionButton:
          _selected == 0
              ? FloatingActionButton(
                tooltip: AppText.translate('Log food', languageCode),
                onPressed: () async {
                  final added = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder:
                        (_) => AddFoodSheet(
                          db: _db,
                          foodSearch: _foodSearch,
                          loggedAt: DateTime.now(),
                          isPlanned: false,
                        ),
                  );
                  if (added == true) _changed();
                },
                child: const Icon(Icons.add_rounded),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: NavigationBar(
            selectedIndex: _selected,
            onDestinationSelected: (index) => setState(() => _selected = index),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.dashboard_outlined),
                selectedIcon: const Icon(Icons.dashboard_rounded),
                label: AppText.translate('Home', languageCode),
              ),
              NavigationDestination(
                icon: const Icon(Icons.menu_book_outlined),
                selectedIcon: const Icon(Icons.menu_book_rounded),
                label: AppText.translate('Diary', languageCode),
              ),
              NavigationDestination(
                icon: const Icon(Icons.restaurant_menu_outlined),
                selectedIcon: const Icon(Icons.restaurant_menu_rounded),
                label: AppText.translate('Plan', languageCode),
              ),
              NavigationDestination(
                icon: const Icon(Icons.insights_outlined),
                selectedIcon: const Icon(Icons.insights_rounded),
                label: AppText.translate('Progress', languageCode),
              ),
              NavigationDestination(
                icon: const Icon(Icons.tune_rounded),
                selectedIcon: const Icon(Icons.tune_rounded),
                label: AppText.translate('Settings', languageCode),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
