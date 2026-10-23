import '../../core/constants.dart';

/// تقدّم يوم واحد: كم مرة قُرئ كل ذكر، وهل اكتملت الفئتان.
///
/// يُخزَّن في Hive بمفتاح التاريخ المحلي "yyyy-MM-dd".
class DayProgress {
  const DayProgress({
    required this.dateKey,
    this.counts = const <String, int>{},
    this.morningCompleted = false,
    this.eveningCompleted = false,
    this.updatedAt,
  });

  /// مفتاح اليوم المحلي "yyyy-MM-dd".
  final String dateKey;

  /// عدد المرات المُنجزة لكل ذكر: dhikrId -> count.
  final Map<String, int> counts;

  /// هل أُكملت كل أذكار الصباح في هذا اليوم؟
  final bool morningCompleted;

  /// هل أُكملت كل أذكار المساء في هذا اليوم؟
  final bool eveningCompleted;

  /// وقت آخر تعديل على تقدّم هذا اليوم.
  final DateTime? updatedAt;

  /// اليوم يُحتسب "مكتملًا" فقط عند إنهاء الصباح **و** المساء معًا.
  bool get isFullyCompleted => morningCompleted && eveningCompleted;

  /// عدد المرات المُنجزة لذكر معيّن.
  int countFor(String dhikrId) => counts[dhikrId] ?? 0;

  bool completedFor(AdhkarCategory category) =>
      category == AdhkarCategory.morning ? morningCompleted : eveningCompleted;

  DayProgress copyWith({
    Map<String, int>? counts,
    bool? morningCompleted,
    bool? eveningCompleted,
    DateTime? updatedAt,
  }) {
    return DayProgress(
      dateKey: dateKey,
      counts: counts ?? this.counts,
      morningCompleted: morningCompleted ?? this.morningCompleted,
      eveningCompleted: eveningCompleted ?? this.eveningCompleted,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// نسخة بعد تحديث عدّاد ذكر واحد.
  DayProgress withCount(String dhikrId, int value) {
    final Map<String, int> next = Map<String, int>.from(counts);
    if (value <= 0) {
      next.remove(dhikrId);
    } else {
      next[dhikrId] = value;
    }
    return copyWith(counts: next, updatedAt: DateTime.now());
  }

  /// نسخة بعد تصفير كل أذكار فئة معيّنة.
  DayProgress withCategoryReset(Iterable<String> dhikrIds,
      AdhkarCategory category) {
    final Map<String, int> next = Map<String, int>.from(counts);
    for (final String id in dhikrIds) {
      next.remove(id);
    }
    return copyWith(
      counts: next,
      morningCompleted:
          category == AdhkarCategory.morning ? false : morningCompleted,
      eveningCompleted:
          category == AdhkarCategory.evening ? false : eveningCompleted,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'dateKey': dateKey,
        'counts': counts,
        'morningCompleted': morningCompleted,
        'eveningCompleted': eveningCompleted,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory DayProgress.fromJson(Map<dynamic, dynamic> json) {
    final Map<String, int> counts = <String, int>{};
    final dynamic rawCounts = json['counts'];
    if (rawCounts is Map) {
      rawCounts.forEach((dynamic key, dynamic value) {
        final int? v = value is int ? value : int.tryParse('$value');
        if (v != null && v > 0) counts['$key'] = v;
      });
    }
    return DayProgress(
      dateKey: '${json['dateKey']}',
      counts: counts,
      morningCompleted: json['morningCompleted'] == true,
      eveningCompleted: json['eveningCompleted'] == true,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse('${json['updatedAt']}'),
    );
  }

  factory DayProgress.empty(String dateKey) => DayProgress(dateKey: dateKey);
}
