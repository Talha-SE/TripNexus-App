# Proguard Rules for Tourism App
# Keep Flutter Engine
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# Keep MongoDB classes
-keep class org.bson.** { *; }
-keep class com.mongodb.** { *; }
-dontwarn org.bson.**
-dontwarn com.mongodb.**

# Keep Web3 classes
-keep class org.web3j.** { *; }
-dontwarn org.web3j.**

# Keep Google Fonts
-keep class com.google.fonts.** { *; }

# Keep Image Picker
-keep class androidx.core.content.FileProvider { *; }

# Keep Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Keep URL Launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Keep notification classes
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Preserve line numbers for debugging stack traces
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
