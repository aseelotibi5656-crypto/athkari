import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/streak_model.dart';
import '../data/repositories/progress_repository.dart';
import 'repository_providers.dart';

/// يدير حالة سلسلة الالتزام.
///
/// لا يحتفظ بعدّاد مستقل: كل قيمة تُشتقّ من سجلّ الأيام المكتملة المخزَّن
/// محليًا. ما يُخزَّن فعلًا هو:
///   • أفضل سلسلة (best) — للعرض فقط، ولا تنقص.
///   • آخر سلسلة رآها المستخدم (lastSeenStreak) — لاكتشاف الانكسار مرة واحدة.
class StreakNotifier extends StateNotifier<StreakState> {
  StreakNotifier(this._repository) : super(StreakState.empty) {
    recalculate();
  }

  final ProgressRepository _repository;

  /// إعادة حساب السلسلة من السجل المحلي.
  ///
  /// تُستدعى: عند الإقلاع، بعد كل تغيير في التقدّم، وعند عودة التطبيق من
  /// الخلفية (لأن اليوم قد يكون تغيّر أثناء غياب المستخدم).
  Future<void> recalculate() async {
    final Set<String> completedDays = _repository.completedDays();
    final int current = StreakState.calculateCurrentStreak(completedDays);
    final bool isTodayCompleted = _repository.todayProgress().isFullyCompleted;

    // أفضل سلسلة: الأكبر بين المحسوب من السجل والمحفوظ سابقًا.
    final int computedBest = StreakState.calculateBestStreak(completedDays);
    final int storedBest = _repository.bestStreak;
    final int best = current > computedBest
        ? current
        : (computedBest > storedBest ? computedBest : storedBest);
    if (best != storedBest) {
      await _repository.saveBestStreak(best);
    }

    // اكتشاف انكسار السلسلة: كان للمستخدم سلسلة، والآن أصبحت صفرًا.
    final int lastSeen = _repository.lastSeenStreak;
    final bool justBroke = lastSeen > 0 && current == 0;

    state = StreakState(
      current: current,
      best: best,
      isTodayCompleted: isTodayCompleted,
      completedDays: completedDays,
      justBroke: justBroke,
      previousStreak: justBroke ? lastSeen : 0,
    );

    // نحفظ القيمة الحالية حتى لا تتكرر رسالة الانكسار في كل مرة.
    if (lastSeen != current) {
      await _repository.saveLastSeenStreak(current);
    }
  }

  /// إخفاء رسالة "انكسرت السلسلة" بعد عرضها للمستخدم.
  void dismissBreakNotice() {
    if (!state.justBroke) return;
    state = state.copyWith(justBroke: false, previousStreak: 0);
  }
}

final StateNotifierProvider<StreakNotifier, StreakState> streakProvider =
    StateNotifierProvider<StreakNotifier, StreakState>(
  (Ref ref) => StreakNotifier(ref.watch(progressRepositoryProvider)),
);

/// رسالة تحفيزية تتغيّر حسب حالة السلسلة.
String streakMessage(StreakState streak) {
  if (streak.justBroke) {
    return 'ما عليك، ابدأ من جديد 🤍';
  }
  if (streak.current == 0) {
    return 'ابدأ سلسلتك اليوم';
  }
  if (streak.isTodayCompleted) {
    if (streak.current == 1) return 'بداية موفّقة — أكملت يومك 🤍';
    if (streak.current >= 30) return 'ما شاء الله، شهر كامل من الالتزام';
    if (streak.current >= 7) return 'أسبوع فأكثر بلا انقطاع، واصل';
    return 'أكملت يومك، بارك الله فيك';
  }
  return 'سلسلتك محفوظة — أكمل أذكار اليوم لتستمر';
}
