
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
-keep class com.example.tunanetra_apk.** { *; }

-keep class com.lyokone.flutter_contacts.** { *; }
-keep class com.baseflow.geolocator.** { *; }
-keep class com.baseflow.permission_handler.** { *; }
-keep class com.github.dhaval2404.imagepicker.** { *; }
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.example.usb_serial.** { *; }
-keep class com.example.syncfusion_flutter_pdf.** { *; }


-keepclasseswithmembers class * {
    native <methods>;
}


-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses


-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory { *; }
-keep class * implements com.google.gson.JsonSerializer { *; }
-keep class * implements com.google.gson.JsonDeserializer { *; }