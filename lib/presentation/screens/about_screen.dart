import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';

/// شاشة "حول التطبيق" — تحتوي التوقيع: صُنع بواسطة أصيل العتيبي.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = info.version);
    } catch (_) {
      // على بعض المنصّات قد لا تتوفر المعلومة — نتجاهلها بهدوء.
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('حول التطبيق')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: <Widget>[
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.nightlight_round,
                size: 46,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              AppInfo.appName,
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ),
          if (_version.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Center(
              child: Text(
                'الإصدار ${AppDateUtils.toArabicDigits(_version)}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('نبذة', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Text(
                  'أذكاري تطبيق بسيط يساعدك على المداومة على أذكار الصباح '
                  'والمساء، مع عدّاد لأيام الالتزام المتتالية يشجّعك على '
                  'الاستمرار. نصوص الأذكار مأخوذة من ${AppInfo.dataSource} '
                  'ومخزّنة داخل التطبيق، فيعمل كاملًا بدون إنترنت.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                const _Fact(
                  icon: Icons.volunteer_activism_rounded,
                  text: 'مجاني بالكامل — صدقة جارية، بلا اشتراكات ولا إعلانات.',
                ),
                const SizedBox(height: 10),
                const _Fact(
                  icon: Icons.wifi_off_rounded,
                  text: 'يعمل بدون إنترنت، وتذكيراته محلية على جهازك.',
                ),
                const SizedBox(height: 10),
                const _Fact(
                  icon: Icons.lock_outline_rounded,
                  text: 'بياناتك تبقى على جهازك ولا تُرفع إلى أي خادم إطلاقًا.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ==================== التوقيع ====================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: <Color>[AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: Column(
              children: <Widget>[
                Text(
                  'صُنع بواسطة',
                  style: TextStyle(
                    fontFamily: AppFonts.ui,
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppInfo.author,
                  style: TextStyle(
                    fontFamily: AppFonts.quran,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: 44,
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'نسأل الله أن يجعله في ميزان حسنات كل من انتفع به',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.ui,
                    fontSize: 12.5,
                    height: 1.8,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
