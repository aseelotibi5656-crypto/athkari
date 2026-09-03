import '../../core/utils/date_utils.dart';

/// حالة سلسلة الالتزام (Streak).
///
/// السلسلة **مشتقّة دائمًا** من سجل الأيام المكتملة (history) ولا تُخزَّن كعدّاد
/// مستقل. هذا يجعلها محصّنة ضد: تغيير ساعة الجهاز، إعادة تثبيت التطبيق مع
/// استرجاع نسخة احتياطية، أو تعديل يوم قديم يدويًا.
class StreakState {
  const StreakState({
    required this.current,
    required this.best,
    required this.isTodayCompleted,
    required this.completedDays,
    this.justBroke = false,
    this.previousStreak = 0,
  });

  /// عدد الأيام المتتالية المكتملة (تنتهي باليوم أو بالأمس).
  final int current;

  /// أطول سلسلة وصل لها المستخدم.
  final int best;

  /// هل أُكمل اليوم الحالي (صباح + مساء)؟
  final bool isTodayCompleted;

  /// كل الأيام المكتملة تاريخيًا (مفاتيح "yyyy-MM-dd") — يُبنى منها التقويم.
  final Set<String> completedDays;

  /// انكسرت السلسلة للتو (نعرض رسالة تشجيعية لا محبِطة).
  final bool justBroke;

  /// قيمة السلسلة قبل الانكسار (للرسالة التشجيعية).
  final int previousStreak;

  /// السلسلة "معلّقة": مكتملة أمس ولم تُكمل اليوم بعد — أي ما زالت حيّة.
  bool get isPending => current > 0 && !isTodayCompleted;

  static const StreakState empty = StreakState(
    current: 0,
    best: 0,
    isTodayCompleted: false,
    completedDays: <String>{},
  );

  StreakState copyWith({
    int? current,
    int? best,
    bool? isTodayCompleted,
    Set<String>? completedDays,
    bool? justBroke,
    int? previousStreak,
  }) {
    return StreakState(
      current: current ?? this.current,
      best: best ?? this.best,
      isTodayCompleted: isTodayCompleted ?? this.isTodayCompleted,
      completedDays: completedDays ?? this.completedDays,
      justBroke: justBroke ?? this.justBroke,
      previousStreak: previousStreak ?? this.previousStreak,
    );
  }

  /// ==================== منطق الـ Streak ====================
  ///
  /// القاعدة: اليوم مكتمل فقط إذا أُنهيت **كل** أذكار الصباح **وكل** أذكار
  /// المساء في نفس اليوم بتوقيت الجهاز المحلي.
  ///
  /// طريقة الحساب:
  /// 1) إذا كان اليوم مكتملًا → نبدأ العدّ من اليوم ونرجع للخلف.
  /// 2) وإلا، إذا كان الأمس مكتملًا → السلسلة ما زالت حيّة، نعدّ من الأمس
  ///    (المستخدم أمامه بقية اليوم ليُكملها).
  /// 3) وإلا → السلسلة صفر (فات يوم كامل بلا إكمال).
  ///
  /// نتوقف عند أول فجوة، والعدّ يتم على مفاتيح تواريخ محلية مُطبَّعة، لذلك
  /// التوقيت الصيفي أو اختلاف عدد ساعات اليوم لا يؤثر عليه.
  static int calculateCurrentStreak(
    Set<String> completedDays, {
    DateTime? now,
  }) {
    if (completedDays.isEmpty) return 0;

    final DateTime today = AppDateUtils.dayOf(now ?? DateTime.now());
    final String todayKey = AppDateUtils.keyOf(today);
    final String yesterdayKey =
        AppDateUtils.keyOf(AppDateUtils.addDays(today, -1));

    DateTime cursor;
    if (completedDays.contains(todayKey)) {
      cursor = today;
    } else if (completedDays.contains(yesterdayKey)) {
      cursor = AppDateUtils.addDays(today, -1);
    } else {
      // فات يوم كامل (أو أكثر) بدون إكمال → السلسلة انتهت.
      return 0;
    }

    int streak = 0;
    while (completedDays.contains(AppDateUtils.keyOf(cursor))) {
      streak++;
      cursor = AppDateUtils.addDays(cursor, -1);
      // حدّ أمان يمنع أي حلقة لا نهائية ببيانات تالفة.
      if (streak > 100000) break;
    }
    return streak;
  }

  /// أطول سلسلة في السجل كله (تُحسب مرة واحدة عند التحميل).
  static int calculateBestStreak(Set<String> completedDays) {
    if (completedDays.isEmpty) return 0;

    final List<DateTime> days = completedDays
        .map(AppDateUtils.parseKey)
        .whereType<DateTime>()
        .toList()
      ..sort();

    int best = 1;
    int run = 1;
    for (int i = 1; i < days.length; i++) {
      final int gap = AppDateUtils.daysBetween(days[i - 1], days[i]);
      if (gap == 1) {
        run++;
        if (run > best) best = run;
      } else if (gap > 1) {
        run = 1;
      }
      // gap == 0 مستحيل لأن المفاتيح فريدة داخل Set.
    }
    return best;
  }
}
