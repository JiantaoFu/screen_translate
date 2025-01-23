package com.example.screen_translate

import android.content.Context
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.util.Locale

class LocalizationHelper {
    companion object {
        private val translationCache = mutableMapOf<String, Map<String, String>>()

        fun getLocalizedString(context: Context, key: String): String {
            val locale = context.resources.configuration.locales[0].language
            
            // Check cache first
            if (translationCache.containsKey(locale)) {
                return translationCache[locale]?.get(key) ?: key
            }

            // Load translations
            val translations = loadTranslations(context, locale)
            translationCache[locale] = translations

            return translations[key] ?: key
        }

        private fun loadTranslations(context: Context, locale: String): Map<String, String> {
            return try {
                // Construct the asset filename
                val filename = "app_$locale.json"
                
                // Open and read the file
                val inputStream = context.assets.open(filename)
                val reader = BufferedReader(InputStreamReader(inputStream))
                val content = reader.use { it.readText() }
                
                // Parse JSON
                val jsonObject = JSONObject(content)
                
                // Convert to map
                jsonObject.keys().asSequence().associate { 
                    it to jsonObject.getString(it) 
                }
            } catch (e: Exception) {
                // Fallback to English if locale file not found
                loadFallbackTranslations(context)
            }
        }

        private fun loadFallbackTranslations(context: Context): Map<String, String> {
            return try {
                val inputStream = context.assets.open("app_en.json")
                val reader = BufferedReader(InputStreamReader(inputStream))
                val content = reader.use { it.readText() }
                
                val jsonObject = JSONObject(content)
                jsonObject.keys().asSequence().associate { 
                    it to jsonObject.getString(it) 
                }
            } catch (e: Exception) {
                // Absolute fallback
                mapOf(
                    "translation_mode" to "Translation Mode",
                    "original_text_mode" to "Original Text Mode",
                    "side_by_side_mode" to "Side by Side Mode"
                )
            }
        }
    }
}
