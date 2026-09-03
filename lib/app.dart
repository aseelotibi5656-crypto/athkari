import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/splash_screen.dart';

/// جذر التطبيق: يضبط الثيم، اللغة العربية، واتجاه RTL لكل الشاشات.
class AthkariApp extends ConsumerWidget {
  const AthkariApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppInfo.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // التطبيق عربي بالكامل.
      locale: const Locale('ar'),
      supportedLocales: const <Locale>[Locale('ar')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ضمان إضافي لاتجاه RTL حتى في الحوارات والقوائم المنبثقة.
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery.withClampedTextScaling(
            // نحدّ من تكبير النص الخارجي حتى لا تنكسر الكروت،
            // ولدينا داخل شاشة الأذكار تحكّم خاص بحجم خط الذكر.
            maxScaleFactor: 1.4,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },

      home: const SplashScreen(),
    );
  }
}
