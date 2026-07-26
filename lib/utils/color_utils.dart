import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ColorUtils {
  /// Extract dominant color from NV21 formatted byte array using weighted average
  static Color extractDominantColorFromNV21(Uint8List bytes, int width, int height) {
    try {
      // Check if the byte array is large enough for NV21 format
      if (bytes.length < width * height * 1.5) {
        print('Image bytes too small for color extraction');
        return Colors.white; // Default to white to ensure dark overlay
      }

      // Strategic sampling points with weights
      final samplePoints = [
        // Top row (9 points)
        Point(width ~/ 16, height ~/ 16),       // Top-left corner (weight: 1.0)
        Point(width ~/ 8, height ~/ 16),         // Top-left first third (weight: 1.1)
        Point(width ~/ 4, height ~/ 16),         // Top-left middle (weight: 1.2)
        Point(3 * width ~/ 8, height ~/ 16),     // Top-left two-thirds (weight: 1.1)
        Point(width ~/ 2, height ~/ 16),         // Top middle (weight: 1.3)
        Point(5 * width ~/ 8, height ~/ 16),     // Top-right two-thirds (weight: 1.1)
        Point(3 * width ~/ 4, height ~/ 16),     // Top-right middle (weight: 1.2)
        Point(7 * width ~/ 8, height ~/ 16),     // Top-right first third (weight: 1.1)
        Point(15 * width ~/ 16, height ~/ 16),   // Top-right corner (weight: 1.0)

        // Upper-middle row (9 points)
        Point(width ~/ 16, height ~/ 4),         // Left upper-middle first third (weight: 1.1)
        Point(width ~/ 8, height ~/ 4),          // Left upper-middle middle (weight: 1.2)
        Point(width ~/ 4, height ~/ 4),          // Left upper-middle two-thirds (weight: 1.1)
        Point(3 * width ~/ 8, height ~/ 4),      // Center-left upper-middle (weight: 1.3)
        Point(width ~/ 2, height ~/ 4),          // Center upper-middle (weight: 1.4)
        Point(5 * width ~/ 8, height ~/ 4),      // Center-right upper-middle (weight: 1.3)
        Point(3 * width ~/ 4, height ~/ 4),      // Right upper-middle two-thirds (weight: 1.1)
        Point(7 * width ~/ 8, height ~/ 4),      // Right upper-middle middle (weight: 1.2)
        Point(15 * width ~/ 16, height ~/ 4),    // Right upper-middle first third (weight: 1.1)

        // Middle row (9 points)
        Point(width ~/ 16, height ~/ 2),         // Left middle first third (weight: 1.2)
        Point(width ~/ 8, height ~/ 2),          // Left middle middle (weight: 1.3)
        Point(width ~/ 4, height ~/ 2),          // Left middle two-thirds (weight: 1.2)
        Point(3 * width ~/ 8, height ~/ 2),      // Center-left middle (weight: 1.4)
        Point(width ~/ 2, height ~/ 2),          // Exact center (weight: 1.5)
        Point(5 * width ~/ 8, height ~/ 2),      // Center-right middle (weight: 1.4)
        Point(3 * width ~/ 4, height ~/ 2),      // Right middle two-thirds (weight: 1.2)
        Point(7 * width ~/ 8, height ~/ 2),      // Right middle middle (weight: 1.3)
        Point(15 * width ~/ 16, height ~/ 2),    // Right middle first third (weight: 1.2)

        // Lower-middle row (9 points)
        Point(width ~/ 16, 3 * height ~/ 4),     // Left lower-middle first third (weight: 1.1)
        Point(width ~/ 8, 3 * height ~/ 4),      // Left lower-middle middle (weight: 1.2)
        Point(width ~/ 4, 3 * height ~/ 4),      // Left lower-middle two-thirds (weight: 1.1)
        Point(3 * width ~/ 8, 3 * height ~/ 4),  // Center-left lower-middle (weight: 1.3)
        Point(width ~/ 2, 3 * height ~/ 4),      // Center lower-middle (weight: 1.4)
        Point(5 * width ~/ 8, 3 * height ~/ 4),  // Center-right lower-middle (weight: 1.3)
        Point(3 * width ~/ 4, 3 * height ~/ 4),  // Right lower-middle two-thirds (weight: 1.1)
        Point(7 * width ~/ 8, 3 * height ~/ 4),  // Right lower-middle middle (weight: 1.2)
        Point(15 * width ~/ 16, 3 * height ~/ 4),// Right lower-middle first third (weight: 1.1)

        // Bottom row (9 points)
        Point(width ~/ 16, 15 * height ~/ 16),   // Bottom-left corner (weight: 1.0)
        Point(width ~/ 8, 15 * height ~/ 16),    // Bottom-left first third (weight: 1.1)
        Point(width ~/ 4, 15 * height ~/ 16),    // Bottom-left middle (weight: 1.2)
        Point(3 * width ~/ 8, 15 * height ~/ 16),// Bottom-left two-thirds (weight: 1.1)
        Point(width ~/ 2, 15 * height ~/ 16),    // Bottom middle (weight: 1.3)
        Point(5 * width ~/ 8, 15 * height ~/ 16),// Bottom-right two-thirds (weight: 1.1)
        Point(3 * width ~/ 4, 15 * height ~/ 16),// Bottom-right middle (weight: 1.2)
        Point(7 * width ~/ 8, 15 * height ~/ 16),// Bottom-right first third (weight: 1.1)
        Point(15 * width ~/ 16, 15 * height ~/ 16)// Bottom-right corner (weight: 1.0)
      ];

      // Weighted color sampling
      final weightedColors = samplePoints.asMap().map((index, point) {
        final color = _getColorFromBytesNV21(bytes, width, height, point.x, point.y);
        final weight = _getWeightForIndex(index);
        return MapEntry(index, {'color': color, 'weight': weight});
      });

      // Calculate weighted average for each color channel
      final totalWeight = weightedColors.values.map((e) => e['weight'] as double).reduce((a, b) => a + b);
      
      final avgRed = weightedColors.values.map((e) {
        return ((e['color'] as Color).red.toDouble() * (e['weight'] as double));
      }).reduce((a, b) => a + b) / totalWeight;

      final avgGreen = weightedColors.values.map((e) {
        return ((e['color'] as Color).green.toDouble() * (e['weight'] as double));
      }).reduce((a, b) => a + b) / totalWeight;

      final avgBlue = weightedColors.values.map((e) {
        return ((e['color'] as Color).blue.toDouble() * (e['weight'] as double));
      }).reduce((a, b) => a + b) / totalWeight;

      // Create dominant color
      final dominantColor = Color.fromRGBO(
        avgRed.toInt().clamp(0, 255), 
        avgGreen.toInt().clamp(0, 255), 
        avgBlue.toInt().clamp(0, 255), 
        1.0
      );

      print('Weighted Dominant Color: #${dominantColor.value.toRadixString(16)}');

      return dominantColor;
    } catch (e) {
      print('NV21 color extraction error: $e');
      return Colors.white;
    }
  }

  /// Extract an average color from a specific region of an NV21 byte array
  /// (image coordinates, not screen coordinates). Used to give each OCR
  /// overlay box a background color sampled from what's actually behind
  /// *that* piece of text, instead of one dominant color for the whole
  /// screen plastered onto every box — on a busy screen (many widgets/app
  /// icons with different local backgrounds) a single global color clashes
  /// with most of them.
  static Color extractRegionColorFromNV21(
    Uint8List bytes,
    int imgWidth,
    int imgHeight,
    double regionX,
    double regionY,
    double regionWidth,
    double regionHeight,
  ) {
    try {
      if (bytes.length < imgWidth * imgHeight * 1.5 || regionWidth <= 0 || regionHeight <= 0) {
        return Colors.white;
      }

      final left = regionX.toInt().clamp(0, imgWidth - 1);
      final top = regionY.toInt().clamp(0, imgHeight - 1);
      final right = (regionX + regionWidth).toInt().clamp(left + 1, imgWidth);
      final bottom = (regionY + regionHeight).toInt().clamp(top + 1, imgHeight);

      const gridSize = 3;
      int totalR = 0, totalG = 0, totalB = 0, count = 0;
      for (int i = 0; i < gridSize; i++) {
        for (int j = 0; j < gridSize; j++) {
          final sx = left + ((right - left) * (i + 0.5) / gridSize).toInt();
          final sy = top + ((bottom - top) * (j + 0.5) / gridSize).toInt();
          final color = _getColorFromBytesNV21(bytes, imgWidth, imgHeight, sx, sy);
          totalR += color.red;
          totalG += color.green;
          totalB += color.blue;
          count++;
        }
      }

      return Color.fromRGBO(totalR ~/ count, totalG ~/ count, totalB ~/ count, 1.0);
    } catch (e) {
      print('NV21 region color extraction error: $e');
      return Colors.white;
    }
  }

  /// Same idea as [extractRegionColorFromNV21], for a decoded (JPEG/PNG)
  /// [img.Image] instead of a raw NV21 camera/screen-capture buffer — used
  /// by the static "Translate Image" path, which has no NV21 bytes to work
  /// with.
  static Color extractRegionColorFromImage(
    img.Image image,
    double regionX,
    double regionY,
    double regionWidth,
    double regionHeight,
  ) {
    try {
      if (regionWidth <= 0 || regionHeight <= 0) return Colors.white;

      final left = regionX.toInt().clamp(0, image.width - 1);
      final top = regionY.toInt().clamp(0, image.height - 1);
      final right = (regionX + regionWidth).toInt().clamp(left + 1, image.width);
      final bottom = (regionY + regionHeight).toInt().clamp(top + 1, image.height);

      const gridSize = 3;
      int totalR = 0, totalG = 0, totalB = 0, count = 0;
      for (int i = 0; i < gridSize; i++) {
        for (int j = 0; j < gridSize; j++) {
          final sx = left + ((right - left) * (i + 0.5) / gridSize).toInt();
          final sy = top + ((bottom - top) * (j + 0.5) / gridSize).toInt();
          final pixel = image.getPixel(sx, sy);
          totalR += pixel.r.toInt();
          totalG += pixel.g.toInt();
          totalB += pixel.b.toInt();
          count++;
        }
      }

      return Color.fromRGBO(totalR ~/ count, totalG ~/ count, totalB ~/ count, 1.0);
    } catch (e) {
      print('Image region color extraction error: $e');
      return Colors.white;
    }
  }

  /// Assign weights to sample points similar to Kotlin implementation
  static double _getWeightForIndex(int index) {
    switch (index) {
      case 1: // Top-left first third
      case 7: // Top-right first third
      case 10: // Left upper-middle first third
      case 16: // Right upper-middle first third
      case 25: // Center-right middle
      case 28: // Right middle middle
      case 31: // Right lower-middle first third
      case 34: // Right lower-middle middle
      case 37: // Bottom-right first third
        return 1.1;
      case 2: // Top-left middle
      case 6: // Top-right middle
      case 9: // Left upper-middle middle
      case 15: // Right upper-middle middle
      case 18: // Left middle middle
      case 23: // Right middle middle
      case 26: // Right middle two-thirds
      case 33: // Right lower-middle middle
      case 36: // Bottom-right middle
        return 1.2;
      case 3: // Top-left two-thirds
      case 5: // Top-right two-thirds
      case 12: // Center-left upper-middle
      case 14: // Center-right upper-middle
      case 20: // Left middle two-thirds
      case 22: // Right middle two-thirds
      case 29: // Center-left middle
      case 32: // Right lower-middle two-thirds
      case 35: // Bottom-right two-thirds
        return 1.1;
      case 4: // Top middle
      case 11: // Left upper-middle
      case 13: // Center-left upper-middle
      case 19: // Left middle
      case 21: // Right middle
      case 27: // Center-right middle
      case 30: // Center lower-middle
        return 1.3;
      case 8: // Top-right corner
      case 17: // Right upper-middle
      case 24: // Right middle
        return 1.4;
      case 4: // Exact center
        return 1.5;
      default:
        return 1.0;
    }
  }

  /// Get color from specific point in NV21 byte array
  static Color _getColorFromBytesNV21(Uint8List bytes, int width, int height, int x, int y) {
    try {
      if (y < 0 || y >= height || x < 0 || x >= width) {
        return Colors.white;
      }

      // NV21 format: Y plane followed by interleaved V and U planes
      final yIndex = y * width + x;
      final uvIndex = width * height + (y ~/ 2) * width + (x ~/ 2 * 2);

      // Extract Y, U, V components
      final y_value = bytes[yIndex] & 0xFF;
      final v = bytes[uvIndex] & 0xFF;
      final u = bytes[uvIndex + 1] & 0xFF;

      // Convert YUV to RGB
      final r = (y_value + 1.402 * (v - 128)).toInt().clamp(0, 255);
      final g = (y_value - 0.34414 * (u - 128) - 0.71414 * (v - 128)).toInt().clamp(0, 255);
      final b = (y_value + 1.772 * (u - 128)).toInt().clamp(0, 255);

      return Color.fromRGBO(r, g, b, 1.0);
    } catch (e) {
      print('Color extraction error at ($x, $y): $e');
      return Colors.white;
    }
  }
}
