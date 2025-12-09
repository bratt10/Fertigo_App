# Mantener clases esenciales de Flutter
-keep class io.flutter.** { *; }

# Clases necesarias de Play Core para deferred components
-keep class com.google.android.play.core.** { *; }

# Evitar que R8 elimine clases internas del split install
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Evitar eliminar listeners, managers y builders
-keep class * implements com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener { *; }

# Evitar warnings molestos
-dontwarn com.google.android.play.core.**
