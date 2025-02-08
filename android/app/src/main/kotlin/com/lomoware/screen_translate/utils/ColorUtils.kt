package com.lomoware.screen_translate.utils

import android.graphics.Color
import android.media.Image
import android.util.Log

object ColorUtils {
    private const val TAG = "ColorUtils"

    /**
     * Extract dominant color from NV21 byte array
     * @param bytes NV21 formatted byte array
     * @param width Image width
     * @param height Image height
     * @return Dominant color as an integer
     */
    @JvmStatic
    fun extractDominantColorFromNV21(bytes: ByteArray, width: Int, height: Int): Int {
        try {
            // Color extraction function for NV21
            fun extractColorAtPoint(x: Int, y: Int): Int {
                val yIndex = y * width + x
                val uvStart = width * height
                val uvIndex = uvStart + (y / 2) * width + (x / 2) * 2
                
                // Ensure we have enough bytes
                if (yIndex >= width * height || uvIndex + 1 >= bytes.size) {
                    return Color.GRAY
                }

                // Extract Y, U, V values
                val yVal = bytes[yIndex].toInt() and 0xFF
                val v = bytes[uvIndex].toInt() and 0xFF
                val u = bytes[uvIndex + 1].toInt() and 0xFF

                // Log detailed YUV values
                // Log.d(TAG, "YUV values at ($x, $y): Y=$yVal, U=$u, V=$v")

                // YUV to RGB conversion
                val r = ((yVal - 16) * 1.164 + (v - 128) * 1.596).toInt().coerceIn(0, 255)
                val g = ((yVal - 16) * 1.164 - (u - 128) * 0.392 - (v - 128) * 0.813).toInt().coerceIn(0, 255)
                val b = ((yVal - 16) * 1.164 + (u - 128) * 2.017).toInt().coerceIn(0, 255)

                // Log converted RGB values
                // Log.d(TAG, "Converted RGB at ($x, $y): R=$r, G=$g, B=$b")

                return Color.rgb(r, g, b)
            }

            return extractDominantColor(width, height) { x, y -> extractColorAtPoint(x, y) }
        } catch (e: Exception) {
            Log.e(TAG, "Error extracting dominant color", e)
            return Color.GRAY
        }
    }

    /**
     * Extract dominant color directly from an Image
     * @param image The input Image
     * @return Dominant color as an integer
     */
    @JvmStatic
    fun extractDominantColor(image: Image): Int {
        try {
            val width = image.width
            val height = image.height
            val planes = image.planes
            val buffer = planes[0].buffer
            val pixelStride = planes[0].pixelStride
            val rowStride = planes[0].rowStride

            // Color extraction function for Image
            fun extractColorAtPoint(x: Int, y: Int): Int {
                val pixelPos = y * rowStride + x * pixelStride
                buffer.position(pixelPos)
                
                // Ensure we have enough bytes
                if (pixelPos + 3 >= buffer.limit()) {
                    return Color.GRAY
                }

                // Read RGBA values
                val r = buffer.get().toInt() and 0xFF
                val g = buffer.get().toInt() and 0xFF
                val b = buffer.get().toInt() and 0xFF
                buffer.get() // Skip alpha

                return Color.rgb(r, g, b)
            }

            return extractDominantColor(width, height) { x, y -> extractColorAtPoint(x, y) }
        } catch (e: Exception) {
            Log.e(TAG, "Error extracting dominant color from Image", e)
            return Color.GRAY
        } finally {
            // Reset buffer position
            image.planes[0].buffer.rewind()
        }
    }

    /**
     * Extract dominant color using weighted average
     * @param width Image width
     * @param height Image height
     * @param extractColorAtPoint Function to extract color at a point
     * @return Dominant color as an integer
     */
    private fun extractDominantColor(width: Int, height: Int, extractColorAtPoint: (Int, Int) -> Int): Int {
        try {
            val samplePoints = listOf(
                // Top row (9 points)
                Pair(width / 16, height / 16),       // Top-left corner (weight: 1.0)
                Pair(width / 8, height / 16),         // Top-left first third (weight: 1.1)
                Pair(width / 4, height / 16),         // Top-left middle (weight: 1.2)
                Pair(3 * width / 8, height / 16),     // Top-left two-thirds (weight: 1.1)
                Pair(width / 2, height / 16),         // Top middle (weight: 1.3)
                Pair(5 * width / 8, height / 16),     // Top-right two-thirds (weight: 1.1)
                Pair(3 * width / 4, height / 16),     // Top-right middle (weight: 1.2)
                Pair(7 * width / 8, height / 16),     // Top-right first third (weight: 1.1)
                Pair(15 * width / 16, height / 16),   // Top-right corner (weight: 1.0)

                // Upper-middle row (9 points)
                Pair(width / 16, height / 4),         // Left upper-middle first third (weight: 1.1)
                Pair(width / 8, height / 4),          // Left upper-middle middle (weight: 1.2)
                Pair(width / 4, height / 4),          // Left upper-middle two-thirds (weight: 1.1)
                Pair(3 * width / 8, height / 4),      // Center-left upper-middle (weight: 1.3)
                Pair(width / 2, height / 4),          // Center upper-middle (weight: 1.4)
                Pair(5 * width / 8, height / 4),      // Center-right upper-middle (weight: 1.3)
                Pair(3 * width / 4, height / 4),      // Right upper-middle two-thirds (weight: 1.1)
                Pair(7 * width / 8, height / 4),      // Right upper-middle middle (weight: 1.2)
                Pair(15 * width / 16, height / 4),    // Right upper-middle first third (weight: 1.1)

                // Middle row (9 points)
                Pair(width / 16, height / 2),         // Left middle first third (weight: 1.2)
                Pair(width / 8, height / 2),          // Left middle middle (weight: 1.3)
                Pair(width / 4, height / 2),          // Left middle two-thirds (weight: 1.2)
                Pair(3 * width / 8, height / 2),      // Center-left middle (weight: 1.4)
                Pair(width / 2, height / 2),          // Exact center (weight: 1.5)
                Pair(5 * width / 8, height / 2),      // Center-right middle (weight: 1.4)
                Pair(3 * width / 4, height / 2),      // Right middle two-thirds (weight: 1.2)
                Pair(7 * width / 8, height / 2),      // Right middle middle (weight: 1.3)
                Pair(15 * width / 16, height / 2),    // Right middle first third (weight: 1.2)

                // Lower-middle row (9 points)
                Pair(width / 16, 3 * height / 4),     // Left lower-middle first third (weight: 1.1)
                Pair(width / 8, 3 * height / 4),      // Left lower-middle middle (weight: 1.2)
                Pair(width / 4, 3 * height / 4),      // Left lower-middle two-thirds (weight: 1.1)
                Pair(3 * width / 8, 3 * height / 4),  // Center-left lower-middle (weight: 1.3)
                Pair(width / 2, 3 * height / 4),      // Center lower-middle (weight: 1.4)
                Pair(5 * width / 8, 3 * height / 4),  // Center-right lower-middle (weight: 1.3)
                Pair(3 * width / 4, 3 * height / 4),  // Right lower-middle two-thirds (weight: 1.1)
                Pair(7 * width / 8, 3 * height / 4),  // Right lower-middle middle (weight: 1.2)
                Pair(15 * width / 16, 3 * height / 4),// Right lower-middle first third (weight: 1.1)

                // Bottom row (9 points)
                Pair(width / 16, 15 * height / 16),   // Bottom-left corner (weight: 1.0)
                Pair(width / 8, 15 * height / 16),    // Bottom-left first third (weight: 1.1)
                Pair(width / 4, 15 * height / 16),    // Bottom-left middle (weight: 1.2)
                Pair(3 * width / 8, 15 * height / 16),// Bottom-left two-thirds (weight: 1.1)
                Pair(width / 2, 15 * height / 16),    // Bottom middle (weight: 1.3)
                Pair(5 * width / 8, 15 * height / 16),// Bottom-right two-thirds (weight: 1.1)
                Pair(3 * width / 4, 15 * height / 16),// Bottom-right middle (weight: 1.2)
                Pair(7 * width / 8, 15 * height / 16),// Bottom-right first third (weight: 1.1)
                Pair(15 * width / 16, 15 * height / 16)// Bottom-right corner (weight: 1.0)
            )

            // Weighted color averaging
            val weightedColors = samplePoints.mapIndexed { index, (x, y) ->
                val color = extractColorAtPoint(x, y)
                val weight = when (index) {
                    1, 7, 10, 16, 25, 28, 31, 34, 37 -> 1.1f
                    2, 6, 9, 15, 18, 23, 26, 33, 36 -> 1.2f
                    3, 5, 12, 14, 20, 22, 29, 32, 35 -> 1.1f
                    4, 11, 13, 19, 21, 27, 30 -> 1.3f
                    8, 17, 24 -> 1.4f
                    4 -> 1.5f
                    else -> 1.0f
                }
                Pair(color, weight)
            }

            // Extract RGB components with weighted averaging
            val totalWeight = weightedColors.sumOf { it.second.toDouble() }
            val avgRed = weightedColors.map { 
                ((it.first shr 16) and 0xFF).toDouble() * it.second 
            }.sum() / totalWeight

            val avgGreen = weightedColors.map { 
                ((it.first shr 8) and 0xFF).toDouble() * it.second 
            }.sum() / totalWeight

            val avgBlue = weightedColors.map { 
                (it.first and 0xFF).toDouble() * it.second 
            }.sum() / totalWeight

            val dominantColor = Color.rgb(
                avgRed.toInt().coerceIn(0, 255), 
                avgGreen.toInt().coerceIn(0, 255), 
                avgBlue.toInt().coerceIn(0, 255)
            )

            Log.d(TAG, "Weighted Dominant Color: ${String.format("#%06X", 0xFFFFFF and dominantColor)}")

            return dominantColor
        } catch (e: Exception) {
            Log.e(TAG, "Error extracting dominant color", e)
            return Color.GRAY
        }
    }
}

// Extension function for convenience
fun ByteArray.extractDominantColor(width: Int, height: Int): Int = 
    ColorUtils.extractDominantColorFromNV21(this, width, height)

// Extension function for Image
fun Image.extractDominantColor(): Int = ColorUtils.extractDominantColor(this)
