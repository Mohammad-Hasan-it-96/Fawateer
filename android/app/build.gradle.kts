import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // FCM live-unlock. Paired with the plugin declaration in settings.gradle.kts;
    // needs android/app/google-services.json (gitignored) or the build fails.
    // See android/README-fcm.md.
    id("com.google.gms.google-services")
}

// Release signing. Secrets live in android/key.properties (gitignored) and point
// at a keystore stored OUTSIDE this repo. See docs/android-release-signing.md.
//
// Losing the keystore is unrecoverable: Android refuses an update signed with a
// different key, so users would have to uninstall — wiping their local SQLite
// (every invoice, customer and debt). Back it up before shipping.
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
val keystoreProperties = Properties().apply {
    if (hasReleaseKeystore) FileInputStream(keystorePropertiesFile).use { load(it) }
}

// Fail loudly rather than silently shipping a debug-signed release. A debug key
// expires after ~1 year and is not ours to control — a release APK signed with
// it is a trap that only springs once real shops are on it.
val isReleaseBuild = gradle.startParameter.taskNames.any {
    it.contains("Release", ignoreCase = true)
}
if (isReleaseBuild && !hasReleaseKeystore) {
    throw GradleException(
        "Release build requested but android/key.properties is missing.\n" +
        "A release APK must NOT be signed with the debug key.\n" +
        "See docs/android-release-signing.md to create the keystore, or re-create\n" +
        "key.properties on this machine if the keystore already exists."
    )
}

android {
    namespace = "com.mohamad.hasan.it.fawateer"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mohamad.hasan.it.fawateer"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
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
            // Guarded above: a release build without key.properties throws, so
            // the debug fallback only ever applies to local debug/profile runs.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
