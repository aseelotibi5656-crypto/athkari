allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// توحيد إصدار جافا لكل الحزم الفرعية على 17.
//
// السبب: بعض حزم Flutter مكتوبة لجافا 11 مع كوتلن 1.8، وكوتلن 2.x يرفض هذا
// التضارب ويوقف البناء برسالة "Inconsistent JVM-target compatibility".
// بدل تعديل كل حزمة أو تجميد إصداراتها، نفرض 17 على الاثنين في كل المشاريع.
subprojects {
    afterEvaluate {
        // نضبط compileOptions من إضافة أندرويد نفسها، لأن ضبط مهام JavaCompile
        // مباشرةً لا يفيد: الإضافة تعيد كتابتها من إعداداتها الخاصة.
        // نستخدم الانعكاس (reflection) لتفادي الاعتماد على أصناف AGP في
        // ملف الجذر، فتبقى القاعدة صالحة مع أي إصدار من الإضافة.
        extensions.findByName("android")?.let { androidExtension ->
            runCatching {
                val compileOptions = androidExtension.javaClass
                    .getMethod("getCompileOptions")
                    .invoke(androidExtension)
                val setter = { name: String ->
                    compileOptions.javaClass
                        .getMethod(name, Any::class.java)
                        .invoke(compileOptions, JavaVersion.VERSION_17)
                }
                setter("setSourceCompatibility")
                setter("setTargetCompatibility")
            }
        }

        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>()
            .configureEach {
                compilerOptions.jvmTarget.set(
                    org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17,
                )
            }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
