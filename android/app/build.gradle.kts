plugins {
    id("com.android.application")
    // يجب أن يأتي بعد إضافة Android.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.aseelotibi.athkari"
    // نتبع إصدارات Flutter نفسها حتى لا يحدث تعارض عند تحديث الـ SDK.
    compileSdk = flutter.compileSdkVersion
    // لا نحدّد ndkVersion: التطبيق لا يحتوي أي كود أصلي (C/C++)، وتحديدها
    // يجبر Gradle على تنزيل NDK بحجم ~٣ GB بلا فائدة.

    compileOptions {
        // مطلوب لمكتبة flutter_local_notifications (تستخدم واجهات java.time).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.aseelotibi.athkari"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // للنشر على المتاجر: أنشئ مفتاح توقيع خاصًا واستبدل هذا السطر.
            // نستخدم مفتاح التصحيح مؤقتًا حتى يعمل `flutter run --release` مباشرة.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
