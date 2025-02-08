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
  });
}
