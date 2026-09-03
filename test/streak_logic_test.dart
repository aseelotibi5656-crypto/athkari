import 'package:athkari/core/utils/date_utils.dart';
import 'package:athkari/data/models/day_progress_model.dart';
import 'package:athkari/data/models/streak_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// اختبارات منطق السلسلة — أهم جزء في التطبيق، وأكثره عرضة لأخطاء التواريخ.
void main() {
  /// مفتاح يوم بإزاحة أيام عن "الآن" المرجعي.
  String keyOffset(DateTime now, int days) =>
      AppDateUtils.keyOf(AppDateUtils.addDays(now, days));

  group('حساب السلسلة الحالية', () {
    final DateTime now = DateTime(2026, 9, 3, 14, 30);

    test('لا يوجد سجل → صفر', () {
      expect(
        StreakState.calculateCurrentStreak(<String>{}, now: now),
        0,
      );
    });

    test('اليوم مكتمل فقط → واحد', () {
      expect(
        StreakState.calculateCurrentStreak(
          <String>{keyOffset(now, 0)},
          now: now,
        ),
        1,
      );
    });

    test('ثلاثة أيام متتالية تنتهي باليوم → ثلاثة', () {
      expect(
        StreakState.calculateCurrentStreak(
          <String>{
            keyOffset(now, 0),
            keyOffset(now, -1),
            keyOffset(now, -2),
          },
          now: now,
        ),
        3,
      );
    });

    test('الأمس مكتمل واليوم لم يبدأ بعد → السلسلة ما زالت حيّة', () {
      // المستخدم أمامه بقية اليوم، فلا يجوز تصفير سلسلته الآن.
      expect(
        StreakState.calculateCurrentStreak(
          <String>{keyOffset(now, -1), keyOffset(now, -2)},
          now: now,
        ),
        2,
      );
    });

    test('فات يوم كامل بلا إكمال → صفر', () {
      expect(
        StreakState.calculateCurrentStreak(
          <String>{keyOffset(now, -2), keyOffset(now, -3)},
          now: now,
        ),
        0,
      );
    });

    test('الفجوة توقف العدّ ولا تتجاوزه', () {
      expect(
        StreakState.calculateCurrentStreak(
          <String>{
            keyOffset(now, 0),
            keyOffset(now, -1),
            // فجوة عند -2
            keyOffset(now, -3),
            keyOffset(now, -4),
          },
          now: now,
        ),
        2,
      );
    });

    test('السلسلة تعبر حدود الشهر بشكل صحيح', () {
      final DateTime firstOfMonth = DateTime(2026, 9, 1, 9);
      expect(
        StreakState.calculateCurrentStreak(
          <String>{
            '2026-09-01',
            '2026-08-31',
            '2026-08-30',
          },
          now: firstOfMonth,
        ),
        3,
      );
    });

    test('السلسلة تعبر حدود السنة بشكل صحيح', () {
      final DateTime newYear = DateTime(2027, 1, 1, 8);
      expect(
        StreakState.calculateCurrentStreak(
          <String>{'2027-01-01', '2026-12-31', '2026-12-30'},
          now: newYear,
        ),
        3,
      );
    });

    test('يتعامل مع السنة الكبيسة (٢٩ فبراير)', () {
      final DateTime leap = DateTime(2028, 3, 1, 10);
      expect(
        StreakState.calculateCurrentStreak(
          <String>{'2028-03-01', '2028-02-29', '2028-02-28'},
          now: leap,
        ),
        3,
      );
    });

    test('اختلاف ساعة اليوم لا يغيّر النتيجة (نفس اليوم المحلي)', () {
      final Set<String> days = <String>{
        AppDateUtils.keyOf(DateTime(2026, 9, 3)),
        AppDateUtils.keyOf(DateTime(2026, 9, 2)),
      };
      // منتصف الليل تمامًا، منتصف النهار، وقبل منتصف الليل بدقيقة.
      for (final DateTime moment in <DateTime>[
        DateTime(2026, 9, 3, 0, 0),
        DateTime(2026, 9, 3, 12, 0),
        DateTime(2026, 9, 3, 23, 59),
      ]) {
        expect(
          StreakState.calculateCurrentStreak(days, now: moment),
          2,
          reason: 'فشل عند الساعة ${moment.hour}',
        );
      }
    });

    test('مفتاح تالف في السجل لا يُسقط التطبيق', () {
      expect(
        StreakState.calculateCurrentStreak(
          <String>{keyOffset(now, 0), 'تاريخ-غير-صالح', ''},
          now: now,
        ),
        1,
      );
    });
  });

  group('أطول سلسلة', () {
    test('يختار أطول تتابع في السجل كله', () {
      expect(
        StreakState.calculateBestStreak(<String>{
          '2026-01-01',
          '2026-01-02',
          '2026-01-03',
          '2026-01-04', // تتابع من ٤
          '2026-02-10',
          '2026-02-11', // تتابع من ٢
        }),
        4,
      );
    });

    test('سجل فارغ → صفر', () {
      expect(StreakState.calculateBestStreak(<String>{}), 0);
    });

    test('يوم واحد → واحد', () {
      expect(StreakState.calculateBestStreak(<String>{'2026-05-05'}), 1);
    });
  });

  group('اكتمال اليوم', () {
    test('اليوم لا يكتمل إلا بإنهاء الصباح والمساء معًا', () {
      const DayProgress morningOnly = DayProgress(
        dateKey: '2026-09-03',
        morningCompleted: true,
      );
      const DayProgress eveningOnly = DayProgress(
        dateKey: '2026-09-03',
        eveningCompleted: true,
      );
      const DayProgress both = DayProgress(
        dateKey: '2026-09-03',
        morningCompleted: true,
        eveningCompleted: true,
      );

      expect(morningOnly.isFullyCompleted, isFalse);
      expect(eveningOnly.isFullyCompleted, isFalse);
      expect(both.isFullyCompleted, isTrue);
    });

    test('العدّادات تُحفظ وتُقرأ بشكل صحيح', () {
      const DayProgress progress = DayProgress(dateKey: '2026-09-03');
      final DayProgress updated = progress.withCount('morning_001', 3);

      expect(updated.countFor('morning_001'), 3);
      expect(updated.countFor('morning_002'), 0);

      // التصفير يحذف المفتاح بدل تخزين صفر.
      expect(updated.withCount('morning_001', 0).counts.isEmpty, isTrue);
    });

    test('التحويل إلى JSON ومنه يحافظ على البيانات', () {
      final DayProgress original = const DayProgress(
        dateKey: '2026-09-03',
        morningCompleted: true,
      ).withCount('morning_001', 2);

      final DayProgress restored = DayProgress.fromJson(original.toJson());

      expect(restored.dateKey, '2026-09-03');
      expect(restored.morningCompleted, isTrue);
      expect(restored.eveningCompleted, isFalse);
      expect(restored.countFor('morning_001'), 2);
    });
  });

  group('أدوات التواريخ', () {
    test('daysBetween يحسب الأيام التقويمية لا الساعات', () {
      // ٢٣ ساعة فقط بين الوقتين لكنهما يومان مختلفان.
      expect(
        AppDateUtils.daysBetween(
          DateTime(2026, 9, 3, 23, 30),
          DateTime(2026, 9, 4, 22, 30),
        ),
        1,
      );
    });

    test('keyOf يتجاهل الوقت', () {
      expect(AppDateUtils.keyOf(DateTime(2026, 9, 3, 23, 59)), '2026-09-03');
      expect(AppDateUtils.keyOf(DateTime(2026, 9, 3, 0, 0)), '2026-09-03');
    });

    test('parseKey يعكس keyOf ويرفض المدخلات التالفة', () {
      expect(AppDateUtils.parseKey('2026-09-03'), DateTime(2026, 9, 3));
      expect(AppDateUtils.parseKey('غير صالح'), isNull);
      expect(AppDateUtils.parseKey('2026-13-01'), isNull);
    });

    test('ترتيب أيام الأسبوع يبدأ من السبت', () {
      // ٥ سبتمبر ٢٠٢٦ يوافق السبت.
      expect(
        AppDateUtils.weekdayIndexSaturdayFirst(DateTime(2026, 9, 5)),
        0,
      );
      // ٦ سبتمبر ٢٠٢٦ يوافق الأحد.
      expect(
        AppDateUtils.weekdayIndexSaturdayFirst(DateTime(2026, 9, 6)),
        1,
      );
    });

    test('تحويل الأرقام إلى عربية', () {
      expect(AppDateUtils.toArabicDigits('2026'), '٢٠٢٦');
      expect(AppDateUtils.toArabicDigits('12 يومًا'), '١٢ يومًا');
    });

    test('تنسيق الوقت بصيغة ١٢ ساعة', () {
      expect(AppDateUtils.formatTime(6, 30), '٦:٣٠ صباحًا');
      expect(AppDateUtils.formatTime(17, 5), '٥:٠٥ مساءً');
      expect(AppDateUtils.formatTime(0, 0), '١٢:٠٠ صباحًا');
      expect(AppDateUtils.formatTime(12, 0), '١٢:٠٠ مساءً');
    });
  });
}
