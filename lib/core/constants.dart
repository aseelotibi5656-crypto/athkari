/// ثوابت التطبيق: أسماء الصناديق، المفاتيح، المسارات، والنصوص الثابتة.
library;

class AppInfo {
  AppInfo._();

  static const String appName = 'أذكاري';
  static const String tagline = 'صدقة جارية — مجاني بالكامل بلا إعلانات';
  static const String author = 'أصيل العتيبي';
  static const String madeBy = 'صُنع بواسطة أصيل العتيبي';
  static const String dataSource = 'حصن المسلم';
}

/// فئات الأذكار المدعومة في التطبيق.
enum AdhkarCategory {
  morning('morning', 'أذكار الصباح'),
  evening('evening', 'أذكار المساء');

  const AdhkarCategory(this.key, this.label);

  final String key;
  final String label;

  static AdhkarCategory fromKey(String key) =>
      AdhkarCategory.values.firstWhere((c) => c.key == key,
          orElse: () => AdhkarCategory.morning);
}

/// مسارات ملفات JSON المخزّنة داخل التطبيق (تعمل بدون إنترنت).
class AssetPaths {
  AssetPaths._();

  static const String morningAdhkar =
      'lib/data/datasources/local/adhkar_morning.json';
  static const String eveningAdhkar =
      'lib/data/datasources/local/adhkar_evening.json';

  static String forCategory(AdhkarCategory category) =>
      switch (category) {
        AdhkarCategory.morning => morningAdhkar,
        AdhkarCategory.evening => eveningAdhkar,
      };
}

/// أسماء صناديق Hive ومفاتيحها.
class StorageKeys {
  StorageKeys._();

  /// صندوق تقدّم الأيام: المفتاح = تاريخ اليوم "yyyy-MM-dd".
  static const String progressBox = 'athkari_progress';

  /// صندوق الإعدادات العامة (التذكيرات، أوقاتها، آخر streak معروف...).
  static const String settingsBox = 'athkari_settings';

  // مفاتيح الإعدادات
  static const String morningReminderEnabled = 'morning_reminder_enabled';
  static const String eveningReminderEnabled = 'evening_reminder_enabled';
  static const String morningReminderHour = 'morning_reminder_hour';
  static const String morningReminderMinute = 'morning_reminder_minute';
  static const String eveningReminderHour = 'evening_reminder_hour';
  static const String eveningReminderMinute = 'evening_reminder_minute';
  static const String hapticsEnabled = 'haptics_enabled';
  static const String keepScreenOn = 'keep_screen_on';
  static const String dhikrTextScale = 'dhikr_text_scale';

  /// آخر قيمة streak رآها المستخدم — تُستخدم لاكتشاف انكسار السلسلة
  /// وعرض رسالة تشجيعية بدل رسالة محبِطة.
  static const String lastSeenStreak = 'last_seen_streak';

  /// أفضل سلسلة وصل لها المستخدم (لا تنقص أبدًا).
  static const String bestStreak = 'best_streak';

  /// آخر مزامنة ناجحة مع Firestore (ISO 8601).
  static const String lastSyncedAt = 'last_synced_at';
}

/// أرقام تعريف الإشعارات المحلية.
class NotificationIds {
  NotificationIds._();

  static const int morningReminder = 1001;
  static const int eveningReminder = 1002;
}

/// القيم الافتراضية لأوقات التذكير.
class Defaults {
  Defaults._();

  static const int morningHour = 6;
  static const int morningMinute = 30;
  static const int eveningHour = 17;
  static const int eveningMinute = 30;
}
