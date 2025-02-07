import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';

class ColorUtils {
  /// Extract dominant color from NV21 formatted byte array using weighted average
  static Color extractDominantColorFromNV21(Uint8List bytes, int width, int height) {
    try {
      // Check if the byte array is large enough for NV21 format
      if (bytes.length < width * height * 1.5) {
        print('Image bytes too small for color extraction');
        return Colors.grey;
      }

      // Strategic sampling points with weights
      final samplePoints = [
        Point(width ~/ 8, height ~/ 8),       // Top-left quadrant (weight: 1.0)
        Point(width ~/ 2, height ~/ 8),        // Top middle (weight: 1.2)
        Point(7 * width ~/ 8, height ~/ 8),    // Top-right quadrant (weight: 1.0)
        Point(width ~/ 8, height ~/ 2),        // Middle left (weight: 1.1)
        Point(width ~/ 2, height ~/ 2),        // Center (weight: 1.5)
        Point(7 * width ~/ 8, height ~/ 2),    // Middle right (weight: 1.1)
        Point(width ~/ 8, 7 * height ~/ 8),    // Bottom-left quadrant (weight: 1.0)
        Point(width ~/ 2, 7 * height ~/ 8),    // Bottom middle (weight: 1.2)
        Point(7 * width ~/ 8, 7 * height ~/ 8) // Bottom-right quadrant (weight: 1.0)
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
      return Colors.grey;
    }
  }

  /// Assign weights to sample points similar to Kotlin implementation
  static double _getWeightForIndex(int index) {
    switch (index) {
      case 1: // Top middle
      case 7: // Bottom middle
        return 1.2;
      case 3: // Middle left
      case 5: // Middle right
        return 1.1;
      case 4: // Center
        return 1.5;
      default: // Corners
        return 1.0;
    }
  }

  /// Get color from specific point in NV21 byte array
  static Color _getColorFromBytesNV21(Uint8List bytes, int width, int height, int x, int y) {
    try {
      if (y < 0 || y >= height || x < 0 || x >= width) {
        return Colors.grey;
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
      return Colors.grey;
    }
  }
}
