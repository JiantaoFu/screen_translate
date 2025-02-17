import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:collection';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Top-level class for translation tasks
class _TranslationTask {
  final String text;
  final String sourceLanguage;
  final String targetLanguage;
  final Completer<String> completer;
  bool isCancelled;

  _TranslationTask({
    required this.text,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.completer,
    this.isCancelled = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TranslationTask &&
          text == other.text &&
          sourceLanguage == other.sourceLanguage &&
          targetLanguage == other.targetLanguage;

  @override
  int get hashCode =>
      text.hashCode ^ sourceLanguage.hashCode ^ targetLanguage.hashCode;
}

class LRUCache<K, V> {
  final int maxSize;
  final _cache = LinkedHashMap<K, V>();

  LRUCache(this.maxSize);

  V? get(K key) {
    if (!_cache.containsKey(key)) return null;
    
    // Move the accessed item to the end (most recently used)
    V value = _cache[key]!;
    _cache.remove(key);
    _cache[key] = value;
    
    return value;
  }

  void put(K key, V value) {
    // If key already exists, remove it first
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } 
    // If cache is full, remove the least recently used item (first item)
    else if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
    }
    
    // Add new item (which goes to the end)
    _cache[key] = value;
  }
}

class LLMTranslationService {
  final String _baseUrl;
  static const _apiKeyStorageKey = 'llm_translation_api_key';
  final _secureStorage = const FlutterSecureStorage();
  late final LRUCache<String, String> _translationCache;

  // Concurrency control for LLM translations
  final int _maxConcurrentTranslations = 20;  // Configurable limit
  final Queue<_TranslationTask> _translationQueue = Queue();
  final Set<_TranslationTask> _activeTranslations = {};
  Timer? _queueProcessingTimer;

  LLMTranslationService({
    String baseUrl = 'https://open.bigmodel.cn/api/paas/v4/chat/completions'
  }) : 
    _baseUrl = baseUrl {
    _translationCache = LRUCache<String, String>(100); // 100 item cache
    // Start periodic queue processing
    _startQueueProcessingTimer();
  }

  void _startQueueProcessingTimer() {
    // Check and process queue every 500 milliseconds
    _queueProcessingTimer = Timer.periodic(Duration(milliseconds: 500), (_) {
      if (_activeTranslations.length < _maxConcurrentTranslations && _translationQueue.isNotEmpty) {
        _processTranslationQueue();
      }
    });
  }

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

  // Static method to quickly check if an API key exists and meets basic criteria
  static Future<bool> isApiKeyConfigured() async {
    final storedKey = await getStoredApiKey();
    return storedKey != null && storedKey.isNotEmpty && storedKey.length > 10;
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
          Uri.parse(_baseUrl),
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

  Future<void> _processTranslationQueue() async {
    // Remove any cancelled tasks from the queue
    _translationQueue.removeWhere((task) => task.isCancelled);

    // If we've reached max concurrent translations, wait
    if (_activeTranslations.length >= _maxConcurrentTranslations) return;

    // If queue is empty, do nothing
    if (_translationQueue.isEmpty) return;

    // Take the next task from the queue
    final task = _translationQueue.removeFirst();

    // If task was cancelled during queuing, skip it
    if (task.isCancelled) {
      task.completer.complete(task.text);
      _processTranslationQueue();
      return;
    }

    _activeTranslations.add(task);

    try {
      final translatedText = await _performTranslation(
        text: task.text,
        sourceLanguage: task.sourceLanguage,
        targetLanguage: task.targetLanguage,
      );

      if (!task.isCancelled) {
        task.completer.complete(translatedText);
      } else {
        task.completer.complete(task.text);
      }
    } catch (e) {
      if (e is StateError && e.message.contains('Rate limit exceeded')) {
        // For rate limit errors, put the task back in the queue
        print('Rate limit hit. Requeuing translation task.');
        _translationQueue.addFirst(task);
        
        // Add a small delay before retrying to avoid immediate re-hitting the rate limit
        await Future.delayed(Duration(milliseconds: 100));
      } else if (!task.isCancelled) {
        task.completer.completeError(e);
      } else {
        task.completer.complete(task.text);
      }
    } finally {
      _activeTranslations.remove(task);
      _processTranslationQueue();
    }
  }

  // Generate a unique cache key based on translation parameters
  String _generateCacheKey(String text, String sourceLanguage, String targetLanguage) {
    return '$sourceLanguage:$targetLanguage:$text';
  }

  Future<String> translateText({
    required String text, 
    required String sourceLanguage, 
    required String targetLanguage
  }) async {
    final cacheKey = _generateCacheKey(text, sourceLanguage, targetLanguage);
    
    // Check cache first
    final cachedTranslation = _translationCache.get(cacheKey);
    if (cachedTranslation != null) {
      return cachedTranslation;
    }

    final task = _TranslationTask(
      text: text,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      completer: Completer<String>(),
    );

    _translationQueue.add(task);
    
    // Ensure queue processing is active
    if (_queueProcessingTimer == null || !_queueProcessingTimer!.isActive) {
      _startQueueProcessingTimer();
    }

    final translatedText = await task.completer.future;

    // Store in cache
    _translationCache.put(cacheKey, translatedText);

    return translatedText;
  }

  Future<String> _performTranslation({
    required String text, 
    required String sourceLanguage, 
    required String targetLanguage
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
- If you do not know how to translate it, or no need to translate, just leave it as is, keep it simple, **no extra explanation required**. For example:
  - If the original text is a domain name "est.io", the translation result should be "est.io"
  - If the original text is date time format "2024-01-01 12:00:00", the translation result should be "2024-01-01 12:00:00"
  - If the original text is something you don't know, like"Lomorage", the translation result should be "Lomorage"

## Skills
- Professional knowledge of multilingual translation
- Understanding and accurately translating text content
- Ensuring the fluency and accuracy of the translation result

## Output
- Output format: Fluent and accurate text in the target language.

## Workflow
1. Read and understand the given text content thoroughly.
2. Analyze the nuances and context of the original text.
3. Translate the text while preserving its original meaning and tone.
4. Ensure the translation is fluent and natural in the target language.
5. Double-check that no critical information is lost in translation. Keep it simple, **no extra explanation required**.
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

  // Method to cancel a specific translation task
  Future<void> cancelTranslation(String text, String sourceLanguage, String targetLanguage) async {
    final taskToCancel = _TranslationTask(
      text: text,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      completer: Completer<String>(),
    );

    // Cancel queued tasks
    _translationQueue.removeWhere((task) {
      if (task == taskToCancel) {
        task.isCancelled = true;
        task.completer.complete(text);
        return true;
      }
      return false;
    });

    // Cancel active tasks
    for (var task in _activeTranslations) {
      if (task == taskToCancel) {
        task.isCancelled = true;
      }
    }

    print('LLM Translation: Cancelled translation tasks for text: $text');
  }

  // Method to cancel all ongoing translations
  Future<void> cancelAllTranslations() async {
    for (var task in _translationQueue) {
      task.isCancelled = true;
      task.completer.complete('');
    }
    
    for (var task in _activeTranslations) {
      task.isCancelled = true;
      task.completer.complete('');
    }

    _translationQueue.clear();
    _activeTranslations.clear();

    // Stop the queue processing timer
    _queueProcessingTimer?.cancel();
    _queueProcessingTimer = null;

    print('LLM Translation: Cancelled all translation tasks');
  }

  // Cleanup method to dispose of resources
  void dispose() {
    _queueProcessingTimer?.cancel();
    cancelAllTranslations();
  }
}
