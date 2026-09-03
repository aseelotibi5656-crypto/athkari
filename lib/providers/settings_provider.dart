import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../data/repositories/progress_repository.dart';
import '../services/notification_service.dart';
import 'repository_providers.dart';

/// إعدادات المستخدم المحفوظة محليًا.
class SettingsState {
  const SettingsState({
    required this.morningReminderEnabled,
    required this.eveningReminderEnabled,
    required this.morningTime,
    required this.eveningTime,
    required this.hapticsEnabled,
    required this.keepScreenOn,
    required this.textScale,
  });

  final bool morningReminderEnabled;
  final bool eveningReminderEnabled;
  final TimeOfDay morningTime;
  final TimeOfDay eveningTime;

  /// اهتزاز خفيف عند كل تسبيحة.
  final bool hapticsEnabled;

  /// إبقاء الشاشة مضاءة أثناء قراءة الأذكار.
  final bool keepScreenOn;

  /// معامل تكبير خط نص الذكر (٠.٨ – ١.٦).
  final double textScale;

  SettingsState copyWith({
    bool? morningReminderEnabled,
    bool? eveningReminderEnabled,
    TimeOfDay? morningTime,
    TimeOfDay? eveningTime,
    bool? hapticsEnabled,
    bool? keepScreenOn,
    double? textScale,
  }) {
    return SettingsState(
      morningReminderEnabled:
          morningReminderEnabled ?? this.morningReminderEnabled,
      eveningReminderEnabled:
          eveningReminderEnabled ?? this.eveningReminderEnabled,
      morningTime: morningTime ?? this.morningTime,
      eveningTime: eveningTime ?? this.eveningTime,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      textScale: textScale ?? this.textScale,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._repository) : super(_read(_repository));

  final ProgressRepository _repository;

  static SettingsState _read(ProgressRepository repo) {
    return SettingsState(
      morningReminderEnabled:
          repo.setting<bool>(StorageKeys.morningReminderEnabled, false),
      eveningReminderEnabled:
          repo.setting<bool>(StorageKeys.eveningReminderEnabled, false),
      morningTime: TimeOfDay(
        hour: repo.setting<int>(
            StorageKeys.morningReminderHour, Defaults.morningHour),
        minute: repo.setting<int>(
            StorageKeys.morningReminderMinute, Defaults.morningMinute),
      ),
      eveningTime: TimeOfDay(
        hour: repo.setting<int>(
            StorageKeys.eveningReminderHour, Defaults.eveningHour),
        minute: repo.setting<int>(
            StorageKeys.eveningReminderMinute, Defaults.eveningMinute),
      ),
      hapticsEnabled: repo.setting<bool>(StorageKeys.hapticsEnabled, true),
      keepScreenOn: repo.setting<bool>(StorageKeys.keepScreenOn, false),
      textScale: repo.setting<double>(StorageKeys.dhikrTextScale, 1.0),
    );
  }

  /// إعادة جدولة التذكيرات عند الإقلاع.
  ///
  /// ضرورية لأن أندرويد يمسح كل المنبّهات المجدولة عند إعادة تشغيل الجهاز؛
  /// إعادة الجدولة عند أول فتح للتطبيق تُصلح ذلك (بالإضافة إلى مستقبِل
  /// BOOT_COMPLETED المُعرَّف في AndroidManifest).
  Future<void> rescheduleAll() async {
    if (state.morningReminderEnabled) {
      await NotificationService.instance.scheduleMorning(
        state.morningTime.hour,
        state.morningTime.minute,
      );
    }
    if (state.eveningReminderEnabled) {
      await NotificationService.instance.scheduleEvening(
        state.eveningTime.hour,
        state.eveningTime.minute,
      );
    }
  }

  /// تفعيل/تعطيل تذكير الصباح. يُرجع false إذا رفض المستخدم إذن الإشعارات.
  Future<bool> setMorningReminder(bool enabled) async {
    if (enabled) {
      final bool granted =
          await NotificationService.instance.requestPermissions();
      if (!granted) return false;
      await NotificationService.instance.scheduleMorning(
        state.morningTime.hour,
        state.morningTime.minute,
      );
    } else {
      await NotificationService.instance
          .cancel(NotificationIds.morningReminder);
    }

    state = state.copyWith(morningReminderEnabled: enabled);
    await _repository.saveSetting(StorageKeys.morningReminderEnabled, enabled);
    return true;
  }

  /// تفعيل/تعطيل تذكير المساء. يُرجع false إذا رفض المستخدم إذن الإشعارات.
  Future<bool> setEveningReminder(bool enabled) async {
    if (enabled) {
      final bool granted =
          await NotificationService.instance.requestPermissions();
      if (!granted) return false;
      await NotificationService.instance.scheduleEvening(
        state.eveningTime.hour,
        state.eveningTime.minute,
      );
    } else {
      await NotificationService.instance
          .cancel(NotificationIds.eveningReminder);
    }

    state = state.copyWith(eveningReminderEnabled: enabled);
    await _repository.saveSetting(StorageKeys.eveningReminderEnabled, enabled);
    return true;
  }

  Future<void> setMorningTime(TimeOfDay time) async {
    state = state.copyWith(morningTime: time);
    await _repository.saveSetting(StorageKeys.morningReminderHour, time.hour);
    await _repository.saveSetting(
        StorageKeys.morningReminderMinute, time.minute);
    if (state.morningReminderEnabled) {
      await NotificationService.instance
          .scheduleMorning(time.hour, time.minute);
    }
  }

  Future<void> setEveningTime(TimeOfDay time) async {
    state = state.copyWith(eveningTime: time);
    await _repository.saveSetting(StorageKeys.eveningReminderHour, time.hour);
    await _repository.saveSetting(
        StorageKeys.eveningReminderMinute, time.minute);
    if (state.eveningReminderEnabled) {
      await NotificationService.instance
          .scheduleEvening(time.hour, time.minute);
    }
  }

  Future<void> setHaptics(bool enabled) async {
    state = state.copyWith(hapticsEnabled: enabled);
    await _repository.saveSetting(StorageKeys.hapticsEnabled, enabled);
  }

  Future<void> setKeepScreenOn(bool enabled) async {
    state = state.copyWith(keepScreenOn: enabled);
    await _repository.saveSetting(StorageKeys.keepScreenOn, enabled);
  }

  /// تغيير حجم خط نص الذكر (يُحفظ ويُطبَّق على كل الشاشات).
  Future<void> setTextScale(double scale) async {
    final double clamped = scale.clamp(0.8, 1.6).toDouble();
    state = state.copyWith(textScale: clamped);
    await _repository.saveSetting(StorageKeys.dhikrTextScale, clamped);
  }
}

final StateNotifierProvider<SettingsNotifier, SettingsState> settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (Ref ref) => SettingsNotifier(ref.watch(progressRepositoryProvider)),
);
