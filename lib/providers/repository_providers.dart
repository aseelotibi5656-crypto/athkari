import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/adhkar_repository.dart';
import '../data/repositories/progress_repository.dart';

/// مستودع نصوص الأذكار (يقرأ من JSON المحلي).
final Provider<AdhkarRepository> adhkarRepositoryProvider =
    Provider<AdhkarRepository>((Ref ref) => AdhkarRepository());

/// مستودع التقدّم (Hive).
///
/// يُستبدل (override) في `main.dart` بالنسخة المفتوحة فعليًا قبل تشغيل
/// التطبيق، لذلك لا يُستدعى هذا الجسم أبدًا في التشغيل الطبيعي.
final Provider<ProgressRepository> progressRepositoryProvider =
    Provider<ProgressRepository>(
  (Ref ref) => throw UnimplementedError(
    'progressRepositoryProvider يجب أن يُستبدل في main.dart',
  ),
);
