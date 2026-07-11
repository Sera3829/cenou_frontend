import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Clé de release : android/key.properties en local, variables d'environnement
// en CI (GitHub Actions). Si rien n'est trouvé, repli sur la clé de debug
// pour ne pas bloquer les builds de développement.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) load(FileInputStream(f))
}
val releaseStoreFile = (keystoreProperties.getProperty("storeFile")
    ?: System.getenv("ANDROID_KEYSTORE_PATH"))
val releaseStorePassword = (keystoreProperties.getProperty("storePassword")
    ?: System.getenv("ANDROID_KEYSTORE_PASSWORD"))
val releaseKeyAlias = (keystoreProperties.getProperty("keyAlias")
    ?: System.getenv("ANDROID_KEY_ALIAS"))
val releaseKeyPassword = (keystoreProperties.getProperty("keyPassword")
    ?: System.getenv("ANDROID_KEY_PASSWORD"))
val hasReleaseKey = releaseStoreFile != null && file(releaseStoreFile).exists()

android {
    namespace = "com.cenou.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.cenou.mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKey)
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
            isShrinkResources = true
            isMinifyEnabled = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(kotlin("stdlib-jdk8"))
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}