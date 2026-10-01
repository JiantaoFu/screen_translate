package com.lomoware.screen_translate

/**
 * Upper bound for a translation box's autosized text so no word is split
 * across lines.
 *
 * TextView autosize only checks that the text fits the box, not where it
 * breaks: in a narrow manga-bubble box it picked a size at which
 * "destroyed" was wider than the box and rendered "des / troyed". Capping
 * the maximum size at the width where the longest word still fits keeps
 * words whole; autosize can still go smaller to fit the height.
 */
object OverlayTextFit {
    /**
     * Largest text size (same unit as [refSize]) at which every
     * space-separated word of [text] fits in [availableWidth], or null when
     * there is nothing to cap. [measure] is the word's width at [refSize];
     * width scales linearly with text size. Words containing CJK characters
     * are skipped: those scripts may break between any two characters.
     */
    fun maxSizeKeepingWordsWhole(
        text: String,
        availableWidth: Float,
        refSize: Float,
        measure: (String) -> Float,
    ): Float? {
        if (availableWidth <= 0f) return null
        val widest = text.split(Regex("\\s+"))
            .filter { it.isNotEmpty() && it.none(::isCjk) }
            .maxOfOrNull(measure) ?: return null
        if (widest <= 0f) return null
        return refSize * availableWidth / widest
    }

    private fun isCjk(c: Char): Boolean {
        val block = Character.UnicodeBlock.of(c)
        return block == Character.UnicodeBlock.CJK_UNIFIED_IDEOGRAPHS ||
            block == Character.UnicodeBlock.HIRAGANA ||
            block == Character.UnicodeBlock.KATAKANA ||
            block == Character.UnicodeBlock.HANGUL_SYLLABLES ||
            block == Character.UnicodeBlock.CJK_SYMBOLS_AND_PUNCTUATION ||
            block == Character.UnicodeBlock.HALFWIDTH_AND_FULLWIDTH_FORMS ||
            block == Character.UnicodeBlock.THAI
    }
}
