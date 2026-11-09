import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val uploadSigningFile = providers.environmentVariable("SHIYU_ANDROID_SIGNING_PROPERTIES")
    .map { rootProject.file(it) }
    .orNull
val uploadSigning = uploadSigningFile?.let { config ->
    require(config.isFile) { "SHIYU_ANDROID_SIGNING_PROPERTIES 必须指向签名配置文件。" }
    Properties().apply { config.reader(Charsets.UTF_8).use { load(it) } }
}

fun Properties.signingValue(name: String): String =
    getProperty(name)?.takeIf { it.isNotBlank() }
        ?: error("Android 上传签名配置缺少 $name。")

android {
    namespace = "com.growthrecord.shiyu"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    buildFeatures {
        buildConfig = true
    }

    bundle {
        language {
            // 应用内可选择不同于系统的语言，桌面组件离线也要有对应资源。
            enableSplit = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.growthrecord.shiyu"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (uploadSigning != null && uploadSigningFile != null) {
            create("upload") {
                storeFile = uploadSigningFile.parentFile.resolve(uploadSigning.signingValue("storeFile"))
                storePassword = uploadSigning.signingValue("storePassword")
                keyAlias = uploadSigning.signingValue("keyAlias")
                keyPassword = uploadSigning.signingValue("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName(if (uploadSigning == null) "debug" else "upload")
        }
    }
}

if (uploadSigning == null) {
    // 保留本地调试签名的 Release APK，商店 AAB 必须使用上传密钥。
    tasks.matching { it.name == "bundleRelease" || it.name == "signReleaseBundle" }.configureEach {
        doFirst { error("构建 Google Play AAB 前，请设置 SHIYU_ANDROID_SIGNING_PROPERTIES。") }
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
    implementation("net.java.dev.jna:jna:5.17.0@aar")
}
