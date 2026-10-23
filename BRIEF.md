# برومت تعريفي كامل بمشروع «أذكاري»

> انسخ كل ما تحت هذا السطر وألصقه للذكاء الاصطناعي الآخر.

---

أعمل على تطبيق جوال اسمه **«أذكاري»** مبني بـ Flutter. هذا وصف كامل ودقيق للمشروع وحالته الحالية. اقرأه كاملًا قبل أن تقترح أي شيء، ولا تفترض معلومات غير مذكورة هنا — إن احتجت تفصيلًا غير موجود، اسألني.

## ١) ما هو التطبيق

تطبيق عربي لمتابعة **أذكار الصباح والمساء** يوميًا، مع **عدّاد سلسلة التزام (Streak)** يشجّع على المداومة.

- **مجاني بالكامل — صدقة جارية**: بلا اشتراكات، بلا إعلانات، بلا أي نظام دفع، بلا تتبّع.
- المؤلف: **أصيل العتيبي** (ذكر — خاطبني بصيغة المذكّر).
- الشعار داخل التطبيق: «صدقة جارية — مجاني بالكامل بلا إعلانات».
- واجهة **عربية RTL بالكامل**. لا توجد لغة ثانية.
- مصدر النصوص: **حصن المسلم**، مع ذكر المرجع والفضل لكل ذكر.

### الفكرة الجوهرية التي تميّزه

السلسلة **لا تكافئ فتح التطبيق ولا النقر** — تكافئ **الإتمام**. اليوم لا يُحتسب إلا إذا أُكملت **كل** أذكار الصباح **وكل** أذكار المساء في نفس اليوم بتوقيت جهاز المستخدم المحلي. أي اقتراح يخفّف هذه القاعدة يخالف روح التطبيق.

## ٢) بيئة العمل على جهازي

- **ويندوز 11** — ولا أملك جهاز Mac إطلاقًا. أي حل يتطلب Mac محليًا غير قابل للتنفيذ.
- Flutter **3.47.2** (قناة stable) — مثبّت في `D:\dev\flutter`
- Dart **3.13.2**
- Android SDK في `D:\Android\Sdk`
- مخزن Gradle منقول إلى `D:\gradle-home` (متغيّر البيئة `GRADLE_USER_HOME`) لأن قرص C ممتلئ
- **مجلد المشروع:** `C:\Users\Aseel\Desktop\athkari-app`
- أداة `sdkmanager`/`android.exe` من سطر الأوامر **معطوبة** على جهازي (تنهار بـ `0xC0000409`)؛ أي تثبيت لحزم Android SDK يجب أن يتم من واجهة Android Studio.

## ٣) الحالة الحالية (أهم قسم)

| المنصة | الحالة |
|---|---|
| **iOS** | **الهدف الأساسي للنشر.** مجلد `ios/` مجهّز بالكامل، ويُبنى على خوادم GitHub (macOS) بنجاح، ويقلع على محاكي iPhone بلا انهيار. |
| **Android** | يعمل بالكامل وبناؤه ناجح، لكنه **ليس الأولوية الآن**. لا تحذفه ولا تعدّله إلا لضرورة. |
| **Web** | منشور فعليًا للمعاينة على: `https://aseelotibi5656-crypto.github.io/athkari/` |

**ما ينقص للنشر على App Store:** اشتراك **Apple Developer Program** (٩٩$/سنة). لم أشترك بعد. كل الجانب التقني جاهز ومجرَّب وينتظر الحساب فقط.

**المستودع:** `https://github.com/aseelotibi5656-crypto/athkari` (عام، فرع `main`، ٧ commits)

## ٤) التقنيات والحزم

Flutter + Dart. إدارة الحالة: **Riverpod**. التخزين المحلي: **Hive**. لا يوجد أي كود أصلي (C/C++) ولا `ndkVersion`.

```yaml
# التبعيات الفعلية من pubspec.yaml
flutter_riverpod: ^2.5.1
hive: ^2.2.3
hive_flutter: ^1.1.0
path_provider: ^2.1.4
flutter_local_notifications: ^17.2.3
timezone: ^0.9.4
flutter_timezone: ^3.0.1
intl: ^0.20.3
package_info_plus: ^8.0.2
wakelock_plus: ^1.2.8
# dev
flutter_lints: ^4.0.0
flutter_launcher_icons: ^0.14.4
```

**مهم جدًا:** التطبيق **محلي بالكامل ولا يتصل بأي خادم إطلاقًا**. أُزيلت نهائيًا كل حزم Firebase (`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging`) و`google_sign_in` و`sign_in_with_apple` و`crypto` و`url_launcher` — لأنها لم تكن مستخدمة فعليًا، وكانت تكبّر الحجم وتعقّد مراجعة App Store. لا تقترح إعادتها. **لا يوجد تسجيل دخول ولا حسابات ولا مزامنة سحابية**، وهذا قرار مقصود لا نقص.

## ٥) بنية المشروع

المجلد: `C:\Users\Aseel\Desktop\athkari-app`

```
lib/                                  (٢٦ ملف Dart، ~٣٩٩٧ سطر)
  main.dart                           نقطة الدخول: قفل الاتجاه الرأسي ← Hive ← الإشعارات
  app.dart                            MaterialApp: الثيم، العربية، RTL
  core/
    constants.dart                    AppInfo / AdhkarCategory / AssetPaths / StorageKeys / Defaults
    theme/app_colors.dart             لوحة الألوان كاملة
    theme/app_theme.dart              الثيم الفاتح والداكن والخطوط
    utils/date_utils.dart             منطق التواريخ المحلية — أساس دقّة السلسلة
  data/
    models/dhikr_model.dart           Dhikr + AdhkarCollection
    models/day_progress_model.dart    DayProgress: dateKey, counts, morningCompleted, eveningCompleted
    models/streak_model.dart          خوارزمية السلسلة (أهم ملف منطقي)
    repositories/adhkar_repository.dart    قراءة JSON المحلي مع كاش
    repositories/progress_repository.dart  الحفظ في Hive
    datasources/local/adhkar_morning.json  ٢٤ ذكرًا
    datasources/local/adhkar_evening.json  ٢٣ ذكرًا
  providers/
    repository_providers.dart         adhkarRepositoryProvider, progressRepositoryProvider
    adhkar_provider.dart              allAdhkarProvider (FutureProvider), DayProgressNotifier
    streak_provider.dart              streakProvider (StateNotifier)
    settings_provider.dart            settingsProvider — التذكيرات وإعدادات القراءة
  presentation/
    screens/   splash / home / adhkar / settings / about
    widgets/   dhikr_card / streak_badge / progress_bar / category_card / month_calendar
  services/
    notification_service.dart         التذكيرات المحلية + المنطقة الزمنية

assets/
  fonts/   Almarai-Regular/Bold/ExtraBold.ttf  +  Amiri-Regular/Bold.ttf
  icon/    icon.png  (٥١٢×٥١٢، هلال أبيض على تدرّج أخضر)

test/streak_logic_test.dart           ٢٣ اختبارًا، ٢٦٩ سطرًا — كلها تمر
android/   ios/   web/                منصّات مولّدة
tools/     setup.ps1, patch_ios.ps1
.github/workflows/   android-build.yml, ios-build.yml, web-deploy.yml
```

## ٦) صيغة بيانات الأذكار

كل ملف JSON **كائن واحد** (ليس مصفوفة):

```json
{
  "category": "morning",
  "title": "أذكار الصباح",
  "source": "حصن المسلم",
  "adhkar": [
    {
      "id": "morning_001",
      "title": "آية الكرسي",
      "text": "أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ...",
      "repeat": 1,
      "reference": "سورة البقرة: ٢٥٥",
      "virtue": "..."
    }
  ]
}
```

الملفات مُسجَّلة في `pubspec.yaml` كأصول بمسارها داخل `lib/` (غير معتاد لكنه مقصود ويعمل).

## ٧) خوارزمية السلسلة — المنطق الأهم

في `lib/data/models/streak_model.dart`:

1. السلسلة **لا تُخزَّن كعدّاد** — تُشتقّ في كل مرة من مجموعة الأيام المكتملة. هذا يحميها من تغيير ساعة الجهاز، وإعادة تثبيت التطبيق، وتعديل يوم قديم.
2. إذا كان **اليوم** مكتملًا → نعدّ رجوعًا بدءًا من اليوم.
3. وإلا إذا كان **الأمس** مكتملًا → السلسلة ما زالت حيّة ونعدّ من الأمس (أمام المستخدم بقية اليوم لإكمالها).
4. وإلا → صفر، لأن يومًا كاملًا فات بلا إكمال. وتظهر رسالة **«ما عليك، ابدأ من جديد 🤍»** لا رسالة فشل.
5. `history` (سجل الأيام المكتملة) يبقى كاملًا دائمًا حتى لو انكسرت السلسلة، ليعرض التقويم الشهري التاريخ الحقيقي.
6. يوجد حدّ أمان `streak > 100000` يمنع أي حلقة لا نهائية ببيانات تالفة.
7. `calculateBestStreak` تحسب أطول سلسلة في السجل كله، ولا تنقص أبدًا.

**حصانة التوقيت:** كل التواريخ تُطبَّع إلى منتصف الليل المحلي وتُخزَّن كنص `yyyy-MM-dd` بلا معلومات منطقة زمنية، والفروق تُحسب على التواريخ المُطبَّعة — فلا يؤثّر التوقيت الصيفي (يوم من ٢٣ أو ٢٥ ساعة) ولا السفر بين المناطق الزمنية على العدّ.

الاختبارات تغطّي: التتابع، الفجوات، حدود الشهر والسنة، السنة الكبيسة، اختلاف ساعات اليوم، والمفاتيح التالفة.

## ٨) التخزين المحلي (Hive)

صندوقان:

- `athkari_progress` — المفتاح = تاريخ اليوم `"yyyy-MM-dd"`، والقيمة تقدّم ذلك اليوم
- `athkari_settings` — مفاتيحه:
  `morning_reminder_enabled`, `evening_reminder_enabled`,
  `morning_reminder_hour`, `morning_reminder_minute`,
  `evening_reminder_hour`, `evening_reminder_minute`,
  `haptics_enabled`, `keep_screen_on`, `dhikr_text_scale`,
  `last_seen_streak`, `best_streak`

**القيم الافتراضية للتذكيرات:** الصباح ٦:٣٠، المساء ١٧:٣٠.

## ٩) الهوية البصرية

```
primary        #0E7C6B   (أخضر)        primaryDark   #075246
primaryLight   #2FA98F
morning        #E0A22B   (ذهبي دافئ)   morningSoft   #FFF3DC
evening        #4A56A8   (نيلي هادئ)   eveningSoft   #E9EBFA
background     #F6F4EF   surface  #FFFFFF   surfaceMuted #EFEDE6
backgroundDark #10161A   surfaceDark #19222A  surfaceMutedDark #222D36
textPrimary    #1B2427   textSecondary #5C6A70
textPrimaryDark #EDF1F3  textSecondaryDark #9BAAB3
success  #2E9E5B   successSoft #E4F5EA
streak   #E2622F   (لهب السلسلة)
divider  #E2DFD6   dividerDark #2C3841
```

**الخطوط:** `Almarai` للواجهة (أوزان 400/700/800)، و`Amiri` لنصوص الأذكار (400/700). كلاهما مضمَّن داخل التطبيق. وضع داكن مدعوم بالكامل.

## ١٠) السلوك والتفاعل

- نقرة على كرت الذكر → ينقص العدّاد واحدًا.
- **ضغطة مطوّلة** → يُكمل الذكر كاملًا دفعة واحدة (لمن قرأه من المصحف).
- شاشة الأذكار تفعّل `WakelockPlus` لمنع إطفاء الشاشة أثناء القراءة، وتعطّله عند الخروج.
- الشاشة الرئيسية: شارة السلسلة، كرتا الصباح والمساء مع حلقة تقدّم، وتقويم شهري يلوّن الأيام المكتملة بالأخضر.
- التطبيق **مقفول على الوضع الرأسي** في `main.dart` عبر `setPreferredOrientations`.

## ١١) الإشعارات

- تذكيرات **محلية فقط** (`flutter_local_notifications`) — لا إشعارات بعيدة ولا Push.
- تُجدول يوميًا بـ `zonedSchedule` مع `matchDateTimeComponents: DateTimeComponents.time`.
- المنطقة الزمنية تُضبط من `flutter_timezone` عند الإقلاع.
- الإذن **لا يُطلب عند الإقلاع** — يُطلب فقط عند تفعيل التذكير من الإعدادات (سلوك تفضّله Apple).
- على أندرويد: اختيار ذكي بين `exactAllowWhileIdle` و`inexactAllowWhileIdle` حسب صلاحية التنبيه الدقيق.
- `isSupported` محروسة بـ `!kIsWeb && (Platform.isAndroid || isIOS || isMacOS)` — ولهذا لا تنهار نسخة الويب.
- في `ios/Runner/AppDelegate.swift` أُضيف `UNUserNotificationCenter.current().delegate = self` قبل `super` — تشترطه `flutter_local_notifications`، وبدونه لا تظهر التذكيرات والتطبيق في المقدمة.

## ١٢) إعدادات iOS

- **Bundle ID:** `com.aseelotibi.athkari` (مطابق لـ Android)
- **اسم العرض:** `أذكاري` — و`CFBundleLocalizations`: `ar`, `en`
- **Deployment Target:** iOS 15.0 (أعلى بكثير مما تطلبه أي حزمة — خيار متحفّظ)
- **iPhone فقط:** `TARGETED_DEVICE_FAMILY = 1` (لتفادي إلزام صور iPad في المتجر)
- **الاتجاه:** رأسي فقط (مطابق لقفل الكود)
- `ITSAppUsesNonExemptEncryption = false`
- الأيقونات مولّدة من `assets/icon/icon.png` عبر `flutter_launcher_icons` مع `remove_alpha_ios: true` (App Store يرفض قناة الألفا)
- شاشة إقلاع بلون خلفية التطبيق عبر `LaunchBackground.colorset` (فاتح `#F6F4EF` / داكن `#10161A`)
- `ios/Podfile` يثبّت `platform :ios, '15.0'` ويوحّد `IPHONEOS_DEPLOYMENT_TARGET` لكل الـ Pods في `post_install`
- `Podfile.lock` **غير مرفوع** بعد — يُولَّد على الخادم

## ١٣) إعدادات Android

- `applicationId` و`namespace`: `com.aseelotibi.athkari`
- `minSdk` 24 · `targetSdk`/`compileSdk` من Flutter
- **التوقيع ما زال `signingConfigs.getByName("debug")`** — مؤقت ليعمل `flutter run --release`. يجب استبداله بمفتاح حقيقي قبل أي نشر على Google Play (لم يُنشأ بعد).
- أحجام البناء الحالية: APK موحّد ٥٦ MB، و arm64-v8a ٢٠.٨ MB، armeabi-v7a ١٨.٥ MB، x86_64 ٢٢.٣ MB

## ١٤) البناء التلقائي (GitHub Actions)

ثلاثة ملفات في `.github/workflows/`:

**`android-build.yml`** — يحلّل ويختبر ويبني APK مع كل رفع.

**`ios-build.yml`** — وظيفتان:
- `verify`: **لا تحتاج أي أسرار ولا حساب Apple.** تحلّل، تختبر، تبني `flutter build ios --release --no-codesign`، تحزم `.ipa` غير موقّع للتجربة الشخصية، ثم تشغّل التطبيق فعليًا على محاكي iPhone وتتأكد أنه لم ينهر بعد ١٥ ثانية (عبر PID + `kill -0`)، وتلتقط صورة شاشة. آخر تشغيل: **ناجح في ١٤ دقيقة**.
- `release`: تبني `.ipa` موقّعًا وترفعه إلى TestFlight. تعمل يدويًا أو عند دفع وسم `v*`. **لم تُشغَّل بعد** لأنها تحتاج الأسرار السبعة. تتحقق قبل البناء من: وجود الأسرار، شكل Team ID و Key ID و Issuer ID، صلاحية base64، صحة كلمة مرور الـ p12، كون الشهادة من نوع Apple Distribution، ومطابقة ملف التزويد للتطبيق والفريق وعدم انتهائه، ثم `altool --validate-app` قبل الرفع. كل حالة لها رسالة خطأ تشرح المصدر.

الأسرار المطلوبة لاحقًا (أسماء فقط — لم يُنشأ أي منها):
`IOS_DIST_CERT_P12_BASE64`, `IOS_DIST_CERT_PASSWORD`, `IOS_PROVISIONING_PROFILE_BASE64`, `APPLE_TEAM_ID`, `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_P8_BASE64`

**`web-deploy.yml`** — يبني `flutter build web --release --base-href=/athkari/` وينشر على GitHub Pages. ملاحظة: تفعيل Pages نفسه لا يمكن من الـ workflow (صلاحية `GITHUB_TOKEN` لا تسمح) — فُعِّل يدويًا من إعدادات المستودع.

## ١٥) نسخة الويب

بُنيت **بلا أي تعديل على كود التطبيق** — حُرّاس `kIsWeb` الموجودة أصلًا كفت. مهيّأة كـ PWA: `manifest.json` بالعربي RTL، وميتا iOS للعمل بملء الشاشة عند الإضافة للشاشة الرئيسية، وألوان ثيم للوضعين. حجم البناء ~٤٣ MB (معظمه CanvasKit).

**القيد:** التذكيرات لا تعمل في نسخة الويب. بقية الوظائف كاملة والتقدّم يُحفظ في متصفح الجهاز.

## ١٦) أوامر البناء

```bash
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings   # نظيف حاليًا
flutter test                                            # ٢٣/٢٣ تمر
flutter build apk --release
flutter build appbundle --release
flutter build web --release --base-href=/athkari/
dart run flutter_launcher_icons                         # إعادة توليد أيقونات iOS
```

بناء iOS لا يعمل على ويندوز — يتم على GitHub Actions فقط.

## ١٧) مشاكل معروفة لم تُحل بعد

1. **الصفر يظهر كمعيّن أسود ◆** في شارة السلسلة. السبب ليس خطأً: الصفر العربي-الهندي `٠` يُكتب نقطة، وعند حجم ٤٦ بكسل بخط Almarai ExtraBold يصير معيّنًا كبيرًا مربكًا. الحل المقترح (لم يُنفَّذ): إخفاء الرقم كليًا عند صفر والاكتفاء برسالة «ابدأ سلسلتك اليوم».
2. **أيقونة التطبيق ٥١٢×٥١٢** والمتجر يريد ١٠٢٤ — النسخة الحالية مُكبَّرة. المصدر الأصلي غير متوفر لديّ.
3. **توقيع Android** ما زال مفتاح التصحيح.
4. **`Podfile.lock`** غير مرفوع للمستودع.
5. التطبيق **لم يُجرَّب على جهاز iPhone حقيقي** بعد — فقط على محاكي iOS وجوال أندرويد حقيقي ونسخة الويب.

## ١٨) ما أريده منك

اقرأ ما سبق كمرجع كامل للمشروع. عند أي اقتراح، التزم بما يلي:

- **لا تعِد كتابة التطبيق** ولا تقترح تغيير التقنية (لا React Native، لا Expo/EAS — وقد تحقّقنا أن EAS لا تدعم Flutter أصلًا).
- **لا تفترض وجود Mac.**
- **لا تغيّر وظائف التطبيق أو تصميمه** إلا إذا طلبت ذلك صراحةً، أو كان التغيير ضروريًا لتوافق منصة.
- لا تقترح حذف `android/` أو تعطيله.
- احترم قاعدة السلسلة: اليوم لا يُحتسب إلا بإكمال الصباح والمساء معًا.
- لا تطلب مني كلمات مرور Apple ولا ملفات `.p8`/`.p12`/`.mobileprovision` — سأضيفها بنفسي كأسرار في GitHub عند الحاجة.
- خاطبني بصيغة المذكّر بالعربي.

ابدأ بتأكيد فهمك للمشروع في فقرة قصيرة، ثم اسألني عمّا تحتاج توضيحه قبل أي اقتراح.
