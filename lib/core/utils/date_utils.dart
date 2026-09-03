/// أدوات التعامل مع التواريخ.
///
/// كل منطق التطبيق يعتمد على **التاريخ المحلي لجهاز المستخدم** فقط، ولا يستخدم
/// UTC أبدًا في تحديد "اليوم". السبب: لو استخدمنا UTC، مستخدم في السعودية
/// (UTC+3) يُنهي أذكار المساء الساعة ١١ ليلًا سيُحسب له اليوم التالي، فتنكسر
/// السلسلة ظلمًا. لذلك نُطبِّع كل تاريخ إلى منتصف الليل المحلي ونُخزّنه كنص
/// "yyyy-MM-dd" بلا أي معلومات توقيت.
library;

class AppDateUtils {
  AppDateUtils._();

  /// يُرجع التاريخ بدون وقت (منتصف الليل المحلي).
  static DateTime dayOf(DateTime dateTime) =>
      DateTime(dateTime.year, dateTime.month, dateTime.day);

  /// اليوم الحالي بتوقيت الجهاز المحلي.
  static DateTime today() => dayOf(DateTime.now());

  /// مفتاح التخزين لليوم: "yyyy-MM-dd".
  static String keyOf(DateTime dateTime) {
    final DateTime d = dayOf(dateTime);
    final String m = d.month.toString().padLeft(2, '0');
    final String day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  /// مفتاح اليوم الحالي.
  static String todayKey() => keyOf(DateTime.now());

  /// تحويل مفتاح "yyyy-MM-dd" إلى DateTime محلي (منتصف الليل).
  /// يُرجع null إذا كان المفتاح تالفًا — حتى لا ينهار التطبيق ببيانات قديمة.
  static DateTime? parseKey(String key) {
    final List<String> parts = key.split('-');
    if (parts.length != 3) return null;
    final int? y = int.tryParse(parts[0]);
    final int? m = int.tryParse(parts[1]);
    final int? d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    return DateTime(y, m, d);
  }

  /// عدد الأيام التقويمية بين تاريخين محليين (b - a).
  ///
  /// نحسبه على التواريخ المُطبَّعة لتفادي مشاكل التوقيت الصيفي: يوم فيه ٢٣ أو
  /// ٢٥ ساعة يجب أن يبقى "يومًا واحدًا".
  static int daysBetween(DateTime a, DateTime b) {
    final DateTime da = dayOf(a);
    final DateTime db = dayOf(b);
    // نحوّل إلى UTC بنفس أرقام السنة/الشهر/اليوم لإلغاء أثر التوقيت الصيفي.
    final DateTime ua = DateTime.utc(da.year, da.month, da.day);
    final DateTime ub = DateTime.utc(db.year, db.month, db.day);
    return ub.difference(ua).inDays;
  }

  /// هل التاريخان في نفس اليوم المحلي؟
  static bool isSameDay(DateTime a, DateTime b) => daysBetween(a, b) == 0;

  /// إضافة (أو طرح) أيام مع الحفاظ على منتصف الليل المحلي.
  static DateTime addDays(DateTime date, int days) {
    final DateTime d = dayOf(date);
    return DateTime(d.year, d.month, d.day + days);
  }

  /// أسماء الأشهر الميلادية بالعربية.
  static const List<String> monthNames = <String>[
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  /// أسماء أيام الأسبوع مختصرة، مرتّبة من السبت إلى الجمعة (ترتيب التقويم العربي).
  static const List<String> weekdayShortNames = <String>[
    'س',
    'ح',
    'ن',
    'ث',
    'ر',
    'خ',
    'ج',
  ];

  /// موضع اليوم داخل صف الأسبوع الذي يبدأ بالسبت (٠ = السبت ... ٦ = الجمعة).
  static int weekdayIndexSaturdayFirst(DateTime date) {
    // DateTime.weekday: الاثنين = 1 ... الأحد = 7، والسبت = 6.
    return (date.weekday + 1) % 7;
  }

  /// اسم الشهر والسنة، مثال: "سبتمبر ٢٠٢٦".
  static String monthLabel(DateTime date) =>
      '${monthNames[date.month - 1]} ${toArabicDigits(date.year.toString())}';

  /// تحويل الأرقام الإنجليزية إلى أرقام عربية-هندية (٠١٢٣...).
  static String toArabicDigits(String input) {
    const List<String> arabic = <String>[
      '٠',
      '١',
      '٢',
      '٣',
      '٤',
      '٥',
      '٦',
      '٧',
      '٨',
      '٩',
    ];
    final StringBuffer buffer = StringBuffer();
    for (final int codeUnit in input.codeUnits) {
      if (codeUnit >= 48 && codeUnit <= 57) {
        buffer.write(arabic[codeUnit - 48]);
      } else {
        buffer.writeCharCode(codeUnit);
      }
    }
    return buffer.toString();
  }

  /// تنسيق الوقت بصيغة ١٢ ساعة بالعربية، مثال: "٦:٣٠ صباحًا".
  static String formatTime(int hour, int minute) {
    final String period = hour < 12 ? 'صباحًا' : 'مساءً';
    int displayHour = hour % 12;
    if (displayHour == 0) displayHour = 12;
    final String m = minute.toString().padLeft(2, '0');
    return '${toArabicDigits(displayHour.toString())}:${toArabicDigits(m)} $period';
  }
}
