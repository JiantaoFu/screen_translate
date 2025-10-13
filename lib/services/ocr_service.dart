import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:logging/logging.dart';
import '../models/ocr_result.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import '../utils/color_utils.dart';
import 'dart:async';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

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

  Future<List<OCRResult>> processImage(
    Map<String, dynamic> imageData,
    TextRecognitionScript script,
    {bool drawDebugBoxes = false, int minTextLength = 1}
  ) async {
    try {
      _logger.info('Starting image processing');

      final Uint8List imageBytes = imageData['bytes'];
      final int width = imageData['width'];
      final int height = imageData['height'];

      // Debug: log image vs screen sizes and devicePixelRatio
      final window = WidgetsBinding.instance.window;
      final physicalScreenW = window.physicalSize.width.toInt();
      final physicalScreenH = window.physicalSize.height.toInt();
      final devicePixelRatio = window.devicePixelRatio;
      _logger.info('Image size: ${width}x${height}');
      _logger.info('Screen physical size: ${physicalScreenW}x${physicalScreenH}, devicePixelRatio=$devicePixelRatio');

      // Get system paddings (status bar / navbar) in physical pixels
      final paddingTop = window.viewPadding.top;
      final paddingBottom = window.viewPadding.bottom;
      _logger.info('Window viewPadding: top=${paddingTop}, bottom=${paddingBottom}');
      // Content area height (where the app content is laid out)
      final contentHeight = physicalScreenH - paddingTop.toInt() - paddingBottom.toInt();
      _logger.info('Content area height: $contentHeight');

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
      // final List<TextBlock> sortedBlocks = recognizedText.blocks.toList()
      //   ..sort((a, b) => (b.boundingBox.width * b.boundingBox.height)
      //       .compareTo(a.boundingBox.width * a.boundingBox.height));

      // Track processed areas to avoid overlaps
      // final List<Rect> processedAreas = [];

      for (final TextBlock block in recognizedText.blocks) {
        final Rect boundingBox = block.boundingBox;

        // Only add if text is not empty, meets minimum length, and box is valid
        if (block.text.trim().isNotEmpty &&
            block.text.trim().length >= minTextLength &&
            boundingBox.width > 0 &&
            boundingBox.height > 0) {
          _logger.info('Text block recognized {${block.text}}, sending mapped screen coords {x:${boundingBox.left}, y:${boundingBox.top}, w:${boundingBox.width}, h:${boundingBox.height}}');
          results.add(OCRResult(
            text: block.text,
            // Pass original bounding box coordinates relative to the image
            x: boundingBox.left,
            y: boundingBox.top,
            width: boundingBox.width,
            height: boundingBox.height,
            overlayColor: overlayColor,
            backgroundColor: backgroundColor,
            isLight: backgroundColor.isLight(),
            // keep original image dims for reference if needed
            imgWidth: width.toDouble(),
            imgHeight: height.toDouble(),
          ));
          // processedAreas.add(adjustedBox);
        }
      }

      _logger.info('OCR: Found ${results.length} text blocks');

      // Log final results
      _logger.info('Background Color: ${backgroundColor.toLoggableString()}');
      _logger.info('OCR: Found ${results.length} text blocks with overlay color ${overlayColor.toLoggableString()}');

      // Optional: Draw and save bounding boxes for debugging
      if (drawDebugBoxes) {
        final debugImagePath = await drawAndSaveBoundingBoxes(
          imageBytes,
          width,
          height,
          recognizedText.blocks
        );

        if (debugImagePath != null) {
          _logger.info('Debug bounding boxes image saved at: $debugImagePath');
        }
      }

      return results;
    } catch (e) {
      _logger.severe('OCR Error: $e');
      return [];
    }
  }

  // Utility method to convert NV21 to RGB using image package
  Uint8List convertNV21toRGB(
    Uint8List nv21Bytes,
    int width,
    int height
  ) {
    try {
      _logger.info('Converting NV21 to RGB: $width x $height');
      _logger.info('Input NV21 bytes length: ${nv21Bytes.length}');

      // Validate input - match Kotlin's size calculation
      final expectedNV21Size = width * height + 2 * ((height + 1) ~/ 2) * ((width + 1) ~/ 2);
      if (nv21Bytes.length != expectedNV21Size) {
        _logger.severe('Invalid NV21 byte array size. '
          'Expected $expectedNV21Size, got ${nv21Bytes.length}');
        return Uint8List(0);
      }

      // Create an image from raw bytes
      final image = img.Image(width: width, height: height);

      // Manual NV21 to RGB conversion
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          // Y component index
          final yIndex = y * width + x;

          // UV component indices
          final uvIndex = width * height + (y >> 1) * width + (x & ~1);

          // Safely access Y, U, V components
          final yComponent = nv21Bytes[yIndex] & 0xFF;
          final uComponent = nv21Bytes[uvIndex] & 0xFF;
          final vComponent = nv21Bytes[uvIndex + 1] & 0xFF;

          // YUV to RGB conversion
          final c = yComponent - 16;
          final d = uComponent - 128;
          final e = vComponent - 128;

          final r = (298 * c + 409 * e + 128) >> 8;
          final g = (298 * c - 100 * d - 208 * e + 128) >> 8;
          final b = (298 * c + 516 * d + 128) >> 8;

          // Clamp and set pixel
          final rClamped = r.clamp(0, 255);
          final gClamped = g.clamp(0, 255);
          final bClamped = b.clamp(0, 255);

          image.setPixelRgb(x, y, rClamped, gClamped, bClamped);
        }
      }

      // Convert to PNG bytes
      final pngBytes = img.encodePng(image);

      _logger.info('Converted PNG bytes length: ${pngBytes.length}');
      return Uint8List.fromList(pngBytes);
    } catch (e, stackTrace) {
      _logger.severe('Error converting NV21 to RGB', e, stackTrace);
      return Uint8List(0);
    }
  }

  Future<ui.Image?> drawBoundingBoxes(
    Uint8List imageBytes,
    int width,
    int height,
    List<TextBlock> blocks
  ) async {
    try {
      _logger.info('Drawing bounding boxes: Image bytes length ${imageBytes.length}');

      // Validate image bytes
      if (imageBytes.isEmpty) {
        _logger.severe('Empty image bytes array');
        return null;
      }

      // Decode the original image
      final originalImage = await decodeImageFromList(imageBytes);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw the original image, scaled to fit
      canvas.drawImage(originalImage, Offset.zero, Paint());

      // Draw bounding boxes
      final boxPaint = Paint()
        ..color = Colors.red.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      final textPaintFill = Paint()
        ..color = Colors.black.withOpacity(0.7);

      for (final block in blocks) {
        final rect = block.boundingBox;

        // Draw bounding box
        canvas.drawRect(
          Rect.fromLTWH(
            rect.left,
            rect.top,
            rect.width,
            rect.height
          ),
          boxPaint
        );

        // Draw text background
        final textRect = Rect.fromLTWH(
          rect.left,
          rect.top - 20,
          rect.width,
          20
        );
        canvas.drawRect(textRect, textPaintFill);

        // Draw text
        final textPainter = TextPainter(
          text: TextSpan(
            text: block.text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            )
          ),
          textDirection: TextDirection.ltr
        )..layout(maxWidth: rect.width);

        textPainter.paint(
          canvas,
          Offset(rect.left, rect.top - 20)
        );
      }

      // Finish recording and convert to image
      final picture = recorder.endRecording();
      return picture.toImage(width, height);
    } catch (e, stackTrace) {
      _logger.severe('Error drawing bounding boxes', e, stackTrace);
      return null;
    }
  }

  Future<String?> drawAndSaveBoundingBoxes(
    Uint8List imageBytes,
    int width,
    int height,
    List<TextBlock> blocks
  ) async {
    try {
      // Convert NV21 to RGB/PNG
      final convertedBytes = convertNV21toRGB(imageBytes, width, height);

      if (convertedBytes.isEmpty) {
        _logger.severe('Failed to convert NV21 to RGB');
        return null;
      }

      final debugImage = await drawBoundingBoxes(convertedBytes, width, height, blocks);

      if (debugImage == null) {
        _logger.severe('Failed to create debug image');
        return null;
      }

      // Convert ui.Image to ByteData with PNG format
      final byteData = await debugImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        _logger.severe('Failed to convert debug image to ByteData');
        return null;
      }

      // Validate byte data
      final uint8List = byteData.buffer.asUint8List();
      if (uint8List.isEmpty) {
        _logger.severe('Generated image byte data is empty');
        return null;
      }

      // Get external files directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        _logger.severe('Failed to get external storage directory');
        return null;
      }

      // Create previews subdirectory
      final previewsDir = Directory('${directory.path}/previews');
      if (!previewsDir.existsSync()) {
        previewsDir.createSync(recursive: true);
      }

      // Generate a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'ocr_debug_${timestamp}.png';
      final file = File('${previewsDir.path}/$filename');

      // Write image bytes to file
      await file.writeAsBytes(uint8List);

      final filePath = file.path;
      _logger.info('Debug bounding boxes image saved: $filePath');
      return filePath;
    } catch (e, stackTrace) {
      _logger.severe('Error saving debug bounding boxes', e, stackTrace);
      return null;
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
