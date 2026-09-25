package com.lomoware.screen_translate

import com.lomoware.screen_translate.MlKitDownloadProgress.Entry
import com.lomoware.screen_translate.MlKitDownloadProgress.Progress
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class MlKitDownloadProgressTest {
    // The URI ML Kit actually used for Chinese on the emulator (2026-09-25).
    private val zhUri = "https://redirector.gvt1.com/edgedl/translate/offline/v5/high/r29/en_zh.zip"
    private val jaUri = "https://redirector.gvt1.com/edgedl/translate/offline/v5/high/r29/en_ja.zip"

    @Test
    fun matchesLanguageInPairFileName() {
        assertTrue(MlKitDownloadProgress.uriMentionsLang(zhUri, "zh"))
        assertTrue(MlKitDownloadProgress.uriMentionsLang("$zhUri?alt=media", "zh"))
        assertFalse(MlKitDownloadProgress.uriMentionsLang(zhUri, "ja"))
    }

    @Test
    fun ignoresLanguageCodesElsewhereInTheUri() {
        // "id" (Indonesian) and "it" (Italian) must not match path or host parts.
        val uri = "https://it.example.com/id/translate/offline/en_ko.zip"
        assertFalse(MlKitDownloadProgress.uriMentionsLang(uri, "id"))
        assertFalse(MlKitDownloadProgress.uriMentionsLang(uri, "it"))
        assertTrue(MlKitDownloadProgress.uriMentionsLang(uri, "ko"))
    }

    @Test
    fun picksOnlyTheRequestedLanguage() {
        val entries = listOf(Entry(zhUri, 10, 100), Entry(jaUri, 40, 50))
        assertEquals(Progress(10, 100, false), MlKitDownloadProgress.pick(entries, "zh"))
        assertEquals(Progress(40, 50, false), MlKitDownloadProgress.pick(entries, "ja"))
        assertNull(MlKitDownloadProgress.pick(entries, "ko"))
    }

    @Test
    fun unknownSizeIsReportedAsMinusOne() {
        // DownloadManager reports total=-1 until the response headers arrive.
        assertEquals(Progress(0, -1, false), MlKitDownloadProgress.pick(listOf(Entry(zhUri, 0, -1)), "zh"))
    }

    @Test
    fun pausedDownloadIsWaiting() {
        // Seen on the emulator: after "unexpected end of stream" the download
        // sat paused (waiting to retry) with no size for over a minute.
        val progress = MlKitDownloadProgress.pick(listOf(Entry(jaUri, 0, -1, paused = true)), "ja")
        assertTrue(progress!!.waiting)
    }
}
