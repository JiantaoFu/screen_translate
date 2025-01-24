package com.lomoware.screen_translate

import android.app.Activity
import android.content.Context
import android.content.res.Resources
import android.media.Image
import android.media.ImageReader
import android.util.DisplayMetrics
import org.junit.Before
import org.junit.Test
import org.junit.Assert.*
import org.mockito.Mockito.*
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
        // Create a test pattern that makes it easy to verify byte order
        val width = 2
        val height = 1
        val pixelStride = 4
        val rowStride = width * pixelStride
        
        // Input data in RGBA format with known values
        // Pixel 1: R=0xFF, G=0x00, B=0x00, A=0xFF (Pure Red)
        // Pixel 2: R=0x00, G=0xFF, B=0x00, A=0xFF (Pure Green)
        val inputData = byteArrayOf(
            // RGBA RGBA
            0xFF.toByte(), 0x00.toByte(), 0x00.toByte(), 0xFF.toByte(),  // Pure Red with full alpha
            0x00.toByte(), 0xFF.toByte(), 0x00.toByte(), 0xFF.toByte()   // Pure Green with full alpha
        )
        
        // Expected output in BGRA format
        // Pixel 1: B=0x00, G=0x00, R=0xFF, A=0xFF
        // Pixel 2: B=0x00, G=0xFF, R=0x00, A=0xFF
        val expectedOutput = byteArrayOf(
            // BGRA BGRA
            0x00.toByte(), 0x00.toByte(), 0xFF.toByte(), 0xFF.toByte(),  // Red pixel in BGRA
            0x00.toByte(), 0xFF.toByte(), 0x00.toByte(), 0xFF.toByte()   // Green pixel in BGRA
        )
        
        // Create mock image
        val image = createMockImage(width, height, pixelStride, rowStride, inputData)
        
        // Convert image
        val result = service.imageToBytes(image)
        
        // Verify output
        assertNotNull("Conversion result should not be null", result)
        assertEquals("Output size should match expected size", expectedOutput.size, result!!.size)
        
        // Verify each byte matches expected BGRA format
        for (i in result.indices) {
            assertEquals(
                "Byte at position $i should match expected BGRA format",
                expectedOutput[i].toInt() and 0xFF,
                result[i].toInt() and 0xFF
            )
        }
        
        // Additional verification of color channels
        fun verifyPixel(offset: Int, b: Int, g: Int, r: Int, a: Int) {
            assertEquals("B channel at offset $offset", b, result[offset + 0].toInt() and 0xFF)
            assertEquals("G channel at offset $offset", g, result[offset + 1].toInt() and 0xFF)
            assertEquals("R channel at offset $offset", r, result[offset + 2].toInt() and 0xFF)
            assertEquals("A channel at offset $offset", a, result[offset + 3].toInt() and 0xFF)
        }
        
        // Verify first pixel (Red)
        verifyPixel(0, 0x00, 0x00, 0xFF, 0xFF)
        
        // Verify second pixel (Green)
        verifyPixel(4, 0x00, 0xFF, 0x00, 0xFF)
        
        // Log the actual bytes for debugging
        println("Input bytes: ${inputData.joinToString { (it.toInt() and 0xFF).toString(16).padStart(2, '0') }}")
        println("Output bytes: ${result.joinToString { (it.toInt() and 0xFF).toString(16).padStart(2, '0') }}")
        println("Expected bytes: ${expectedOutput.joinToString { (it.toInt() and 0xFF).toString(16).padStart(2, '0') }}")
    }
}
