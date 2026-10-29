import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:screen_translate/models/ocr_result.dart';
import 'package:screen_translate/utils/overlay_layout.dart';

OCRResult box(double x, double y, double w, double h, {double? fontSize}) =>
    OCRResult(
        text: 'label',
        x: x,
        y: y,
        width: w,
        height: h,
        imgWidth: 912,
        imgHeight: 2048,
        fontSize: fontSize);

void main() {
  test('adjacent map labels keep their source positions and do not overlap',
      () {
    final sources = [
      box(100, 100, 100, 40),
      box(204, 100, 100, 40),
      box(308, 144, 100, 40)
    ];
    final boxes = computeOverlayBoxes(sources);
    for (var i = 0; i < boxes.length; i++) {
      expect(boxes[i].contains(Offset(sources[i].x, sources[i].y)), isTrue);
      for (var j = i + 1; j < boxes.length; j++) {
        expect(boxes[i].overlaps(boxes[j]), isFalse);
      }
    }
  });

  test('paragraph padding uses glyph height rather than paragraph height', () {
    final result =
        computeOverlayBoxes([box(100, 100, 250, 400, fontSize: 20)]).single;
    expect(result, const Rect.fromLTWH(97, 97, 256, 406));
  });

  test('padding stays inside image edges', () {
    final result = computeOverlayBoxes([box(0, 2010, 912, 38)]).single;
    expect(result.left, 0);
    expect(result.right, 912);
    expect(result.bottom, 2048);
  });
}
