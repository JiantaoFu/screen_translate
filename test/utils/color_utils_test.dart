import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_translate/utils/color_utils.dart';

/// A 1080x2400 grey (dark manga art) NV21 frame with a white speech bubble
/// holding two vertical text columns of near-solid ink — the layout ML Kit
/// returns as one block per column on a vertical manga bubble.
const _w = 1080, _h = 2400;
const _bubble = Rect.fromLTRB(140, 1500, 320, 2000);
const _colRight = Rect.fromLTRB(230, 1578, 277, 1893);
const _colLeft = Rect.fromLTRB(164, 1571, 217, 1940);

Uint8List _frame() {
  final bytes = Uint8List(_w * _h * 3 ~/ 2);
  for (int y = 0; y < _h; y++) {
    for (int x = 0; x < _w; x++) {
      final p = Offset(x.toDouble(), y.toDouble());
      int luma = 70; // art around the bubble
      if (_bubble.contains(p)) luma = 255;
      // glyph ink: dense stripes inside each column
      if ((_colRight.contains(p) || _colLeft.contains(p)) && (y ~/ 6).isEven) {
        luma = 10;
      }
      bytes[y * _w + x] = luma;
    }
  }
  bytes.fillRange(_w * _h, bytes.length, 128); // neutral chroma
  return bytes;
}

double _distance(Color a, Color b) {
  final dr = a.red - b.red, dg = a.green - b.green, db = a.blue - b.blue;
  return (dr * dr + dg * dg + db * db).toDouble();
}

void main() {
  test('vertical columns in one bubble get the bubble colour, not ink or art', () {
    final bytes = _frame();
    Color surround(Rect r) => ColorUtils.extractSurroundColorFromNV21(
        bytes, _w, _h, r, r.shortestSide * 0.3);

    final right = surround(_colRight);
    final left = surround(_colLeft);
    expect(right.red, greaterThan(240));
    expect(left.red, greaterThan(240));
    // OCRService merges blocks whose colours are within 35 (RGB distance).
    expect(_distance(right, left), lessThan(35 * 35));
  });

  test('text on different backgrounds stays distinguishable', () {
    final bytes = _frame();
    // A line of text on the dark art, outside the bubble.
    const onArt = Rect.fromLTRB(500, 600, 900, 640);
    final art = ColorUtils.extractSurroundColorFromNV21(
        bytes, _w, _h, onArt, onArt.shortestSide * 0.3);
    final bubble = ColorUtils.extractSurroundColorFromNV21(
        bytes, _w, _h, _colRight, _colRight.shortestSide * 0.3);
    expect(art.red, lessThan(100));
    expect(_distance(art, bubble), greaterThan(35 * 35));
  });
}
