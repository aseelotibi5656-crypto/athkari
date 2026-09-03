import 'package:flutter/material.dart';

/// لوحة ألوان التطبيق — هادئة ومريحة للقراءة الطويلة.
class AppColors {
  AppColors._();

  // اللون الأساسي: أخضر مزرقّ هادئ
  static const Color primary = Color(0xFF0E7C6B);
  static const Color primaryDark = Color(0xFF075246);
  static const Color primaryLight = Color(0xFF2FA98F);

  // ألوان الفئتين
  static const Color morning = Color(0xFFE0A22B); // ذهبي دافئ
  static const Color morningSoft = Color(0xFFFFF3DC);
  static const Color evening = Color(0xFF4A56A8); // نيلي هادئ
  static const Color eveningSoft = Color(0xFFE9EBFA);

  // الخلفيات (فاتح)
  static const Color background = Color(0xFFF6F4EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEFEDE6);

  // الخلفيات (داكن)
  static const Color backgroundDark = Color(0xFF10161A);
  static const Color surfaceDark = Color(0xFF19222A);
  static const Color surfaceMutedDark = Color(0xFF222D36);

  // النصوص
  static const Color textPrimary = Color(0xFF1B2427);
  static const Color textSecondary = Color(0xFF5C6A70);
  static const Color textPrimaryDark = Color(0xFFEDF1F3);
  static const Color textSecondaryDark = Color(0xFF9BAAB3);

  // حالات
  static const Color success = Color(0xFF2E9E5B);
  static const Color successSoft = Color(0xFFE4F5EA);
  static const Color streak = Color(0xFFE2622F); // لهب الـ streak
  static const Color divider = Color(0xFFE2DFD6);
  static const Color dividerDark = Color(0xFF2C3841);

  /// لون الفئة (صباح/مساء).
  static Color accentFor(String categoryKey) =>
      categoryKey == 'evening' ? evening : morning;

  /// لون الخلفية الخفيف للفئة.
  static Color accentSoftFor(String categoryKey) =>
      categoryKey == 'evening' ? eveningSoft : morningSoft;
}
