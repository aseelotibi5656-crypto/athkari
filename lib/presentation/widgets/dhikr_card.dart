import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/dhikr_model.dart';

/// كرت ذكر واحد: النص، عدّاد التكرار، والمصدر.
///
/// الضغط على أي مكان في الكرت ينقص العدّاد. عند الوصول للصفر يتحوّل الكرت
/// لحالة "مكتمل" بتدرّج لوني هادئ — ولا يختفي، حتى يستطيع المستخدم إعادة
/// قراءته أو التراجع.
class DhikrCard extends StatelessWidget {
  const DhikrCard({
    super.key,
    required this.dhikr,
    required this.count,
    required this.accent,
    required this.onTap,
    required this.onUndo,
    required this.onComplete,
    this.hapticsEnabled = true,
    this.textScale = 1.0,
    this.index,
  });

  final Dhikr dhikr;

  /// عدد المرات المُنجزة حتى الآن.
  final int count;

  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onUndo;

  /// إكمال الذكر دفعة واحدة (ضغطة مطوّلة).
  final VoidCallback onComplete;

  final bool hapticsEnabled;
  final double textScale;

  /// ترتيب الذكر في القائمة (للعرض فقط).
  final int? index;

  bool get _isCompleted => count >= dhikr.repeat;

  int get _remaining {
    final int left = dhikr.repeat - count;
    return left < 0 ? 0 : left;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: AppTheme.cardDecoration(
        context,
        color: _isCompleted
            ? (isDark
                ? const Color(0xFF16302A)
                : AppColors.successSoft)
            : null,
        borderColor: _isCompleted
            ? AppColors.success.withValues(alpha: isDark ? 0.5 : 0.35)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (_isCompleted) return;
            if (hapticsEnabled) HapticFeedback.selectionClick();
            onTap();
          },
          onLongPress: () {
            if (_isCompleted) return;
            if (hapticsEnabled) HapticFeedback.mediumImpact();
            onComplete();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _header(context),
                const SizedBox(height: 12),
                Text(
                  dhikr.text,
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                  style: AppTheme.dhikrTextStyle(context, scale: textScale)
                      .copyWith(
                    color: _isCompleted
                        ? (isDark
                            ? AppColors.textPrimaryDark.withValues(alpha: 0.75)
                            : AppColors.textPrimary.withValues(alpha: 0.65))
                        : null,
                  ),
                ),
                if (dhikr.virtue != null || dhikr.reference != null) ...<Widget>[
                  const SizedBox(height: 12),
                  _footer(context),
                ],
                const SizedBox(height: 6),
                _counterRow(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: <Widget>[
        if (index != null)
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _isCompleted
                  ? AppColors.success.withValues(alpha: 0.15)
                  : accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              AppDateUtils.toArabicDigits('${index! + 1}'),
              style: TextStyle(
                fontFamily: AppFonts.ui,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _isCompleted ? AppColors.success : accent,
              ),
            ),
          ),
        if (dhikr.title != null) ...<Widget>[
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              dhikr.title!,
              style: TextStyle(
                fontFamily: AppFonts.ui,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ] else
          const Spacer(),
        if (_isCompleted)
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 22),
      ],
    );
  }

  Widget _footer(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color color = isDark
        ? AppColors.textSecondaryDark.withValues(alpha: 0.85)
        : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (dhikr.virtue != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.auto_awesome_rounded, size: 14, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  dhikr.virtue!,
                  style: TextStyle(
                    fontFamily: AppFonts.ui,
                    fontSize: 12,
                    height: 1.6,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        if (dhikr.reference != null) ...<Widget>[
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.menu_book_rounded, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  dhikr.reference!,
                  style: TextStyle(
                    fontFamily: AppFonts.ui,
                    fontSize: 12,
                    height: 1.6,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _counterRow(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: <Widget>[
        // زر التراجع — يظهر فقط بعد أول ضغطة.
        if (count > 0)
          IconButton(
            onPressed: () {
              if (hapticsEnabled) HapticFeedback.lightImpact();
              onUndo();
            },
            visualDensity: VisualDensity.compact,
            tooltip: 'تراجع',
            icon: Icon(
              Icons.undo_rounded,
              size: 20,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          )
        else
          const SizedBox(width: 8),

        const Spacer(),

        if (_isCompleted)
          const Text(
            'تمّ بحمد الله',
            style: TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          )
        else ...<Widget>[
          Text(
            dhikr.repeat > 1 ? 'المتبقّي' : 'اضغط عند القراءة',
            style: TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: 12,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          _counterChip(context),
        ],
      ],
    );
  }

  Widget _counterChip(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 46),
      height: 38,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        AppDateUtils.toArabicDigits('$_remaining'),
        style: TextStyle(
          fontFamily: AppFonts.ui,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: accent,
        ),
      ),
    );
  }
}
