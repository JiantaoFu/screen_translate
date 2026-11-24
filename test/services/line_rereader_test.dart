import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:screen_translate/services/line_rereader.dart';
import 'package:screen_translate/services/ocr_service.dart';

void main() {
  group('CyrillicLineRecognizer.ctcDecode', () {
    const dict = ['П', 'р', 'и', 'в', 'е', 'т', '!'];

    test('collapses repeats, drops blanks, maps the id after the dictionary to a space', () {
      // П П _ р и в в е т ␠ !   (ids: 1-based; 0 blank; 8 space)
      final ids = [1, 1, 0, 2, 3, 4, 4, 5, 6, 8, 7];
      expect(CyrillicLineRecognizer.ctcDecode(ids, dict), 'Привет !');
    });

    test('a blank between equal ids keeps both letters', () {
      expect(CyrillicLineRecognizer.ctcDecode([4, 0, 4], dict), 'вв');
    });

    test('ids outside the dictionary are ignored and spaces trimmed', () {
      expect(CyrillicLineRecognizer.ctcDecode([8, 1, 99, 8], dict), 'П');
    });
  });

  group('CyrillicLineRecognizer.cropLine', () {
    test('scales the line, with a margin, to 48 px high', () {
      final image = LumaImage(400, 200, Uint8List(400 * 200));
      final crop = CyrillicLineRecognizer.cropLine(image, const Rect.fromLTWH(100, 80, 200, 24));
      expect(crop.height, 48);
      // 212 x 32 after the margins (rows 76..108), scaled to 48 high.
      expect(crop.width, (212 * 48 / 32).round());
      expect(crop.luma.length, crop.width * 48);
    });

    test('keeps dark text dark and the background light', () {
      final w = 300, h = 100;
      final luma = Uint8List(w * h)..fillRange(0, w * h, 240);
      for (var y = 40; y < 60; y++) {
        for (var x = 100; x < 120; x++) {
          luma[y * w + x] = 10;
        }
      }
      final crop = CyrillicLineRecognizer.cropLine(
          LumaImage(w, h, luma), const Rect.fromLTWH(90, 40, 120, 20));
      final values = crop.luma.toList()..sort();
      expect(values.first, lessThan(40));
      expect(values.last, greaterThan(220));
    });

    test('a line at the image edge stays inside it', () {
      final image = LumaImage(50, 30, Uint8List(50 * 30));
      final crop = CyrillicLineRecognizer.cropLine(image, const Rect.fromLTWH(0, 0, 50, 30));
      expect(crop.height, 48);
    });
  });

  test('batchTensor normalizes to [-1, 1] in three channels and pads with 0', () {
    final a = LumaImage(2, 48, Uint8List(2 * 48)..fillRange(0, 96, 255));
    final t = CyrillicLineRecognizer.batchTensor([a], 3);
    const plane = 48 * 3;
    expect(t.length, 3 * plane);
    expect(t[0], closeTo(1.0, 1e-6));
    expect(t[plane], closeTo(1.0, 1e-6));
    expect(t[2 * plane + 1], closeTo(1.0, 1e-6));
    expect(t[2], 0.0); // column 2 is padding
  });

  test('OCRService.lumaOf weighs channels like Rec. 601', () {
    final image = img.Image(width: 2, height: 1);
    image.setPixelRgb(0, 0, 255, 255, 255);
    image.setPixelRgb(1, 0, 0, 255, 0);
    final luma = OCRService.lumaOf(image);
    expect(luma.luma, [255, 150]);
  });
}
