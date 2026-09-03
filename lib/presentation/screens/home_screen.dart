import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/day_progress_model.dart';
import '../../data/models/dhikr_model.dart';
import '../../data/models/streak_model.dart';
import '../../providers/adhkar_provider.dart';
import '../../providers/streak_provider.dart';
import '../widgets/category_card.dart';
import '../widgets/month_calendar.dart';
import '../widgets/streak_badge.dart';
import 'adhkar_screen.dart';
import 'settings_screen.dart';

/// الشاشة الرئيسية: عدّاد السلسلة، كرتا الصباح والمساء، والتقويم الشهري.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // عند العودة من الخلفية قد يكون اليوم تغيّر (منتصف الليل مرّ)،
    // فنعيد تحميل تقدّم اليوم وحساب السلسلة.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    ref.read(dayProgressProvider.notifier).syncWithToday();
    ref.read(streakProvider.notifier).recalculate();
  }

  /// الفئة المقترحة حسب ساعة اليوم: قبل الظهر → الصباح، بعده → المساء.
  AdhkarCategory get _suggestedCategory =>
      DateTime.now().hour < 12 ? AdhkarCategory.morning : AdhkarCategory.evening;

  void _openCategory(AdhkarCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdhkarScreen(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StreakState streak = ref.watch(streakProvider);
    final DayProgress progress = ref.watch(dayProgressProvider);
    final AsyncValue<Map<AdhkarCategory, AdhkarCollection>> collections =
        ref.watch(allAdhkarProvider);

    // عرض رسالة تشجيعية (لا محبِطة) عند انكسار السلسلة.
    ref.listen<StreakState>(streakProvider, (StreakState? previous, StreakState next) {
      if (next.justBroke) _showStreakBreakMessage(next);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppInfo.appName),
        actions: <Widget>[
          IconButton(
            tooltip: 'الإعدادات',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: <Widget>[
              StreakBadge(streak: streak),
              const SizedBox(height: 22),
              Text(
                'أذكار اليوم',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              collections.when(
                loading: () => const _CategoriesPlaceholder(),
                error: (Object error, StackTrace stack) => _ErrorBox(
                  message: 'تعذّر تحميل الأذكار',
                  onRetry: () => ref.invalidate(allAdhkarProvider),
                ),
                data: (Map<AdhkarCategory, AdhkarCollection> data) => Column(
                  children: <Widget>[
                    for (final AdhkarCategory category
                        in AdhkarCategory.values) ...<Widget>[
                      CategoryCard(
                        category: category,
                        progress:
                            categoryProgressRatio(progress, data[category]),
                        completedCount:
                            completedDhikrCount(progress, data[category]),
                        totalCount: data[category]?.items.length ?? 0,
                        isCompleted: progress.completedFor(category),
                        isSuggested: category == _suggestedCategory,
                        onTap: () => _openCategory(category),
                      ),
                      if (category != AdhkarCategory.values.last)
                        const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _TodayStatusBanner(progress: progress),
              const SizedBox(height: 22),
              Text(
                'سجلّ الالتزام',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              MonthCalendar(completedDays: streak.completedDays),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  AppInfo.madeBy,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// رسالة انكسار السلسلة — تشجيعية لا محبِطة.
  ///
  /// نؤجّلها إلى ما بعد اكتمال الإطار، لأن `ref.listen` قد يُستدعى أثناء بناء
  /// الشجرة، ولا يجوز تعديل حالة provider أو عرض SnackBar في تلك اللحظة.
  void _showStreakBreakMessage(StreakState streak) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(streakProvider.notifier).dismissBreakNotice();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(
            'ما عليك، ابدأ من جديد 🤍  '
            '(أطول سلسلة لك: ${AppDateUtils.toArabicDigits('${streak.best}')})',
          ),
        ),
      );
    });
  }
}

/// شريط يلخّص حالة اليوم أسفل الكرتين.
class _TodayStatusBanner extends StatelessWidget {
  const _TodayStatusBanner({required this.progress});

  final DayProgress progress;

  @override
  Widget build(BuildContext context) {
    final bool done = progress.isFullyCompleted;
    final bool half = progress.morningCompleted || progress.eveningCompleted;

    final String message = done
        ? 'اكتمل يومك — تقبّل الله منك 🤍'
        : half
            ? 'بقي عليك جزء واحد لإكمال اليوم'
            : 'أكمل أذكار الصباح والمساء ليُحتسب يومك';

    final Color color = done ? AppColors.success : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            done ? Icons.verified_rounded : Icons.info_outline_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: AppFonts.ui,
                fontSize: 13,
                height: 1.6,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesPlaceholder extends StatelessWidget {
  const _CategoriesPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List<Widget>.generate(
        2,
        (int index) => Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: AppTheme.cardDecoration(context),
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        children: <Widget>[
          Text(message, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
