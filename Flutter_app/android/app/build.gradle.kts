import com.android.build.api.dsl.ApplicationExtension
import org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    compileSdk = 35
    namespace = "com.example.sensorapp"

    defaultConfig {
        applicationId = "com.example.sensorapp"
        minSdk = 21
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlin {
        jvmToolchain(17)
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation ("androidx.multidex:multidex:2.0.1")
    implementation("com.android.support:support-v4:27.1.1")
    implementation("com.google.firebase:firebase-core:17.0.0")
    implementation("com.google.firebase:firebase-database:20.0.0")
}

flutter {
    source = "../.."
}