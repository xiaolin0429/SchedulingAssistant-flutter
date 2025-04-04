plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

// 添加签名配置处理逻辑
val keystorePropertiesFile = rootProject.file("key.properties")

android {
    namespace = "com.schedule.assistant"
    compileSdk = 35

    ndkVersion = "28.0.13004108"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    // 添加签名配置
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                val properties = Properties()
                properties.load(FileInputStream(keystorePropertiesFile))
                
                keyAlias = properties.getProperty("keyAlias")
                keyPassword = properties.getProperty("keyPassword")
                storeFile = file(properties.getProperty("storeFile"))
                storePassword = properties.getProperty("storePassword")
            }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.schedule.assistant"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 21
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
        signingConfig = signingConfigs.getByName("debug")
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            // 使用发布签名配置
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    implementation("androidx.annotation:annotation:1.9.1")
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("org.jetbrains.kotlin:kotlin-stdlib:2.0.0")
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.appcompat:appcompat:1.7.0")
    
    // 添加 desugaring 依赖
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
