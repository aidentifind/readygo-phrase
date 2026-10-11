import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ストア提出用の本番署名(アップロード鍵)。android/key.properties はコミットしない
// (.gitignore済み)。作り方は android/RELEASE_SIGNING.md を参照(readygo-speakと同じ仕組み)。
//
// 無い場合、配布用ビルド(assembleRelease/bundleRelease、Security issue #5)は下のタスク
// グラフチェックで明確なエラーにして止める。ローカルで `flutter run --release` を試すだけなら
// debug鍵へのフォールバックを明示的に許可する `-PallowDebugRelease=true` を付けること。
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val allowDebugRelease = (project.findProperty("allowDebugRelease") as String?) == "true"

android {
    // Speakと同じ命名規則で確定(2026-10-08、CLAUDE.md参照)。公開後は変更不可なので要注意。
    namespace = "space.readygo_english.phrase"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "space.readygo_english.phrase"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // 配布用ビルドで本番署名が無い場合に誤ってdebug鍵のapk/aabを作らないよう、
            // 下のタスクグラフチェックで止める。ここではこれまで通りdebug鍵を割り当てておき
            // (そうしないとAGPの設定自体が失敗する)、実際に止めるかどうかはチェック側で判断する。
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

// 本番署名(android/key.properties)が無いまま配布用ビルド(assembleRelease/bundleRelease。
// `flutter build apk --release`・`flutter build appbundle --release`・Play Store提出)を
// 実行しようとした場合はエラーで止める(Security issue #5)。ローカルでreleaseモードの
// 動作確認(`flutter run --release`)だけしたい場合は、明示的な開発用設定として
// `-PallowDebugRelease=true` を付けて区別する。手順は android/RELEASE_SIGNING.md 参照。
gradle.taskGraph.whenReady {
    val buildingForDistribution = allTasks.any {
        it.name == "assembleRelease" || it.name == "bundleRelease"
    }
    if (buildingForDistribution && !hasReleaseKeystore && !allowDebugRelease) {
        throw GradleException(
            "android/key.properties が見つからないため、配布用のreleaseビルドを停止しました。\n" +
                "作り方は android/RELEASE_SIGNING.md を参照してください。\n" +
                "ローカルでreleaseモードの動作確認だけしたい場合は " +
                "-PallowDebugRelease=true を付けて実行してください(debug鍵で署名されます)。"
        )
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
