import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/utils/date_utils.dart';
import '../data/models/day_progress_model.dart';
import '../data/models/dhikr_model.dart';
import '../data/repositories/progress_repository.dart';
import 'repository_providers.dart';
import 'streak_provider.dart';

/// تحميل فئة أذكار واحدة من الملف المحلي.
final FutureProviderFamily<AdhkarCollection, AdhkarCategory>
    adhkarCollectionProvider =
    FutureProvider.family<AdhkarCollection, AdhkarCategory>(
  (Ref ref, AdhkarCategory category) =>
      ref.watch(adhkarRepositoryProvider).load(category),
);

/// تحميل الفئتين معًا (تحتاجهما الشاشة الرئيسية لحساب نِسَب الإنجاز).
final FutureProvider<Map<AdhkarCategory, AdhkarCollection>> allAdhkarProvider =
    FutureProvider<Map<AdhkarCategory, AdhkarCollection>>(
  (Ref ref) => ref.watch(adhkarRepositoryProvider).loadAll(),
);

/// نتيجة الضغط على ذكر — تستخدمها الواجهة لعرض الاحتفاء المناسب.
enum DhikrTapOutcome {
  /// نقص العدّاد فقط.
  counted,

  /// اكتمل هذا الذكر بالذات.
  dhikrCompleted,

  /// اكتملت الفئة كاملة (كل أذكار الصباح مثلًا).
  categoryCompleted,

  /// اكتمل اليوم كاملًا (صباح + مساء) → السلسلة زادت.
  dayCompleted,
}

/// يدير تقدّم اليوم الحالي.
///
/// كل تغيير يُحفظ فورًا في Hive (offline-first) ثم يُعاد حساب السلسلة.
class DayProgressNotifier extends StateNotifier<DayProgress> {
  DayProgressNotifier(this._repository, this._ref)
      : super(_repository.todayProgress());

  final ProgressRepository _repository;
  final Ref _ref;

  /// إعادة التحميل إذا تغيّر اليوم (مثلًا بقي التطبيق مفتوحًا بعد منتصف الليل).
  ///
  /// بدون هذه الخطوة، سيظل المستخدم يعدّل تقدّم يوم الأمس دون أن يشعر.
  bool syncWithToday() {
    final String todayKey = AppDateUtils.todayKey();
    if (state.dateKey == todayKey) return false;
    state = _repository.dayProgress(todayKey);
    _ref.read(streakProvider.notifier).recalculate();
    return true;
  }

  /// زيادة عدّاد ذكر بمقدار واحد (حتى الوصول إلى عدد التكرار المطلوب).
  Future<DhikrTapOutcome> increment(
    AdhkarCategory category,
    Dhikr dhikr,
    AdhkarCollection collection,
  ) async {
    syncWithToday();

    final int currentCount = state.countFor(dhikr.id);
    if (currentCount >= dhikr.repeat) {
      return DhikrTapOutcome.dhikrCompleted;
    }

    final int nextCount = currentCount + 1;
    DayProgress next = state.withCount(dhikr.id, nextCount);

    final bool dhikrDone = nextCount >= dhikr.repeat;
    final bool categoryDone =
        dhikrDone && _isCategoryComplete(next, collection);

    final bool wasDayComplete = state.isFullyCompleted;

    if (categoryDone) {
      next = next.copyWith(
        morningCompleted: category == AdhkarCategory.morning
            ? true
            : next.morningCompleted,
        eveningCompleted: category == AdhkarCategory.evening
            ? true
            : next.eveningCompleted,
        updatedAt: DateTime.now(),
      );
    }

    state = next;
    await _repository.saveDayProgress(next);
    await _ref.read(streakProvider.notifier).recalculate();

    if (!wasDayComplete && next.isFullyCompleted) {
      return DhikrTapOutcome.dayCompleted;
    }
    if (categoryDone) return DhikrTapOutcome.categoryCompleted;
    if (dhikrDone) return DhikrTapOutcome.dhikrCompleted;
    return DhikrTapOutcome.counted;
  }

  /// إنقاص عدّاد ذكر (للتراجع عن ضغطة بالخطأ).
  Future<void> decrement(
    AdhkarCategory category,
    Dhikr dhikr,
    AdhkarCollection collection,
  ) async {
    syncWithToday();

    final int currentCount = state.countFor(dhikr.id);
    if (currentCount <= 0) return;

    DayProgress next = state.withCount(dhikr.id, currentCount - 1);
    // إذا لم تعد الفئة مكتملة، نرفع علامة الإكمال عنها.
    if (!_isCategoryComplete(next, collection)) {
      next = next.copyWith(
        morningCompleted: category == AdhkarCategory.morning
            ? false
            : next.morningCompleted,
        eveningCompleted: category == AdhkarCategory.evening
            ? false
            : next.eveningCompleted,
        updatedAt: DateTime.now(),
      );
    }

    state = next;
    await _repository.saveDayProgress(next);
    await _ref.read(streakProvider.notifier).recalculate();
  }

  /// إكمال ذكر دفعة واحدة (ضغطة مطوّلة) — مفيد لأذكار المئة تسبيحة.
  Future<DhikrTapOutcome> completeDhikr(
    AdhkarCategory category,
    Dhikr dhikr,
    AdhkarCollection collection,
  ) async {
    syncWithToday();

    if (state.countFor(dhikr.id) >= dhikr.repeat) {
      return DhikrTapOutcome.dhikrCompleted;
    }

    final bool wasDayComplete = state.isFullyCompleted;
    DayProgress next = state.withCount(dhikr.id, dhikr.repeat);
    final bool categoryDone = _isCategoryComplete(next, collection);

    if (categoryDone) {
      next = next.copyWith(
        morningCompleted:
            category == AdhkarCategory.morning ? true : next.morningCompleted,
        eveningCompleted:
            category == AdhkarCategory.evening ? true : next.eveningCompleted,
        updatedAt: DateTime.now(),
      );
    }

    state = next;
    await _repository.saveDayProgress(next);
    await _ref.read(streakProvider.notifier).recalculate();

    if (!wasDayComplete && next.isFullyCompleted) {
      return DhikrTapOutcome.dayCompleted;
    }
    if (categoryDone) return DhikrTapOutcome.categoryCompleted;
    return DhikrTapOutcome.dhikrCompleted;
  }

  /// تصفير فئة كاملة لليوم الحالي (إعادة القراءة من البداية).
  Future<void> resetCategory(
    AdhkarCategory category,
    AdhkarCollection collection,
  ) async {
    syncWithToday();

    final DayProgress next = state.withCategoryReset(
      collection.items.map((Dhikr d) => d.id),
      category,
    );
    state = next;
    await _repository.saveDayProgress(next);
    await _ref.read(streakProvider.notifier).recalculate();
  }

  /// هل أُنجزت كل أذكار الفئة بالكامل في هذا اليوم؟
  bool _isCategoryComplete(DayProgress progress, AdhkarCollection collection) {
    for (final Dhikr dhikr in collection.items) {
      if (progress.countFor(dhikr.id) < dhikr.repeat) return false;
    }
    return true;
  }
}

final StateNotifierProvider<DayProgressNotifier, DayProgress>
    dayProgressProvider =
    StateNotifierProvider<DayProgressNotifier, DayProgress>(
  (Ref ref) => DayProgressNotifier(
    ref.watch(progressRepositoryProvider),
    ref,
  ),
);

/// نسبة إنجاز فئة اليوم (٠.٠ – ١.٠) محسوبة على مجموع التكرارات،
/// حتى يعكس الشريط الجهد الحقيقي (ذكر بمئة تسبيحة ليس كذكر واحد).
double categoryProgressRatio(
  DayProgress progress,
  AdhkarCollection? collection,
) {
  if (collection == null || collection.items.isEmpty) return 0;

  int done = 0;
  for (final Dhikr dhikr in collection.items) {
    final int count = progress.countFor(dhikr.id);
    done += count > dhikr.repeat ? dhikr.repeat : count;
  }
  final int total = collection.totalRepeats;
  if (total == 0) return 0;
  return done / total;
}

/// عدد الأذكار المنتهية في فئة (للعرض: "أنجزت ٥ من ١٢ ذكرًا").
int completedDhikrCount(DayProgress progress, AdhkarCollection? collection) {
  if (collection == null) return 0;
  int count = 0;
  for (final Dhikr dhikr in collection.items) {
    if (progress.countFor(dhikr.id) >= dhikr.repeat) count++;
  }
  return count;
}
