# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in C:\Users\marri\AppData\Local\Android\sdk\tools\proguard\proguard-android.txt
# You can edit the include path and order by changing the proguardFiles
# directive in build.gradle.

# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Flutter shrinking rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
# Additional rules for Firebase and Play Core
-dontwarn com.google.android.play.core.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**

# Firebase ProGuard rules (usually handled by dependency, but safe to keep)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
