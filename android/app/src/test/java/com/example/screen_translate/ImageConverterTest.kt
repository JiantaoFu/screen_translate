package com.lomoware.screen_translate

import android.app.Activity
import android.content.Context
import android.content.res.Resources
import android.graphics.Color
import android.media.Image
import android.media.ImageReader
import android.util.DisplayMetrics
import com.lomoware.screen_translate.utils.ColorUtils
import org.junit.Before
import org.junit.Test
import org.junit.Assert.*
import org.mockito.Mockito.*
import org.robolectric.shadows.ShadowLog
import java.nio.ByteBuffer
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import kotlin.experimental.and

@RunWith(RobolectricTestRunner::class)
class ImageConverterTest {
    
    private lateinit var mockContext: Context
    private lateinit var mockActivity: Activity
    private lateinit var mockResources: Resources
    private lateinit var mockDisplayMetrics: DisplayMetrics
    private lateinit var service: ScreenCaptureService
    
    @Before
    fun setup() {
        ShadowLog.stream = System.out
        
        // Create mocks
        mockContext = mock(Context::class.java)
        mockActivity = mock(Activity::class.java)
        mockResources = mock(Resources::class.java)
        mockDisplayMetrics = DisplayMetrics().apply {
            widthPixels = 1080
            heightPixels = 2400
            densityDpi = 420
        }
        
        // Set up context to return resources
        `when`(mockContext.resources).thenReturn(mockResources)
        `when`(mockResources.displayMetrics).thenReturn(mockDisplayMetrics)
        
        service = ScreenCaptureService(mockContext, mockActivity)
    }

    private fun createMockImage(width: Int, height: Int, pixelStride: Int, rowStride: Int, data: ByteArray): Image {
        val image = mock(Image::class.java)
        val plane = mock(Image.Plane::class.java)
        val buffer = ByteBuffer.allocate(data.size)
        buffer.put(data)
        buffer.rewind()

        `when`(image.width).thenReturn(width)
        `when`(image.height).thenReturn(height)
        `when`(image.planes).thenReturn(arrayOf(plane))
        `when`(plane.buffer).thenReturn(buffer)
        `when`(plane.pixelStride).thenReturn(pixelStride)
        `when`(plane.rowStride).thenReturn(rowStride)

        return image
    }

    @Test
    fun `test output format matches ML Kit requirements`() {
        // Create a test pattern with all black pixels
        val width = 2
        val height = 2
        val pixelStride = 4
        val rowStride = width * pixelStride
        
        // Input data in RGBA format with all black pixels
        val inputData = ByteArray(width * height * 4) { 0 }
        
        // Expected output in NV21 format
        val expectedOutputSize = width * height + 2 * ((height + 1) / 2) * ((width + 1) / 2)
        
        // Create mock image
        val image = createMockImage(width, height, pixelStride, rowStride, inputData)
        
        // Convert image
        val result = service.imageToBytes(image)
        
        // Assertions
        assertNotNull("Conversion result should not be null", result)
        assertEquals("Output size should match NV21 format", expectedOutputSize, result!!.size)
        
        // Dump full result bytes
        println("Full result bytes:")
        result.forEachIndexed { index, byte ->
            println("Byte $index: ${byte.toInt() and 0xFF} (0x${(byte.toInt() and 0xFF).toString(16).padStart(2, '0')})")
        }
        
        // Verify Y plane (luminance)
        // For black pixels, Y value is ((66 * 0 + 129 * 0 + 25 * 0 + 128) shr 8) + 16 = 16
        val expectedY = ByteArray(width * height) { 16.toByte() }
        
        // Verify Y plane values
        for (i in 0 until width * height) {
            val expectedValue = expectedY[i].toInt() and 0xFF
            val actualValue = result[i].toInt() and 0xFF
            
            println("Y Plane Position $i:")
            println("  Expected Y value: ${expectedValue.toString(16).padStart(2, '0')}")
            println("  Actual Y value:   ${actualValue.toString(16).padStart(2, '0')}")
            
            assertEquals(
                "Y plane value at position $i should match expected luminance",
                expectedValue,
                actualValue
            )
        }
        
        // Verify UV plane values
        val uvStart = width * height
        val uvSize = width * height / 4  // Correct UV plane size for NV21
        
        println("\nUV Plane Bytes:")
        for (i in 0 until uvSize) {
            // First byte is V, second is U
            val vValue = result[uvStart + i * 2].toInt() and 0xFF
            val uValue = result[uvStart + i * 2 + 1].toInt() and 0xFF
            
            println("UV Block $i:")
            println("  V value: ${vValue.toString(16).padStart(2, '0')}")
            println("  U value: ${uValue.toString(16).padStart(2, '0')}")
            
            // Both V and U should be 128 for black pixels
            assertEquals(
                "V plane value at block $i should be 128 (neutral chrominance)",
                128,
                vValue
            )
            assertEquals(
                "U plane value at block $i should be 128 (neutral chrominance)",
                128,
                uValue
            )
        }
        
        // Verify dominant color extraction
        val dominantColor = ColorUtils.extractDominantColorFromNV21(result, width, height)
        println("Dominant color: ${String.format("#%06X", 0xFFFFFF and dominantColor)}")
        
        // Black image should result in very dark color
        assertTrue(Color.red(dominantColor) <= 20)
        assertTrue(Color.green(dominantColor) <= 20)
        assertTrue(Color.blue(dominantColor) <= 20)
    }
}
