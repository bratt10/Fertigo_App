allprojects {
    repositories {
        google()
        mavenCentral()

        // Repositorio nuevo de Flutter (obligatorio para evitar errores de descarga)
        maven { url = uri("https://flutter-storage.googleapis.com") }

        // Repositorio viejo de Flutter (backup)
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }

        // Extras para evitar fallos con dependencias
        maven { url = uri("https://jitpack.io") }
        maven { url = uri("https://maven.google.com") }
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
