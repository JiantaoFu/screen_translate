import 'package:flutter/material.dart';

class OCRResult {
  final String text;
  final double x;
  final double y;
  final double width;
  final double height;
  Color? overlayColor; // New property to store adaptive overlay color
  Color? backgroundColor; // Background color extracted from the image
  bool isLight; // Whether the background is considered light
  final double imgWidth;
  final double imgHeight;

  /// The ORIGINAL (pre-merge) glyph size — min(height, width) of the raw
  /// single-line OCR block this result came from, or the smaller of two
  /// inputs' values when merged. Deliberately NOT recomputed from the
  /// current (possibly already-merged) bounding box: once several lines
  /// merge into one tall multi-line block, min(height, width) on THAT box
  /// picks up the page width instead of a line height, inflating the
  /// merge-decision "font size" far past the real glyph size and causing
  /// a runaway cascade that swallows increasingly distant, unrelated
  /// paragraphs. Carrying the true original size forward keeps the merge
  /// threshold anchored to what a "line" actually looks like, no matter
  /// how many lines have already been folded into this block.
  final double fontSize;

  OCRResult({
    required this.text,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.overlayColor,
    this.backgroundColor,
    this.isLight = false,
    required this.imgWidth,
    required this.imgHeight,
    double? fontSize,
  }) : fontSize = fontSize ?? (height < width ? height : width);
}
