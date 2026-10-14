import 'package:flutter_test/flutter_test.dart';
import 'package:screen_translate/services/onnx_translation_service.dart';

void main() {
  test('every AI pack has a download size to show in Settings', () {
    for (final pair in kSupportedOnnxPairs) {
      expect(kOnnxPackDownloadMb[pair.key], isNotNull, reason: '${pair.key} has no size');
    }
    for (final pivot in kSupportedOnnxPivotPairs) {
      expect(kOnnxPackDownloadMb[pivot.firstHopKey], isNotNull, reason: pivot.firstHopKey);
      expect(kOnnxPackDownloadMb[pivot.secondHopKey], isNotNull, reason: pivot.secondHopKey);
    }
  });

  test('fp16 packs load with a lower ONNX optimization level', () {
    // ORT's default level fails to initialize the fp16 models.
    for (final pair in kSupportedOnnxPairs) {
      expect(OnnxTranslationService.graphOptimizationLevelFor(pair.key), pair.useFp16 ? 'extended' : isNull,
          reason: pair.key);
    }
    expect(OnnxTranslationService.graphOptimizationLevelFor('opus-mt-ko-en'), 'extended');
    expect(OnnxTranslationService.graphOptimizationLevelFor('opus-mt-ja-en'), isNull);
  });
}
