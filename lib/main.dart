import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/repositories/progress_repository.dart';
import 'providers/repository_providers.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ١) التخزين المحلي أولًا — هو المصدر الوحيد للحقيقة؛ التطبيق محلي
  //    بالكامل ولا يرفع أي بيانات إلى أي خادم.
  await Hive.initFlutter();
  final ProgressRepository progressRepository = await ProgressRepository.open();

  // ٢) التذكيرات المحلية (تعمل بدون إنترنت).
  await NotificationService.instance.init();

  runApp(
    ProviderScope(
      overrides: <Override>[
        progressRepositoryProvider.overrideWithValue(progressRepository),
      ],
      child: const AthkariApp(),
    ),
  );
}
