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
}
