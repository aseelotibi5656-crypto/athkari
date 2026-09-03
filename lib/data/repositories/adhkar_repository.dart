import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../core/constants.dart';
import '../models/dhikr_model.dart';

/// مصدر نصوص الأذكار: ملفات JSON مُجمّعة داخل التطبيق.
///
/// لا يوجد أي اتصال بالشبكة هنا — الأذكار تُقرأ يوميًا وبكثرة، ولازم تشتغل
/// بدون إنترنت. أي تحديث للنصوص يأتي مع تحديث التطبيق نفسه.
class AdhkarRepository {
  AdhkarRepository();

  /// كاش في الذاكرة حتى لا نفكّ ترميز JSON في كل مرة تُفتح فيها الشاشة.
  final Map<AdhkarCategory, AdhkarCollection> _cache =
      <AdhkarCategory, AdhkarCollection>{};

  Future<AdhkarCollection> load(AdhkarCategory category) async {
    final AdhkarCollection? cached = _cache[category];
    if (cached != null) return cached;

    final String raw = await rootBundle.loadString(
      AssetPaths.forCategory(category),
    );
    final Map<String, dynamic> json =
        jsonDecode(raw) as Map<String, dynamic>;
    final AdhkarCollection collection = AdhkarCollection.fromJson(json);
    _cache[category] = collection;
    return collection;
  }

  /// تحميل الفئتين معًا (تُستخدم في الشاشة الرئيسية لحساب نِسَب الإنجاز).
  Future<Map<AdhkarCategory, AdhkarCollection>> loadAll() async {
    final List<AdhkarCollection> results = await Future.wait(
      AdhkarCategory.values.map(load),
    );
    return <AdhkarCategory, AdhkarCollection>{
      for (final AdhkarCollection c in results) c.category: c,
    };
  }
}
