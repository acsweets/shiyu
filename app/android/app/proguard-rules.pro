# JNA 在运行时按名称查找 JNI 成员及 UniFFI 结构体字段。
-keep class com.sun.jna.** { *; }
-keep class com.growthrecord.shiyu.core.** extends com.sun.jna.Structure { *; }
-keep class com.growthrecord.shiyu.core.** implements com.sun.jna.Callback { *; }
-keepattributes RuntimeVisibleAnnotations
-dontwarn java.awt.**
