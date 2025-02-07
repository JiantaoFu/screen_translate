package com.lomoware.screen_translate

import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.media.Image
import android.media.ImageReader
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mockito.*
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import java.nio.ByteBuffer
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

@RunWith(RobolectricTestRunner::class)
class ImageToBytesTest {

    @Test
    fun `test imageToBytes with all black pixels`() {
        // Create mocks
        val mockImage = mock(Image::class.java)
        val mockActivity = mock(Activity::class.java)

        // Setup mock dimensions
        val width = 100
        val height = 100

        // Configure mock image
        `when`(mockImage.width).thenReturn(width)
        `when`(mockImage.height).thenReturn(height)
        `when`(mockImage.format).thenReturn(PixelFormat.RGBA_8888)

        // Create a buffer with black pixel data
        val bufferSize = width * height * 4  // RGBA, 4 bytes per pixel
        val blackBuffer = ByteBuffer.allocate(bufferSize)
        
        // Fill buffer with black pixels (0,0,0,255)
        for (i in 0 until width * height) {
            blackBuffer.put(0.toByte())   // R
            blackBuffer.put(0.toByte())   // G
            blackBuffer.put(0.toByte())   // B
            blackBuffer.put(255.toByte()) // A
        }
        
        blackBuffer.rewind()

        // Configure mock planes
        val mockPlane = mock(Image.Plane::class.java)

        `when`(mockPlane.buffer).thenReturn(blackBuffer)
        `when`(mockPlane.pixelStride).thenReturn(4)
        `when`(mockPlane.rowStride).thenReturn(width * 4)

        `when`(mockImage.planes).thenReturn(arrayOf(mockPlane))

        // Create a mock context
        val context = RuntimeEnvironment.getApplication()

        // Call method under test
        val screenCaptureService = ScreenCaptureService(context, mockActivity)
        val result = screenCaptureService.imageToBytes(mockImage)

        // Assertions
        assertNotNull(result)

        // Dump first few bytes for verification
        println("First 50 bytes of converted data:")
        result.take(50).forEachIndexed { index, byte ->
            println("Byte $index: ${byte.toInt() and 0xFF}")
        }

        // Extension function to extract dominant color from bytes
        fun ByteArray.extractDominantColor(width: Int, height: Int): Int {
            try {
                // Sample strategic points
                val samplePoints = listOf(
                    Pair(0, 0),                     // Top-left
                    Pair(width / 4, height / 4),    // 1/4 through
                    Pair(width / 2, height / 2),    // Middle
                    Pair(3 * width / 4, 3 * height / 4), // 3/4 through
                    Pair(width - 1, height - 1)     // Bottom-right
                )

                // Color extraction function for bytes
                fun extractColorAtPoint(x: Int, y: Int): Int {
                    val pixelIndex = (y * width + x) * 4
                    
                    // Ensure we have enough bytes
                    if (pixelIndex + 3 >= size) {
                        return Color.GRAY
                    }

                    // Extract RGBA values
                    val r = this[pixelIndex].toInt() and 0xFF
                    val g = this[pixelIndex + 1].toInt() and 0xFF
                    val b = this[pixelIndex + 2].toInt() and 0xFF

                    return Color.rgb(r, g, b)
                }

                // Sample colors and find the darkest
                val sampledColors = samplePoints.map { (x, y) -> 
                    extractColorAtPoint(x, y)
                }

                // Find the darkest color based on luminance
                return sampledColors.minByOrNull { color ->
                    val r = Color.red(color)
                    val g = Color.green(color)
                    val b = Color.blue(color)
                    0.299 * r + 0.587 * g + 0.114 * b
                } ?: Color.GRAY
            } catch (e: Exception) {
                return Color.GRAY
            }
        }

        // Verify dominant color extraction
        val dominantColor = result.extractDominantColor(width, height)
        println("Dominant color: ${String.format("#%06X", 0xFFFFFF and dominantColor)}")
        
        // Black image should result in very dark color
        assertTrue(Color.red(dominantColor) <= 20)
        assertTrue(Color.green(dominantColor) <= 20)
        assertTrue(Color.blue(dominantColor) <= 20)
    }
}
