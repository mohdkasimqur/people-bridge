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
// Plugins built against an older Android API than the app (overlay_pop_up: 31) fail the AAR metadata check.
subprojects {
    if (name != "app") {
        afterEvaluate {
            val appSdk = rootProject.project(":app").extensions
                .findByType(com.android.build.api.dsl.ApplicationExtension::class.java)?.compileSdk
            val lib = extensions.findByType(com.android.build.api.dsl.LibraryExtension::class.java)
            if (appSdk != null && lib != null && (lib.compileSdk ?: 0) < appSdk) {
                lib.compileSdk = appSdk
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
