# flutter_local_notifications stores scheduled notification data with Gson.
# R8 must keep generic signatures for Gson TypeToken or release builds crash
# when cancelling/rescheduling local notifications.
-keepattributes Signature
-keepattributes *Annotation*

-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken { *; }

-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.styles.** { *; }
