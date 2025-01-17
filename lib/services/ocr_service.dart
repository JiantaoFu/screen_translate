import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final TextRecognizer textRecognizer = TextRecognizer();

  Future<String> processImage(Map<String, dynamic> imageData) async {
    try {
      print('OCR: Starting image processing');
      
      final Uint8List imageBytes = imageData['bytes'];
      final int width = imageData['width'];
      final int height = imageData['height'];
      
      print('OCR: Image dimensions: ${width}x${height}');
      
      // Create InputImage directly from bytes
      final InputImage image = InputImage.fromBytes(
        bytes: imageBytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: width * 4, // 4 bytes per pixel for BGRA
        ),
      );

      print('OCR: Processing image with ML Kit');
      final RecognizedText recognizedText = await textRecognizer.processImage(image);
      
      if (recognizedText.text.isNotEmpty) {
        print('OCR: Text recognized: ${recognizedText.text}');
      } else {
        print('OCR: No text recognized');
      }
      
      return recognizedText.text;
    } catch (e) {
      print('OCR Error: $e');
      return '';
    }
  }

  void dispose() {
    textRecognizer.close();
  }
}
