import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/ocr_result.dart';

class OCRService {
  final TextRecognizer textRecognizer = TextRecognizer();

  Future<List<OCRResult>> processImage(Map<String, dynamic> imageData) async {
    try {
      print('OCR: Starting image processing');
      
      final Uint8List imageBytes = imageData['bytes'];
      final int width = imageData['width'];
      final int height = imageData['height'];
      
      print('OCR: Image dimensions: ${width}x${height}');
      
      final InputImage image = InputImage.fromBytes(
        bytes: imageBytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: width,
        ),
      );

      print('OCR: Processing image with ML Kit');
      final RecognizedText recognizedText = await textRecognizer.processImage(image);
      
      final List<OCRResult> results = [];
      
      for (final TextBlock block in recognizedText.blocks) {
        final Rect boundingBox = block.boundingBox;
        print('OCR: Text block recognized at position: $boundingBox');
        
        results.add(OCRResult(
          text: block.text,
          x: boundingBox.left,
          y: boundingBox.top,
          width: boundingBox.width,
          height: boundingBox.height,
        ));
      }
      
      print('OCR: Found ${results.length} text blocks');
      return results;
    } catch (e) {
      print('OCR Error: $e');
      return [];
    }
  }

  void dispose() {
    textRecognizer.close();
  }
}
