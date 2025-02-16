import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LLMTranslationService {
  final String _apiKey;
  final String _baseUrl;
  static const _apiKeyStorageKey = 'llm_translation_api_key';
  final _secureStorage = const FlutterSecureStorage();

  LLMTranslationService({
    String? apiKey, 
    String baseUrl = 'https://open.bigmodel.cn/api/paas/v4/chat/completions'
  }) : 
    _apiKey = apiKey ?? '',
    _baseUrl = baseUrl;

  // Load API key from secure storage or environment
  static Future<String?> getStoredApiKey() async {
    final secureStorage = const FlutterSecureStorage();
    return await secureStorage.read(key: _apiKeyStorageKey);
  }

  // Save API key to secure storage
  Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.write(key: _apiKeyStorageKey, value: apiKey);
  }

  // Remove stored API key
  Future<void> clearApiKey() async {
    await _secureStorage.delete(key: _apiKeyStorageKey);
  }

  // Static method to get API key
  static Future<String?> getApiKey() async {
    return await getStoredApiKey();
  }

  // Static method to check if an API key is configured
  static Future<bool> isApiKeyConfigured() async {
    final storedKey = await getStoredApiKey();
    return storedKey != null && storedKey.isNotEmpty;
  }

  // Validate API key before use
  bool isApiKeyValid() {
    return _apiKey.isNotEmpty && _apiKey.length > 10;
  }

  Future<bool> hasValidApiKey() async {
    try {
      // Retrieve the stored API key
      final storedApiKey = await _secureStorage.read(key: _apiKeyStorageKey);
      
      // Check if the API key exists and is not empty
      if (storedApiKey == null || storedApiKey.isEmpty) {
        return false;
      }
      
      try {
        // Attempt API validation using chat completions endpoint
        final response = await http.post(
          Uri.parse('https://open.bigmodel.cn/api/paas/v4/chat/completions'),
          headers: {
            'Authorization': 'Bearer $storedApiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': 'GLM-4-Flash',
            'messages': [
              {
                'role': 'user',
                'content': 'Hello, can you verify my API key?'
              }
            ],
            'max_tokens': 10, // Limit response to minimize unnecessary tokens
          }),
        );
        
        // Check if the response indicates a valid key
        // Successful responses are typically 200 or 201
        return response.statusCode == 200 || response.statusCode == 201;
      } catch (e) {
        // If there's an error during validation, log it and return false
        print('API key validation error: $e');
        return false;
      }
    } catch (e) {
      // Log the error
      print('Error checking API key: $e');
      return false;
    }
  }

  Future<String> translateText({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    // Retrieve the stored API key
    final storedApiKey = await getApiKey();
    
    if (storedApiKey == null || storedApiKey.isEmpty) {
      throw StateError('No API key configured. Please set up LLM translation in settings.');
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $storedApiKey'
        },
        body: jsonEncode({
          'model': 'GLM-4-Flash',
          'messages': [
            {
              'role': 'system', 
              'content': '''
# Role: Translation Expert

## Goals
- Focus on the field of multilingual translation, providing accurate and fluent translation services.

## Constraints
- The translation must be accurate, retaining the meaning and tone of the original text.
- The translation result must be fluent and natural, conforming to the expression habits of the target language.

## Skills
- Professional knowledge of multilingual translation
- Understanding and accurately translating text content
- Ensuring the fluency and accuracy of the translation result

## Output
- Output format: Fluent and accurate text in the target language

## Workflow
1. Read and understand the given text content thoroughly.
2. Analyze the nuances and context of the original text.
3. Translate the text while preserving its original meaning and tone.
4. Ensure the translation is fluent and natural in the target language.
5. Double-check that no critical information is lost in translation.
'''
            },
            {
              'role': 'user', 
              'content': 'Translate the following text from $sourceLanguage to $targetLanguage: "$text"'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['choices'][0]['message']['content'].trim();
      } else if (response.statusCode == 401) {
        throw StateError('Invalid API key. Please check your LLM translation settings.');
      } else if (response.statusCode == 429) {
        throw StateError('Rate limit exceeded. Please try again later.');
      } else {
        throw Exception('Failed to translate text: ${response.body}');
      }
    } catch (e) {
      debugPrint('LLM Translation error: $e');
      rethrow;
    }
  }
}
