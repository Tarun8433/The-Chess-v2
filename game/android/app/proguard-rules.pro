###############################
# Flutter & Firebase keep rules
###############################

# Keep Flutter classes used via reflection
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Firebase SDK classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep generated registrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Keep Kotlin coroutines (if used by plugins)
-keep class kotlinx.coroutines.** { *; }

# Do not warn about missing checks for kotlin metadata
-dontwarn kotlin.**

# Flutter deferred components reference Play Core; suppress warnings when not using it
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Optimize but allow access modifiers changes
-optimizations !class/merging/*,!field/*

# Keep application class (if any)
-keep class **.MainActivity { *; }

# Entry points
-keep class **Application { *; }

# Model classes often used by gson/kotlinx serialization
-keepclassmembers class ** { @com.google.gson.annotations.SerializedName *; }