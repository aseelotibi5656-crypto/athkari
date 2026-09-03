import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/streak_model.dart';
import '../../providers/streak_provider.dart';

/// بطاقة عدّاد السلسلة أعلى الشاشة الرئيسية.
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.streak});

  final StreakState streak;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool alive = streak.current > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: alive
              ? <Color>[AppColors.primary, AppColors.primaryDark]
              : isDark
                  ? <Color>[AppColors.surfaceDark, AppColors.surfaceMutedDark]
                  : <Color>[AppColors.surface, AppColors.surfaceMuted],
        ),
        border: alive
            ? null
            : Border.all(
                color: isDark ? AppColors.dividerDark : AppColors.divider,
              ),
      ),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                alive ? '🔥' : '🤍',
                style: const TextStyle(fontSize: 30),
              ),
              const SizedBox(width: 10),
              Text(
                AppDateUtils.toArabicDigits('${streak.current}'),
                style: TextStyle(
                  fontFamily: AppFonts.ui,
                  fontSize: 46,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: alive
                      ? Colors.white
                      : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  streak.current == 1 ? 'يوم' : 'يومًا',
                  style: TextStyle(
                    fontFamily: AppFonts.ui,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: alive
                        ? Colors.white70
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            streakMessage(streak),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: 14,
              height: 1.6,
              color: alive
                  ? Colors.white.withValues(alpha: 0.92)
                  : (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary),
            ),
          ),
          if (streak.best > 0) ...<Widget>[
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: alive
                    ? Colors.white.withValues(alpha: 0.16)
                    : (isDark
                        ? AppColors.surfaceMutedDark
                        : AppColors.surface),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                'أطول سلسلة: ${AppDateUtils.toArabicDigits('${streak.best}')} '
                '${streak.best == 1 ? 'يوم' : 'يومًا'}',
                style: TextStyle(
                  fontFamily: AppFonts.ui,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: alive
                      ? Colors.white
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
