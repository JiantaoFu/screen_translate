import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:screen_translate/models/ocr_result.dart';
import 'package:screen_translate/services/ocr_service.dart';

OCRResult _block(String text, double x, double y, double w, double h) => OCRResult(
      text: text, x: x, y: y, width: w, height: h,
      backgroundColor: Colors.white, imgWidth: 1080, imgHeight: 2400,
    );

void main() {
  // ML Kit's blocks for one vertical speech bubble (manga-1 demo page, as
  // seen on a 1080x2400 emulator): one block per column.
  final columns = [
    _block('たすけて!あの', 935, 246, 56, 386),
    _block('ロボットが街を', 862, 256, 51, 382),
    _block('壊している!', 776, 273, 66, 338),
  ];

  for (final order in [
    [0, 1, 2], [2, 1, 0], [1, 0, 2], [2, 0, 1], [0, 2, 1], [1, 2, 0],
  ]) {
    test('vertical columns merge right-to-left (input order $order)', () {
      final merged = OCRService().mergeNearbyBlocksForTest(
        [for (final i in order) columns[i]], TextRecognitionScript.japanese);
      expect(merged, hasLength(1));
      expect(merged.single.text.split('\n'),
          ['たすけて!あの', 'ロボットが街を', '壊している!']);
    });
  }

  group('readingOrderText', () {
    // One ML Kit block for the whole bubble, lines in left-to-right order.
    const lines = [
      ('壊している!', Rect.fromLTWH(776, 273, 66, 338)),
      ('ロボットが街を', Rect.fromLTWH(862, 256, 51, 382)),
      ('たすけて!あの', Rect.fromLTWH(935, 246, 56, 386)),
    ];

    test('vertical Japanese and Chinese columns read right to left', () {
      for (final script in [TextRecognitionScript.japanese, TextRecognitionScript.chinese]) {
        expect(OCRService.readingOrderText(lines, script).split('\n'),
            ['たすけて!あの', 'ロボットが街を', '壊している!']);
      }
    });

    test('horizontal lines and non-CJK scripts keep ML Kit order', () {
      const horizontal = [
        ('勇者よ、城の北の塔に魔王が待っている。', Rect.fromLTWH(110, 930, 1150, 60)),
        ('気をつけて進むのじゃ。', Rect.fromLTWH(110, 1030, 640, 60)),
      ];
      expect(OCRService.readingOrderText(horizontal, TextRecognitionScript.japanese).split('\n'),
          ['勇者よ、城の北の塔に魔王が待っている。', '気をつけて進むのじゃ。']);
      expect(OCRService.readingOrderText(lines, TextRecognitionScript.latin).split('\n'),
          ['壊している!', 'ロボットが街を', 'たすけて!あの']);
    });
  });
}
