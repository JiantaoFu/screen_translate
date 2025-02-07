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

  OCRResult({
    required this.text,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.overlayColor,
    this.backgroundColor,
    this.isLight = false,
  });

  // Optional: Add a toJson method if you're serializing these results
  Map<String, dynamic> toJson() => {
    'text': text,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'overlayColor': overlayColor?.value,
    'backgroundColor': backgroundColor?.value,
    'isLight': isLight,
  };

  // Optional: Add a fromJson constructor if you're deserializing
  factory OCRResult.fromJson(Map<String, dynamic> json) => OCRResult(
    text: json['text'],
    x: json['x'],
    y: json['y'],
    width: json['width'],
    height: json['height'],
    overlayColor: json['overlayColor'] != null ? Color(json['overlayColor']) : null,
    backgroundColor: json['backgroundColor'] != null ? Color(json['backgroundColor']) : null,
    isLight: json['isLight'] ?? false,
  );
}
