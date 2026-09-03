import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants.dart';
import '../../core/utils/date_utils.dart';
import '../models/day_progress_model.dart';

/// حفظ واسترجاع تقدّم المستخدم.
///
/// المصدر الأساسي للحقيقة هو التخزين المحلي (Hive) — التطبيق يعمل بالكامل
/// بدون إنترنت. المزامنة مع Firestore (إن سجّل المستخدم دخوله) اختيارية
/// وتُبنى فوق هذه الطبقة، ولا يعتمد عليها أي شيء في الواجهة.
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

  /// دمج سجلّات قادمة من السحابة مع المحلية.
  ///
  /// قاعدة الدمج: لكل يوم، الأحدث (updatedAt) يفوز؛ وإذا كان أحدهما مكتملًا
  /// فالإكمال لا يُلغى أبدًا — لا نريد أن تُمحى سلسلة المستخدم بسبب جهاز قديم.
  Future<void> mergeRemoteDays(List<DayProgress> remoteDays) async {
    for (final DayProgress remote in remoteDays) {
      final DayProgress local = dayProgress(remote.dateKey);
      final DateTime localAt =
          local.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime remoteAt =
          remote.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      final DayProgress newer = remoteAt.isAfter(localAt) ? remote : local;
      final DayProgress merged = newer.copyWith(
        morningCompleted: local.morningCompleted || remote.morningCompleted,
        eveningCompleted: local.eveningCompleted || remote.eveningCompleted,
      );
      await saveDayProgress(merged);
    }
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

  DateTime? get lastSyncedAt {
    final String? raw = setting<String?>(StorageKeys.lastSyncedAt, null);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> saveLastSyncedAt(DateTime value) =>
      saveSetting(StorageKeys.lastSyncedAt, value.toIso8601String());

  /// حذف كل بيانات التقدّم (يُستخدم من الإعدادات بتأكيد صريح من المستخدم).
  Future<void> clearAllProgress() async {
    await _progressBox.clear();
    await saveLastSeenStreak(0);
    await saveBestStreak(0);
  }
}
