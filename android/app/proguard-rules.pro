-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

-keep class com.stripe.android.pushProvisioning.** { *; }
-dontwarn com.stripe.android.pushProvisioning.**

-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# OkHttp
-dontwarn okhttp3.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# Okio
-dontwarn okio.**
-keep class okio.** { *; }
-keep interface okio.** { *; }

# UCrop
-dontwarn com.yalantis.ucrop.**
-keep class com.yalantis.ucrop.** { *; }
