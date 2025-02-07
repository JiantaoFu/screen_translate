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
                Pair(width / 8, height / 8),       // Top-left quadrant (weight: 1.0)
                Pair(width / 2, height / 8),        // Top middle (weight: 1.2)
                Pair(7 * width / 8, height / 8),    // Top-right quadrant (weight: 1.0)
                Pair(width / 8, height / 2),        // Middle left (weight: 1.1)
                Pair(width / 2, height / 2),        // Center (weight: 1.5)
                Pair(7 * width / 8, height / 2),    // Middle right (weight: 1.1)
                Pair(width / 8, 7 * height / 8),    // Bottom-left quadrant (weight: 1.0)
                Pair(width / 2, 7 * height / 8),    // Bottom middle (weight: 1.2)
                Pair(7 * width / 8, 7 * height / 8) // Bottom-right quadrant (weight: 1.0)
            )

            // Weighted color averaging
            val weightedColors = samplePoints.mapIndexed { index, (x, y) ->
                val color = extractColorAtPoint(x, y)
                val weight = when (index) {
                    1, 7 -> 1.2f   // Top and bottom middle
                    3, 5 -> 1.1f   // Middle left and right
                    4 -> 1.5f      // Center
                    else -> 1.0f   // Corners
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
