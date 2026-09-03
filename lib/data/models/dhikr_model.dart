import '../../core/constants.dart';

/// ذِكر واحد كما هو مخزّن في ملفات JSON المحلية.
class Dhikr {
  const Dhikr({
    required this.id,
    required this.text,
    required this.repeat,
    this.title,
    this.reference,
    this.virtue,
  });

  /// معرّف ثابت (مثل: morning_001) — يُستخدم مفتاحًا لحفظ التقدّم.
  final String id;

  /// نص الذكر كاملًا مشكولًا.
  final String text;

  /// عدد مرات التكرار المطلوبة.
  final int repeat;

  /// عنوان مختصر للذكر (اختياري).
  final String? title;

  /// مصدر الذكر (اختياري).
  final String? reference;

  /// فضل الذكر (اختياري).
  final String? virtue;

  factory Dhikr.fromJson(Map<String, dynamic> json) {
    final int rawRepeat = (json['repeat'] as num?)?.toInt() ?? 1;
    return Dhikr(
      id: json['id'] as String,
      text: (json['text'] as String).trim(),
      // نضمن ألا يقل التكرار عن ١ حتى لا ينكسر حساب التقدّم.
      repeat: rawRepeat < 1 ? 1 : rawRepeat,
      title: (json['title'] as String?)?.trim(),
      reference: (json['reference'] as String?)?.trim(),
      virtue: (json['virtue'] as String?)?.trim(),
    );
  }
}

/// مجموعة أذكار فئة كاملة (صباح أو مساء).
class AdhkarCollection {
  const AdhkarCollection({
    required this.category,
    required this.title,
    required this.source,
    required this.items,
  });

  final AdhkarCategory category;
  final String title;
  final String source;
  final List<Dhikr> items;

  /// مجموع التكرارات المطلوبة لإكمال الفئة كلها.
  int get totalRepeats =>
      items.fold<int>(0, (int sum, Dhikr d) => sum + d.repeat);

  factory AdhkarCollection.fromJson(Map<String, dynamic> json) {
    final List<dynamic> raw = json['adhkar'] as List<dynamic>;
    return AdhkarCollection(
      category: AdhkarCategory.fromKey(json['category'] as String),
      title: json['title'] as String? ?? '',
      source: json['source'] as String? ?? AppInfo.dataSource,
      items: raw
          .map((dynamic e) => Dhikr.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
