# Local patch

Vendored from pub.dev `flutter_onnxruntime` 1.8.3 (MIT, see LICENSE); `example/` and `doc/` removed.

Change: `OrtSessionOptions.graphOptimizationLevel` ('disable' | 'basic' | 'extended' | 'all'),
applied on Android in `FlutterOnnxruntimePlugin.kt`.

Why: ONNX Runtime 1.23 (onnxruntime-android) fails to initialize the fp16 opus-mt models
(ko-en, th-en, id-en from onnx-community) at the default ALL level:
"Attempting to get index by a name which does not exist: InsertedPrecisionFreeCast_...
SimplifiedLayerNormFusion". EXTENDED and lower load fine (reproduced with Python onnxruntime 1.23.0).
Drop this patch when upstream exposes the optimization level or ORT fixes the fusion.
