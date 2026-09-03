import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/day_progress_model.dart';
import '../../data/models/dhikr_model.dart';
import '../../providers/adhkar_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/streak_provider.dart';
import '../widgets/dhikr_card.dart';
import '../widgets/progress_bar.dart';

/// شاشة موحّدة لعرض أذكار فئة واحدة (صباح أو مساء).
class AdhkarScreen extends ConsumerStatefulWidget {
  const AdhkarScreen({super.key, required this.category});

  final AdhkarCategory category;

  @override
  ConsumerState<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends ConsumerState<AdhkarScreen> {
  final ScrollController _scrollController = ScrollController();

  /// نمنع تكرار رسالة الإكمال إذا واصل المستخدم الضغط.
  bool _celebrationShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dayProgressProvider.notifier).syncWithToday();
      if (ref.read(settingsProvider).keepScreenOn) {
        WakelockPlus.enable();
      }
    });
  }

  @override
  void dispose() {
    // نُطفئ إبقاء الشاشة مضاءة عند مغادرة الشاشة مهما كان سبب الخروج.
    WakelockPlus.disable();
    _scrollController.dispose();
    super.dispose();
  }

  Color get _accent => AppColors.accentFor(widget.category.key);

  Future<void> _handleOutcome(DhikrTapOutcome outcome) async {
    switch (outcome) {
      case DhikrTapOutcome.dayCompleted:
        if (_celebrationShown) return;
        _celebrationShown = true;
        await _showDayCompletedDialog();
      case DhikrTapOutcome.categoryCompleted:
        if (_celebrationShown) return;
        _celebrationShown = true;
        _showCategoryCompletedMessage();
      case DhikrTapOutcome.dhikrCompleted:
      case DhikrTapOutcome.counted:
        break;
    }
  }

  void _showCategoryCompletedMessage() {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Text(
          'أتممت ${widget.category.label} — تقبّل الله منك 🤍\n'
          'أكمل الجزء الآخر ليُحتسب يومك في السلسلة',
        ),
      ),
    );
  }

  Future<void> _showDayCompletedDialog() async {
    if (!mounted) return;
    HapticFeedback.heavyImpact();

    final int streak = ref.read(streakProvider).current;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('🔥', style: TextStyle(fontSize: 46)),
              const SizedBox(height: 12),
              Text(
                'اكتمل يومك',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'أتممت أذكار الصباح والمساء.\n'
                'سلسلتك الآن '
                '${AppDateUtils.toArabicDigits('$streak')} '
                '${streak == 1 ? 'يوم' : 'يومًا'} متتالية.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('الحمد لله'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmReset(AdhkarCollection collection) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إعادة العدّادات'),
        content: Text(
          'سيُعاد ضبط عدّادات ${widget.category.label} لهذا اليوم فقط. '
          'سجلّ الأيام السابقة لن يتأثر.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('إعادة'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref
        .read(dayProgressProvider.notifier)
        .resetCategory(widget.category, collection);
    _celebrationShown = false;
  }

  void _showTextSizeSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return Consumer(
          builder: (BuildContext context, WidgetRef ref, _) {
            final double scale = ref.watch(settingsProvider).textScale;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'حجم خط الذكر',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
                    textAlign: TextAlign.center,
                    style: AppTheme.dhikrTextStyle(context, scale: scale),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      const Text('أ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Slider(
                          value: scale,
                          min: 0.8,
                          max: 1.6,
                          divisions: 8,
                          activeColor: _accent,
                          onChanged: (double value) => ref
                              .read(settingsProvider.notifier)
                              .setTextScale(value),
                        ),
                      ),
                      const Text('أ', style: TextStyle(fontSize: 24)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AdhkarCollection> collectionAsync =
        ref.watch(adhkarCollectionProvider(widget.category));
    final DayProgress progress = ref.watch(dayProgressProvider);
    final SettingsState settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.label),
        actions: <Widget>[
          IconButton(
            tooltip: 'حجم الخط',
            icon: const Icon(Icons.format_size_rounded),
            onPressed: _showTextSizeSheet,
          ),
          collectionAsync.maybeWhen(
            data: (AdhkarCollection collection) => IconButton(
              tooltip: 'إعادة العدّادات',
              icon: const Icon(Icons.restart_alt_rounded),
              onPressed: () => _confirmReset(collection),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: collectionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'تعذّر تحميل الأذكار',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(
                      adhkarCollectionProvider(widget.category)),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
        data: (AdhkarCollection collection) => _buildBody(
          collection,
          progress,
          settings,
        ),
      ),
    );
  }

  Widget _buildBody(
    AdhkarCollection collection,
    DayProgress progress,
    SettingsState settings,
  ) {
    final double ratio = categoryProgressRatio(progress, collection);
    final int completed = completedDhikrCount(progress, collection);

    return Column(
      children: <Widget>[
        // شريط التقدّم ثابت أعلى الشاشة أثناء التمرير.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: AdhkarProgressBar(
            value: ratio,
            completed: completed,
            total: collection.items.length,
            color: _accent,
          ),
        ),
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
            itemCount: collection.items.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              if (index == collection.items.length) {
                return _FooterNote(source: collection.source);
              }

              final Dhikr dhikr = collection.items[index];
              return DhikrCard(
                dhikr: dhikr,
                index: index,
                count: progress.countFor(dhikr.id),
                accent: _accent,
                hapticsEnabled: settings.hapticsEnabled,
                textScale: settings.textScale,
                onTap: () async {
                  final DhikrTapOutcome outcome = await ref
                      .read(dayProgressProvider.notifier)
                      .increment(widget.category, dhikr, collection);
                  await _handleOutcome(outcome);
                },
                onComplete: () async {
                  final DhikrTapOutcome outcome = await ref
                      .read(dayProgressProvider.notifier)
                      .completeDhikr(widget.category, dhikr, collection);
                  await _handleOutcome(outcome);
                },
                onUndo: () {
                  _celebrationShown = false;
                  ref
                      .read(dayProgressProvider.notifier)
                      .decrement(widget.category, dhikr, collection);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        children: <Widget>[
          Text(
            'المصدر: $source',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'اضغط على الكرت لتنقص العدّاد، أو اضغط مطوّلًا لإكمال الذكر دفعة واحدة.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
