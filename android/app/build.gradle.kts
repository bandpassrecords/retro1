import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

// Load keystore properties from key.properties file (for release signing)
val keystorePropertiesFile = rootProject.file("android/key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.bandpassrecords.retro1"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true // Necessário para flutter_local_notifications
    }
    
    // Suprimir warnings de Java 8 de plugins Flutter antigos
    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.addAll(listOf("-Xlint:-options"))
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.bandpassrecords.retro1"
        minSdk = if (flutter.minSdkVersion >= 24) flutter.minSdkVersion else 24 // ffmpeg_kit_flutter_new requer API 24+
        targetSdk = 36
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                val keystoreFile = keystoreProperties["storeFile"] as String?
                if (keystoreFile != null) {
                    val keystorePath = rootProject.file("android/app/$keystoreFile")
                    if (keystorePath.exists()) {
                        keyAlias = keystoreProperties["keyAlias"] as String?
                        keyPassword = keystoreProperties["keyPassword"] as String?
                        storeFile = keystorePath
                        storePassword = keystoreProperties["storePassword"] as String?
                    } else {
                        throw GradleException("Keystore file not found: ${keystorePath.absolutePath}")
                    }
                } else {
                    throw GradleException("storeFile not specified in key.properties")
                }
            }
        }
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
        release {
            // REQUIRED: Use release signing config - fail if keystore doesn't exist
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                throw GradleException(
                    "Release builds require a keystore. " +
                    "Please create android/key.properties and android/app/release.keystore"
                )
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring para flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
