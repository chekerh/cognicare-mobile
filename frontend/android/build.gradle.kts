// So that record_android (and other plugins) can resolve flutter.* in CI/local when Flutter extension is not set
rootProject.extra["flutter"] = mapOf(
    "compileSdkVersion" to 35,
    "minSdkVersion" to 23,
    "targetSdkVersion" to 35,
)

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
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
