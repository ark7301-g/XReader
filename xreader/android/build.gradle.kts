buildscript {
    val kotlinVersion by extra("1.9.10")
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    afterEvaluate {
        if (plugins.hasPlugin("com.android.library")) {
            configure<com.android.build.gradle.LibraryExtension> {
                if (namespace == null) {
                    namespace = "com.xreader.${project.name}"
                }
            }
        }
        if (plugins.hasPlugin("com.android.application")) {
            configure<com.android.build.gradle.AppExtension> {
                if (namespace == null) {
                    namespace = "com.xreader.${project.name}"
                }
            }
        }
    }
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
