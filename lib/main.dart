import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/repositories/progress_repository.dart';
import 'providers/repository_providers.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ١) التخزين المحلي أولًا — هو المصدر الأساسي للحقيقة، والتطبيق
  //    لا يعمل بدونه، بعكس Firebase.
  await Hive.initFlutter();
  final ProgressRepository progressRepository = await ProgressRepository.open();

  // ٢) التذكيرات المحلية (تعمل بدون إنترنت).
  await NotificationService.instance.init();

  // ٣) Firebase اختياري: إن لم تُضَف ملفات الإعداد يكمل التطبيق محليًا.
  await FirebaseService.instance.initialize();

  runApp(
    ProviderScope(
      overrides: <Override>[
        progressRepositoryProvider.overrideWithValue(progressRepository),
      ],
      child: const AthkariApp(),
    ),
  );
}
