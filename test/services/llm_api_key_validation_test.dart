import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:screen_translate/services/llm_translation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storageKey = 'llm_translation_api_key';
  const oldKey = 'old-test-key-only';
  const candidate = 'new-test-key-only';
  const storage = FlutterSecureStorage();
  late LLMTranslationService service;

  setUp(() => FlutterSecureStorage.setMockInitialValues({storageKey: oldKey}));
  tearDown(() => service.dispose());

  for (final status in [200, 201]) {
    test('HTTP $status validates candidate before replacing saved key',
        () async {
      service =
          LLMTranslationService(validationClient: MockClient((request) async {
        expect(await storage.read(key: storageKey), oldKey,
            reason: 'candidate must never be persisted before validation');
        expect(request.headers['Authorization'], 'Bearer $candidate');
        return http.Response('{}', status);
      }));
      expect(await service.validateAndSaveApiKey('  $candidate  '),
          ApiKeyValidationResult.valid);
      expect(await storage.read(key: storageKey), candidate);
    });
  }

  for (final status in [400, 401, 403, 408, 429, 500, 503]) {
    test('HTTP $status never erases or overwrites an existing key', () async {
      service = LLMTranslationService(
          validationClient: MockClient(
              (_) async => http.Response('untrusted provider error', status)));
      expect(
          await service.validateAndSaveApiKey(candidate),
          status == 401
              ? ApiKeyValidationResult.invalid
              : ApiKeyValidationResult.unavailable);
      expect(await storage.read(key: storageKey), oldKey);
    });
  }

  test('network exceptions preserve saved key', () async {
    service = LLMTranslationService(validationClient: MockClient((_) async {
      throw http.ClientException('network unavailable');
    }));
    expect(await service.validateAndSaveApiKey(candidate),
        ApiKeyValidationResult.unavailable);
    expect(await storage.read(key: storageKey), oldKey);
  });

  test('timeout is bounded and a late success cannot overwrite saved key',
      () async {
    final response = Completer<http.Response>();
    service = LLMTranslationService(
      validationClient: MockClient((_) => response.future),
      validationTimeout: const Duration(milliseconds: 10),
    );
    expect(await service.validateAndSaveApiKey(candidate),
        ApiKeyValidationResult.unavailable);
    response.complete(http.Response('{}', 200));
    await Future<void>.delayed(Duration.zero);
    expect(await storage.read(key: storageKey), oldKey);
  });

  test('no stored key and rejected candidate does not create one', () async {
    FlutterSecureStorage.setMockInitialValues({});
    service = LLMTranslationService(
        validationClient: MockClient((_) async => http.Response('{}', 401)));
    expect(await service.validateAndSaveApiKey(candidate),
        ApiKeyValidationResult.invalid);
    expect(await storage.read(key: storageKey), isNull);
  });

  test('validating current saved key is read-only even on rejection', () async {
    service = LLMTranslationService(
        validationClient: MockClient((_) async => http.Response('{}', 401)));
    expect(await service.hasValidApiKey(), isFalse);
    expect(await storage.read(key: storageKey), oldKey);
  });

  test('empty candidate is rejected without network or storage mutation',
      () async {
    service = LLMTranslationService(validationClient: MockClient((_) async {
      fail('empty key must not be sent');
    }));
    expect(await service.validateAndSaveApiKey('   '),
        ApiKeyValidationResult.invalid);
    expect(await storage.read(key: storageKey), oldKey);
  });

  test('explicit user key removal remains available', () async {
    service = LLMTranslationService(
        validationClient: MockClient((_) async => http.Response('{}', 200)));
    await service.clearApiKey();
    expect(await storage.read(key: storageKey), isNull);
  });
}
