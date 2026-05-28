import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load signing credentials from key.properties (local) or environment variables (CI).
// key.properties is gitignored — never commit it.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}

fun keystoreProp(name: String): String =
    keystoreProperties.getProperty(name) ?: System.getenv(name) ?: ""

android {
    namespace = "com.totalmote.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias     = keystoreProp("keyAlias")
            keyPassword  = keystoreProp("keyPassword")
            storeFile    = keystoreProp("storeFile").takeIf { it.isNotEmpty() }?.let { file(it) }
            storePassword = keystoreProp("storePassword")
        }
    }

    defaultConfig {
        applicationId = "com.totalmote.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
