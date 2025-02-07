import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:logging/logging.dart';
import '../models/ocr_result.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import '../utils/color_utils.dart';

extension ColorAdaptation on Color {
  // Determine if a color is considered "light"
  bool isLight() {
    // Consider a color dark if its luminance is below 0.3
    return computeLuminance() >= 0.3;
  }

  // Create a contrasting color for text overlay
  Color getContrastColor() {
    return isLight() ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.7);
  }

  String toLoggableString() {
    return '#${red.toRadixString(16).padLeft(2, '0')}${green.toRadixString(16).padLeft(2, '0')}${blue.toRadixString(16).padLeft(2, '0')}';
  }
}

class OCRService {
  TextRecognizer? _textRecognizer;
  TextRecognitionScript? _currentScript;
  final Logger _logger = Logger('OCRService');

  static const double overlapThreshold = 0.1;
  static const double PADDING = 5.0;

  TextRecognitionScript getScriptForLanguage(String languageCode) {
    switch (languageCode) {
      case 'zh':
        return TextRecognitionScript.chinese;
      case 'hi':
      case 'mr':
        return TextRecognitionScript.devanagiri;
      case 'ja':
        return TextRecognitionScript.japanese;
      case 'ko':
        return TextRecognitionScript.korean;
      default:
        return TextRecognitionScript.latin;
    }
  }

  TextRecognizer getTextRecognizer(TextRecognitionScript script) {
    // Reuse existing recognizer if script matches
    if (_textRecognizer != null && _currentScript == script) {
      return _textRecognizer!;
    }

    // Close and create new if different
    _textRecognizer?.close();
    _currentScript = script;
    _textRecognizer = TextRecognizer(script: script);
    return _textRecognizer!;
  }

  Future<List<OCRResult>> processImage(Map<String, dynamic> imageData, TextRecognitionScript script) async {
    try {
      _logger.info('Starting image processing');
      
      final Uint8List imageBytes = imageData['bytes'];
      final int width = imageData['width'];
      final int height = imageData['height'];
      
      _logger.info('Image dimensions: ${width}x${height}');
      
      final InputImage image = InputImage.fromBytes(
        bytes: imageBytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: width,
        ),
      );

      _logger.info('OCR: Processing image with ML Kit');
      final textRecognizer = getTextRecognizer(script);
      final RecognizedText recognizedText = await textRecognizer.processImage(image);
      
      // Extract dominant background color
      final Color backgroundColor = ColorUtils.extractDominantColorFromNV21(imageBytes, width, height);
      final Color overlayColor = backgroundColor.getContrastColor();
      
      final List<OCRResult> results = [];
      
      // Sort blocks by size (largest first) to prioritize main text blocks
      final List<TextBlock> sortedBlocks = recognizedText.blocks.toList()
        ..sort((a, b) => (b.boundingBox.width * b.boundingBox.height)
            .compareTo(a.boundingBox.width * a.boundingBox.height));
      
      // Track processed areas to avoid overlaps
      final List<Rect> processedAreas = [];
      
      for (final TextBlock block in sortedBlocks) {
        final Rect boundingBox = block.boundingBox;
        
        // Check for significant overlap with already processed areas
        bool hasSignificantOverlap = false;
        Rect adjustedBox = boundingBox;
        
        for (final Rect processed in processedAreas) {
          if (_calculateOverlap(adjustedBox, processed) > OCRService.overlapThreshold) {
            // If significant overlap, adjust position
            adjustedBox = _adjustPosition(adjustedBox, processed);
            hasSignificantOverlap = true;
          }
        }
        
        // Only add if text is not empty and box is valid
        if (block.text.trim().isNotEmpty && 
            adjustedBox.width > 0 && 
            adjustedBox.height > 0) {
          _logger.info('Text block recognized at position: $adjustedBox, text: ${block.text}, bounding box: ${block.boundingBox.width}x${block.boundingBox.height}');
          results.add(OCRResult(
            text: block.text,
            x: adjustedBox.left,
            y: adjustedBox.top,
            width: adjustedBox.width,
            height: adjustedBox.height,
            overlayColor: overlayColor,
            backgroundColor: backgroundColor,
            isLight: backgroundColor.isLight(),
          ));
          processedAreas.add(adjustedBox);
        }
      }
      
      _logger.info('OCR: Found ${results.length} text blocks');

      // Log final results
      _logger.info('Background Color: ${backgroundColor.toLoggableString()}');
      _logger.info('OCR: Found ${results.length} text blocks with overlay color ${overlayColor.toLoggableString()}');

      return results;
    } catch (e) {
      _logger.severe('OCR Error: $e');
      return [];
    }
  }

  // Calculate overlap percentage between two rectangles
  double _calculateOverlap(Rect a, Rect b) {
    final intersect = a.intersect(b);
    if (intersect.isEmpty) return 0.0;
    
    final overlapArea = intersect.width * intersect.height;
    final minArea = min(a.width * a.height, b.width * b.height);
    
    return overlapArea / minArea;
  }

  // Adjust position of a rectangle to avoid overlap
  Rect _adjustPosition(Rect newBox, Rect existing) {
    // If boxes overlap vertically, adjust y position
    if (newBox.left < existing.right && newBox.right > existing.left) {
      if (newBox.top < existing.top) {
        // Place above if there's room
        return Rect.fromLTWH(
          newBox.left,
          max(0, existing.top - newBox.height - PADDING),
          newBox.width,
          newBox.height,
        );
      } else {
        // Place below
        return Rect.fromLTWH(
          newBox.left,
          existing.bottom + 5,
          newBox.width,
          newBox.height,
        );
      }
    }
    // If boxes overlap horizontally, adjust x position
    else if (newBox.top < existing.bottom && newBox.bottom > existing.top) {
      if (newBox.left < existing.left) {
        // Place to the left if there's room
        return Rect.fromLTWH(
          max(0, existing.left - newBox.width - PADDING),
          newBox.top,
          newBox.width,
          newBox.height,
        );
      } else {
        // Place to the right
        return Rect.fromLTWH(
          existing.right + 5,
          newBox.top,
          newBox.width,
          newBox.height,
        );
      }
    }
    return newBox;
  }

  void dispose() {
    _textRecognizer?.close();
    _textRecognizer = null;
  }
}
