import java.util.Properties
import java.io.FileInputStream



plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}


android {
    namespace = "com.ztd.ztd_password_manager"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }



    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.ztd.ztd_password_manager"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            var signatureConfigured = false
            val keystorePropertiesFile = rootProject.file("key.properties")
            
            if (keystorePropertiesFile.exists()) {
                val keystoreProperties = Properties()
                keystoreProperties.load(FileInputStream(keystorePropertiesFile))

                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                signatureConfigured = true
            } else if (System.getenv("KEYSTORE_PASSWORD") != null) {
                val ksPath = System.getenv("KEYSTORE_FILE_PATH") ?: "upload-keystore.jks"
                val ksFile = file(ksPath)
                if (ksFile.exists()) {
                    keyAlias = System.getenv("KEY_ALIAS") ?: "upload"
                    keyPassword = System.getenv("KEY_PASSWORD") ?: System.getenv("KEYSTORE_PASSWORD")
                    storeFile = ksFile
                    storePassword = System.getenv("KEYSTORE_PASSWORD")
                    signatureConfigured = true
                }
            }

            if (!signatureConfigured) {
                // Fallback: Using debug signature for release build ONLY if it exists.
                val debugConfig = getByName("debug")
                val debugStoreFile = debugConfig.storeFile
                if (debugStoreFile != null && debugStoreFile.exists()) {
                    keyAlias = debugConfig.keyAlias
                    keyPassword = debugConfig.keyPassword
                    storeFile = debugStoreFile
                    storePassword = debugConfig.storePassword
                }
            }
        }
    }

    buildTypes {
        release {
            val releaseConfig = signingConfigs.getByName("release")
            // Only use signingConfig if storeFile exists to avoid build failure in CI without secrets
            if (releaseConfig.storeFile?.exists() == true) {
                signingConfig = releaseConfig
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.appcompat:appcompat:1.6.1")
}
