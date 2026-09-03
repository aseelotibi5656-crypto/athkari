import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import 'progress_bar.dart';

/// كرت كبير لفئة أذكار (صباح/مساء) مع حلقة نسبة الإنجاز اليومي.
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.progress,
    required this.completedCount,
    required this.totalCount,
    required this.isCompleted,
    required this.onTap,
    this.isSuggested = false,
  });

  final AdhkarCategory category;

  /// نسبة الإنجاز من ٠ إلى ١.
  final double progress;
  final int completedCount;
  final int totalCount;
  final bool isCompleted;
  final VoidCallback onTap;

  /// هل هذه الفئة هي المقترحة الآن حسب وقت اليوم؟
  final bool isSuggested;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accent = AppColors.accentFor(category.key);
    final bool isMorning = category == AdhkarCategory.morning;

    return Container(
      decoration: AppTheme.cardDecoration(
        context,
        borderColor: isSuggested ? accent.withValues(alpha: 0.55) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: <Widget>[
                ProgressRing(
                  value: progress,
                  color: accent,
                  size: 62,
                  child: Icon(
                    isMorning ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                    color: isCompleted ? AppColors.success : accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              category.label,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          if (isSuggested && !isCompleted) ...<Widget>[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                'وقتها الآن',
                                style: TextStyle(
                                  fontFamily: AppFonts.ui,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isCompleted
                            ? 'اكتملت اليوم ✅'
                            : 'أنجزت ${AppDateUtils.toArabicDigits('$completedCount')}'
                                ' من ${AppDateUtils.toArabicDigits('$totalCount')}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: isCompleted ? AppColors.success : null,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
