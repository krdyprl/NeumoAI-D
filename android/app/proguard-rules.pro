# tflite_flutter / TensorFlow Lite keep rules
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.nnapi.** { *; }

# Suppress warnings for optional TFLite GPU delegate classes absent from the
# tflite_flutter artifact.
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory

# Keep all model-related native bindings
-keep class com.neumoiaid.neumoi_d.** { *; }

# Generic: keep names needed by reflection
-keepattributes Signature
-keepattributes InnerClasses
