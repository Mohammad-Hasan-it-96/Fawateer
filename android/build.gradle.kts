allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// flutter_vibrate 1.3.0 (discontinued) compiles its resources against an SDK
// older than API 31, which lacks `android:attr/lStar` and fails release resource
// linking ("resource android:attr/lStar not found"). Force any such stale plugin
// module to compile against a modern SDK so AAPT can resolve the attribute.
// Registered before the evaluationDependsOn block below so the afterEvaluate hook
// is attached while every subproject is still unevaluated.
subprojects {
    afterEvaluate {
        val androidExtension = project.extensions.findByName("android")
        if (androidExtension is com.android.build.gradle.BaseExtension) {
            val current = androidExtension.compileSdkVersion
                ?.substringAfter("android-")
                ?.toIntOrNull()
            if (current == null || current < 34) {
                androidExtension.compileSdkVersion(34)
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
