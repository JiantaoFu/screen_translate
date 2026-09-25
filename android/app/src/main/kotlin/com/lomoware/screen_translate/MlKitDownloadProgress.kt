package com.lomoware.screen_translate

import android.app.DownloadManager
import android.content.Context

/**
 * Real progress for Quick-mode (ML Kit) model downloads.
 *
 * ML Kit's translate API reports nothing until a model download finishes,
 * but it downloads through Android's DownloadManager, and DownloadManager
 * queries only return this app's own downloads. So the byte counts of the
 * ML Kit download for a language are readable here.
 */
object MlKitDownloadProgress {
    data class Entry(val uri: String, val downloaded: Long, val total: Long, val paused: Boolean = false)

    /**
     * [total] is <= 0 while the size isn't known yet. [waiting] is true when
     * DownloadManager has paused the download, which in practice means it is
     * waiting for the network (e.g. retrying after a dropped connection).
     * PAUSED also covers "queued for Wi-Fi"; that can't happen while the app
     * downloads with isWifiRequired: false, but would read as "waiting for
     * network" if that ever changes.
     */
    data class Progress(val downloaded: Long, val total: Long, val waiting: Boolean)

    /** Progress of the download for [lang], or null if none is running. */
    fun query(context: Context, lang: String): Progress? {
        val dm = context.getSystemService(DownloadManager::class.java) ?: return null
        val entries = mutableListOf<Entry>()
        val query = DownloadManager.Query().setFilterByStatus(
            DownloadManager.STATUS_PENDING or
                DownloadManager.STATUS_RUNNING or
                DownloadManager.STATUS_PAUSED
        )
        dm.query(query)?.use { c ->
            val uriCol = c.getColumnIndex(DownloadManager.COLUMN_URI)
            val soFarCol = c.getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR)
            val totalCol = c.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES)
            val statusCol = c.getColumnIndex(DownloadManager.COLUMN_STATUS)
            if (uriCol < 0 || soFarCol < 0 || totalCol < 0 || statusCol < 0) return null
            while (c.moveToNext()) {
                entries += Entry(
                    c.getString(uriCol) ?: "",
                    c.getLong(soFarCol),
                    c.getLong(totalCol),
                    c.getInt(statusCol) == DownloadManager.STATUS_PAUSED,
                )
            }
        }
        return pick(entries, lang)
    }

    /**
     * Sums the downloads whose URI names [lang]. Null when none match; the
     * total is -1 while any matching download's size isn't known yet.
     */
    fun pick(entries: List<Entry>, lang: String): Progress? {
        val matching = entries.filter { uriMentionsLang(it.uri, lang) }
        if (matching.isEmpty()) return null
        val total = if (matching.any { it.total <= 0 }) -1L else matching.sumOf { it.total }
        return Progress(matching.sumOf { it.downloaded }, total, matching.any { it.paused })
    }

    /**
     * ML Kit names each model file after its language pair, e.g.
     * ".../translate/offline/v5/high/r29/en_zh.zip" for Chinese. True when
     * [lang] is one side of the pair in the URI's file name.
     */
    internal fun uriMentionsLang(uri: String, lang: String): Boolean {
        val fileName = uri.substringBefore('?').substringAfterLast('/').lowercase()
        val pair = fileName.substringBefore('.').split('_')
        return lang.lowercase() in pair
    }
}
