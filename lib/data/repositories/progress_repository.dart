import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants.dart';
import '../../core/utils/date_utils.dart';
import '../models/day_progress_model.dart';

/// حفظ واسترجاع تقدّم المستخدم.
///
/// المصدر الوحيد للحقيقة هو التخزين المحلي (Hive) — التطبيق يعمل بالكامل
/// بدون إنترنت، ولا يرفع أي بيانات إلى أي خادم.
class ProgressRepository {
  ProgressRepository(this._progressBox, this._settingsBox);

  final Box<dynamic> _progressBox;
  final Box<dynamic> _settingsBox;

  /// فتح الصناديق. تُستدعى مرة واحدة عند إقلاع التطبيق.
  static Future<ProgressRepository> open() async {
    final Box<dynamic> progress =
        await Hive.openBox<dynamic>(StorageKeys.progressBox);
    final Box<dynamic> settings =
        await Hive.openBox<dynamic>(StorageKeys.settingsBox);
    return ProgressRepository(progress, settings);
  }

  // ==================== تقدّم الأيام ====================

  DayProgress dayProgress(String dateKey) {
    final dynamic raw = _progressBox.get(dateKey);
    if (raw is Map) {
      return DayProgress.fromJson(raw);
    }
    return DayProgress.empty(dateKey);
  }

  DayProgress todayProgress() => dayProgress(AppDateUtils.todayKey());

  Future<void> saveDayProgress(DayProgress progress) async {
    await _progressBox.put(progress.dateKey, progress.toJson());
  }

  /// كل الأيام المكتملة (صباح + مساء) — مصدر بناء السلسلة والتقويم.
  ///
  /// نحتفظ بالسجل كاملًا حتى لو انكسرت السلسلة، حتى يبقى التقويم الشهري
  /// يعرض التاريخ الحقيقي للمستخدم.
  Set<String> completedDays() {
    final Set<String> days = <String>{};
    for (final dynamic key in _progressBox.keys) {
      final dynamic raw = _progressBox.get(key);
      if (raw is Map &&
          raw['morningCompleted'] == true &&
          raw['eveningCompleted'] == true) {
        days.add('$key');
      }
    }
    return days;
  }

  /// كل سجلّات الأيام (تُستخدم في رفع نسخة كاملة إلى السحابة).
  List<DayProgress> allDays() {
    final List<DayProgress> days = <DayProgress>[];
    for (final dynamic key in _progressBox.keys) {
      final dynamic raw = _progressBox.get(key);
      if (raw is Map) days.add(DayProgress.fromJson(raw));
    }
    days.sort((DayProgress a, DayProgress b) => a.dateKey.compareTo(b.dateKey));
    return days;
  }

  // ==================== الإعدادات ====================

  T setting<T>(String key, T fallback) {
    final dynamic value = _settingsBox.get(key);
    return value is T ? value : fallback;
  }

  Future<void> saveSetting(String key, Object? value) =>
      _settingsBox.put(key, value);

  int get lastSeenStreak => setting<int>(StorageKeys.lastSeenStreak, 0);

  Future<void> saveLastSeenStreak(int value) =>
      saveSetting(StorageKeys.lastSeenStreak, value);

  int get bestStreak => setting<int>(StorageKeys.bestStreak, 0);

  Future<void> saveBestStreak(int value) =>
      saveSetting(StorageKeys.bestStreak, value);

  /// حذف كل بيانات التقدّم (يُستخدم من الإعدادات بتأكيد صريح من المستخدم).
  Future<void> clearAllProgress() async {
    await _progressBox.clear();
    await saveLastSeenStreak(0);
    await saveBestStreak(0);
  }
}
