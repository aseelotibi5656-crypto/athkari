import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/constants.dart';

/// خدمة التذكيرات المحلية.
///
/// تعتمد على `flutter_local_notifications` + قاعدة بيانات المناطق الزمنية،
/// فتعمل بدون إنترنت وحتى لو كان التطبيق مغلقًا بالكامل (النظام هو من يوقظ
/// الإشعار، لا التطبيق).
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// هل الإشعارات مدعومة على هذه المنصّة أصلًا؟
  bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'athkari_reminders',
    'تذكيرات الأذكار',
    channelDescription: 'تذكير يومي بأذكار الصباح والمساء',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );

  static const DarwinNotificationDetails _darwinDetails =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  static const NotificationDetails _details = NotificationDetails(
    android: _androidDetails,
    iOS: _darwinDetails,
    macOS: _darwinDetails,
  );

  /// تهيئة الخدمة + ضبط المنطقة الزمنية المحلية للجهاز.
  Future<void> init() async {
    if (_initialized || !isSupported) return;

    tz_data.initializeTimeZones();
    await _configureLocalTimeZone();

    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// ضبط المنطقة الزمنية على منطقة الجهاز.
  ///
  /// مهم جدًا: بدونها يجدول `zonedSchedule` بتوقيت UTC، فيصل تذكير "الصباح"
  /// في وقت خاطئ تمامًا لمن هم خارج UTC.
  Future<void> _configureLocalTimeZone() async {
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // في حال تعذّر تحديد المنطقة (جهاز غير معتاد)، نرجع إلى UTC بدل الانهيار.
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  /// طلب أذونات الإشعارات. يُرجع true إذا كانت ممنوحة.
  Future<bool> requestPermissions() async {
    if (!isSupported) return false;
    await init();

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final bool granted =
          await android?.requestNotificationsPermission() ?? true;
      return granted;
    }

    if (Platform.isIOS) {
      final bool? granted = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    if (Platform.isMacOS) {
      final bool? granted = await _plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    return false;
  }

  /// جدولة تذكير يومي متكرر في وقت محدّد بتوقيت الجهاز.
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (!isSupported) return;
    await init();

    await cancel(id);

    final tz.TZDateTime scheduled = _nextInstanceOf(hour, minute);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _details,
      // exactAllowWhileIdle يضمن وصول التذكير حتى في وضع Doze،
      // ونرجع إلى inexact تلقائيًا إذا لم يُمنح إذن المنبّهات الدقيقة.
      androidScheduleMode: await _scheduleMode(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // التكرار اليومي في نفس الساعة والدقيقة.
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'athkari_reminder_$id',
    );
  }

  /// اختيار وضع الجدولة حسب توفّر إذن المنبّهات الدقيقة (أندرويد ١٢+).
  Future<AndroidScheduleMode> _scheduleMode() async {
    if (!Platform.isAndroid) return AndroidScheduleMode.exactAllowWhileIdle;
    try {
      final AndroidFlutterLocalNotificationsPlugin? android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final bool canExact =
          await android?.canScheduleExactNotifications() ?? false;
      return canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
    } catch (_) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  /// أقرب موعد قادم للساعة/الدقيقة المطلوبة بتوقيت الجهاز.
  ///
  /// إذا مرّ وقت اليوم، نجدول ليوم غد. نستخدم TZDateTime.local حتى يتعامل
  /// النظام مع التوقيت الصيفي تلقائيًا.
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> cancel(int id) async {
    if (!isSupported) return;
    await init();
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    if (!isSupported) return;
    await init();
    await _plugin.cancelAll();
  }

  /// تذكير الصباح.
  Future<void> scheduleMorning(int hour, int minute) => scheduleDaily(
        id: NotificationIds.morningReminder,
        hour: hour,
        minute: minute,
        title: 'أذكار الصباح',
        body: 'ابدأ يومك بذكر الله 🌤️',
      );

  /// تذكير المساء.
  Future<void> scheduleEvening(int hour, int minute) => scheduleDaily(
        id: NotificationIds.eveningReminder,
        hour: hour,
        minute: minute,
        title: 'أذكار المساء',
        body: 'اختم يومك بذكر الله 🌙',
      );

  /// إشعار فوري (يُستخدم لاختبار التذكيرات من شاشة الإعدادات).
  Future<void> showTestNotification() async {
    if (!isSupported) return;
    await init();
    await _plugin.show(
      9999,
      'أذكاري',
      'التذكيرات تعمل بنجاح ✅',
      _details,
    );
  }
}
