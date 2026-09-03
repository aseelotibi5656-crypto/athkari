import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';

/// شريط تقدّم أفقي بسيط مع نص "أنجزت ٥ من ١٢ ذكرًا".
class AdhkarProgressBar extends StatelessWidget {
  const AdhkarProgressBar({
    super.key,
    required this.value,
    required this.completed,
    required this.total,
    required this.color,
  });

  /// النسبة من ٠ إلى ١.
  final double value;
  final int completed;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isDone = completed >= total && total > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                isDone
                    ? 'أكملت جميع الأذكار ✅'
                    : 'أنجزت ${AppDateUtils.toArabicDigits('$completed')}'
                        ' من ${AppDateUtils.toArabicDigits('$total')} ذكرًا',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isDone ? AppColors.success : null,
                    ),
              ),
            ),
            Text(
              '${AppDateUtils.toArabicDigits('${(value * 100).round()}')}٪',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0).toDouble()),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double animated, _) {
              return LinearProgressIndicator(
                value: animated,
                minHeight: 8,
                backgroundColor: isDark
                    ? AppColors.surfaceMutedDark
                    : AppColors.surfaceMuted,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDone ? AppColors.success : color,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// حلقة تقدّم دائرية تُستخدم داخل كروت الصباح/المساء.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.color,
    this.size = 56,
    this.strokeWidth = 6,
    this.child,
  });

  final double value;
  final Color color;
  final double size;
  final double strokeWidth;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0).toDouble()),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        builder: (BuildContext context, double animated, _) {
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: animated,
                  strokeWidth: strokeWidth,
                  strokeCap: StrokeCap.round,
                  backgroundColor: isDark
                      ? AppColors.surfaceMutedDark
                      : AppColors.surfaceMuted,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    animated >= 1 ? AppColors.success : color,
                  ),
                ),
              ),
              if (child != null) child!,
            ],
          );
        },
      ),
    );
  }
}
