import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';

/// تقويم شهري مصغّر يعرض الأيام المكتملة بنقاط خضراء.
///
/// يعتمد على سجلّ الأيام الكامل (لا على السلسلة الحالية)، فيبقى التاريخ ظاهرًا
/// حتى لو انكسرت السلسلة.
class MonthCalendar extends StatefulWidget {
  const MonthCalendar({
    super.key,
    required this.completedDays,
  });

  /// مفاتيح الأيام المكتملة "yyyy-MM-dd".
  final Set<String> completedDays;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final DateTime today = AppDateUtils.today();
    _visibleMonth = DateTime(today.year, today.month);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  /// هل الشهر المعروض هو الشهر الحالي؟ (نمنع التنقّل للمستقبل)
  bool get _isCurrentMonth {
    final DateTime today = AppDateUtils.today();
    return _visibleMonth.year == today.year &&
        _visibleMonth.month == today.month;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTime today = AppDateUtils.today();

    final int daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final DateTime firstDay =
        DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final int leadingBlanks = AppDateUtils.weekdayIndexSaturdayFirst(firstDay);

    final int completedThisMonth = List<int>.generate(daysInMonth, (int i) => i + 1)
        .where((int day) => widget.completedDays.contains(
            AppDateUtils.keyOf(
                DateTime(_visibleMonth.year, _visibleMonth.month, day))))
        .length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: () => _shiftMonth(-1),
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'الشهر السابق',
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Text(
                  AppDateUtils.monthLabel(_visibleMonth),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                // لا معنى لتصفّح المستقبل.
                onPressed: _isCurrentMonth ? null : () => _shiftMonth(1),
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: 'الشهر التالي',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: AppDateUtils.weekdayShortNames
                .map((String name) => Expanded(
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppFonts.ui,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingBlanks + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemBuilder: (BuildContext context, int index) {
              if (index < leadingBlanks) return const SizedBox.shrink();

              final int dayNumber = index - leadingBlanks + 1;
              final DateTime date = DateTime(
                  _visibleMonth.year, _visibleMonth.month, dayNumber);
              final bool isCompleted =
                  widget.completedDays.contains(AppDateUtils.keyOf(date));
              final bool isToday = AppDateUtils.isSameDay(date, today);
              final bool isFuture = date.isAfter(today);

              return _DayCell(
                day: dayNumber,
                isCompleted: isCompleted,
                isToday: isToday,
                isFuture: isFuture,
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            'أيام مكتملة هذا الشهر: '
            '${AppDateUtils.toArabicDigits('$completedThisMonth')}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isCompleted,
    required this.isToday,
    required this.isFuture,
  });

  final int day;
  final bool isCompleted;
  final bool isToday;
  final bool isFuture;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color background = isCompleted
        ? AppColors.success.withValues(alpha: isDark ? 0.28 : 0.16)
        : Colors.transparent;
    final Color textColor = isFuture
        ? (isDark
            ? AppColors.textSecondaryDark.withValues(alpha: 0.4)
            : AppColors.textSecondary.withValues(alpha: 0.4))
        : isCompleted
            ? AppColors.success
            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);

    return Container(
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: isToday
            ? Border.all(color: AppColors.primary, width: 1.6)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        AppDateUtils.toArabicDigits('$day'),
        style: TextStyle(
          fontFamily: AppFonts.ui,
          fontSize: 12,
          fontWeight: isCompleted || isToday ? FontWeight.w800 : FontWeight.w400,
          color: textColor,
        ),
      ),
    );
  }
}
