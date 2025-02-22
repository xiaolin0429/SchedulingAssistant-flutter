pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.2.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.22" apply false
}

// 全局仓库配置
@Suppress("UnstableApiUsage")
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven { 
            url = uri("https://storage.googleapis.com/download.flutter.io")
            content {
                includeGroup("io.flutter")
            }
        }
        maven { 
            url = uri("https://dl.google.com/dl/android/maven2")
            content {
                includeGroupByRegex("androidx.*")
                includeGroupByRegex("com\\.google.*")
                includeGroupByRegex("com\\.android.*")
            }
        }
    }
}

include(":app")

// Flutter plugins
val flutterProjectRoot: File = rootDir.parentFile
val plugins: File = File("$flutterProjectRoot/.flutter-plugins")
if (plugins.exists()) {
    plugins.readLines().forEach { line: String ->
        if (line.isNotEmpty() && line.contains('=')) {
            try {
                val parts: List<String> = line.split('=')
                if (parts.size >= 2) {
                    val name: String = parts[0].trim()
                    val path: String = parts[1].trim()
                    if (name.isNotEmpty() && path.isNotEmpty()) {
                        val pluginProject = File(path, "android")
                        if (pluginProject.exists()) {
                            include(":$name")
                            project(":$name").projectDir = pluginProject
                        }
                    }
                }
            } catch (e: Exception) {
                println("Error processing plugin line: $line")
                e.printStackTrace()
            }
        }
    }
}

