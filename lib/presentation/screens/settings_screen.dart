import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/streak_provider.dart';
import '../../services/notification_service.dart';
import 'about_screen.dart';

/// شاشة الإعدادات: التذكيرات، القراءة، العام، وحول التطبيق.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsState settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          _Section(
            title: 'التذكيرات',
            subtitle: 'تعمل بدون إنترنت، وحتى لو كان التطبيق مغلقًا',
            children: <Widget>[
              _ReminderTile(
                label: 'تذكير أذكار الصباح',
                icon: Icons.wb_sunny_rounded,
                accent: AppColors.morning,
                enabled: settings.morningReminderEnabled,
                time: settings.morningTime,
                onToggle: (bool value) =>
                    _toggleMorning(context, ref, value),
                onPickTime: () => _pickTime(
                  context,
                  ref,
                  initial: settings.morningTime,
                  isMorning: true,
                ),
              ),
              const Divider(height: 1),
              _ReminderTile(
                label: 'تذكير أذكار المساء',
                icon: Icons.nights_stay_rounded,
                accent: AppColors.evening,
                enabled: settings.eveningReminderEnabled,
                time: settings.eveningTime,
                onToggle: (bool value) =>
                    _toggleEvening(context, ref, value),
                onPickTime: () => _pickTime(
                  context,
                  ref,
                  initial: settings.eveningTime,
                  isMorning: false,
                ),
              ),
              if (NotificationService.instance.isSupported) ...<Widget>[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('تجربة الإشعار'),
                  subtitle: const Text('للتأكد أن التذكيرات تصل لجهازك'),
                  onTap: () async {
                    final bool granted = await NotificationService.instance
                        .requestPermissions();
                    if (!context.mounted) return;
                    if (!granted) {
                      _snack(context,
                          'لم يُمنح إذن الإشعارات — فعّله من إعدادات الجهاز');
                      return;
                    }
                    await NotificationService.instance.showTestNotification();
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          _Section(
            title: 'القراءة',
            children: <Widget>[
              SwitchListTile(
                value: settings.hapticsEnabled,
                onChanged: (bool value) =>
                    ref.read(settingsProvider.notifier).setHaptics(value),
                secondary: const Icon(Icons.vibration_rounded),
                title: const Text('اهتزاز خفيف عند كل تسبيحة'),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: settings.keepScreenOn,
                onChanged: (bool value) =>
                    ref.read(settingsProvider.notifier).setKeepScreenOn(value),
                secondary: const Icon(Icons.lightbulb_outline_rounded),
                title: const Text('إبقاء الشاشة مضاءة أثناء القراءة'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.format_size_rounded),
                title: const Text('حجم خط الذكر'),
                subtitle: Slider(
                  value: settings.textScale,
                  min: 0.8,
                  max: 1.6,
                  divisions: 8,
                  label: '×${settings.textScale.toStringAsFixed(1)}',
                  onChanged: (double value) =>
                      ref.read(settingsProvider.notifier).setTextScale(value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _Section(
            title: 'عام',
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('حول التطبيق'),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFC0392B)),
                title: const Text('حذف كل سجلّ التقدّم'),
                subtitle: const Text('لا يمكن التراجع عن هذه الخطوة'),
                onTap: () => _confirmClear(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Center(
            child: Text(
              AppInfo.madeBy,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleMorning(
      BuildContext context, WidgetRef ref, bool value) async {
    final bool ok =
        await ref.read(settingsProvider.notifier).setMorningReminder(value);
    if (!context.mounted) return;
    if (!ok) {
      _snack(context, 'لتفعيل التذكير، اسمح للتطبيق بالإشعارات من إعدادات جهازك');
    }
  }

  Future<void> _toggleEvening(
      BuildContext context, WidgetRef ref, bool value) async {
    final bool ok =
        await ref.read(settingsProvider.notifier).setEveningReminder(value);
    if (!context.mounted) return;
    if (!ok) {
      _snack(context, 'لتفعيل التذكير، اسمح للتطبيق بالإشعارات من إعدادات جهازك');
    }
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref, {
    required TimeOfDay initial,
    required bool isMorning,
  }) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isMorning ? 'وقت تذكير الصباح' : 'وقت تذكير المساء',
    );
    if (picked == null) return;

    final SettingsNotifier notifier = ref.read(settingsProvider.notifier);
    if (isMorning) {
      await notifier.setMorningTime(picked);
    } else {
      await notifier.setEveningTime(picked);
    }
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف كل سجلّ التقدّم؟'),
        content: Text(
          'سيُحذف سجلّ الأيام المكتملة والسلسلة نهائيًا من هذا الجهاز.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف',
                style: TextStyle(color: Color(0xFFC0392B))),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(progressRepositoryProvider).clearAllProgress();
    await ref.read(streakProvider.notifier).recalculate();
    if (!context.mounted) return;
    _snack(context, 'تم حذف السجل');
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

/// بطاقة قسم في الإعدادات.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: AppTheme.cardDecoration(context),
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// صف تذكير: مفتاح تفعيل + اختيار الوقت.
class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.label,
    required this.icon,
    required this.accent,
    required this.enabled,
    required this.time,
    required this.onToggle,
    required this.onPickTime,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final bool enabled;
  final TimeOfDay time;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SwitchListTile(
          value: enabled,
          onChanged: onToggle,
          secondary: Icon(icon, color: accent),
          title: Text(label),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState:
              enabled ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: ListTile(
            contentPadding: const EdgeInsetsDirectional.only(
              start: 56,
              end: 16,
              bottom: 6,
            ),
            title: const Text('وقت التذكير'),
            trailing: TextButton(
              onPressed: onPickTime,
              child: Text(
                AppDateUtils.formatTime(time.hour, time.minute),
                style: TextStyle(
                  fontFamily: AppFonts.ui,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ),
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
