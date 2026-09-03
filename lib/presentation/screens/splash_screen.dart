import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/firebase_service.dart';
import 'home_screen.dart';

/// شاشة البداية: شعار بسيط + اسم التطبيق.
///
/// تستغل هذه اللحظة لتحميل ملفات الأذكار في الذاكرة وإعادة جدولة التذكيرات
/// (أندرويد يمسح المنبّهات بعد إعادة تشغيل الجهاز).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    final Stopwatch stopwatch = Stopwatch()..start();

    // تحميل الأذكار مسبقًا حتى تفتح الشاشات فورًا بلا انتظار.
    await ref.read(adhkarRepositoryProvider).loadAll();

    // إعادة جدولة التذكيرات المفعّلة.
    await ref.read(settingsProvider.notifier).rescheduleAll();

    // مزامنة صامتة إن كان المستخدم مسجّلًا دخوله (اختيارية تمامًا).
    if (FirebaseService.instance.isSignedIn) {
      unawaited(ref.read(syncProvider.notifier).syncNow());
    }

    // نضمن ظهور الشعار مدة لائقة بدل وميض سريع.
    final int remaining = 1200 - stopwatch.elapsedMilliseconds;
    if (remaining > 0) {
      await Future<void>.delayed(Duration(milliseconds: remaining));
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, Animation<double> animation, __, Widget child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? <Color>[AppColors.backgroundDark, AppColors.primaryDark]
                : <Color>[AppColors.background, AppColors.primaryLight],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Spacer(),
              const _SplashLogo(),
              const SizedBox(height: 22),
              Text(
                AppInfo.appName,
                style: TextStyle(
                  fontFamily: AppFonts.ui,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppInfo.tagline,
                style: TextStyle(
                  fontFamily: AppFonts.ui,
                  fontSize: 13,
                  color: isDark
                      ? Colors.white70
                      : AppColors.primaryDark.withValues(alpha: 0.75),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  AppInfo.madeBy,
                  style: TextStyle(
                    fontFamily: AppFonts.ui,
                    fontSize: 12,
                    color: isDark
                        ? Colors.white54
                        : AppColors.primaryDark.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شعار بسيط: هلال داخل دائرة.
class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      height: 118,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.nightlight_round,
        size: 58,
        color: AppColors.primary,
      ),
    );
  }
}
