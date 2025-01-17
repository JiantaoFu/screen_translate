import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_translate/providers/translation_provider.dart';
import 'package:screen_translate/services/android_screen_capture_service.dart';
import 'package:screen_translate/services/ocr_service.dart';

// Mock Platform to test iOS and Android specific code
class MockAndroidScreenCaptureService extends AndroidScreenCaptureService {
  bool captureStarted = false;
  Uint8List mockImageData = Uint8List(0);

  @override
  Future<bool> requestScreenCapture() async {
    captureStarted = true;
    return true;
  }

  @override
  Future<void> stopScreenCapture() async {
    captureStarted = false;
  }

  @override
  Future<Uint8List?> captureScreen() async {
    return mockImageData;
  }
}

class MockOCRService extends OCRService {
  String mockText = '';

  @override
  Future<String> processImage(Uint8List imageBytes) async {
    return mockText;
  }
}

class MockTranslationProvider extends TranslationProvider {
  final bool mockIsAndroid;
  final bool mockIsIOS;
  final MockAndroidScreenCaptureService mockAndroidService;
  final MockOCRService mockOcrService;

  MockTranslationProvider({
    this.mockIsAndroid = false,
    this.mockIsIOS = false,
  })  : mockAndroidService = MockAndroidScreenCaptureService(),
        mockOcrService = MockOCRService();

  @override
  Future<bool> requestPermissions() async {
    return false; // Mock permissions denied for testing
  }

  @override
  Future<void> _startAndroidScreenCapture() async {
    // Mock implementation
  }

  @override
  Future<void> _startIOSScreenCapture() async {
    // Mock implementation
  }
}

void main() {
  late MockTranslationProvider provider;

  setUp(() {
    provider = MockTranslationProvider();
  });

  group('TranslationProvider', () {
    test('initial values are correct', () {
      expect(provider.isTranslating, false);
      expect(provider.lastTranslatedText, '');
      expect(provider.sourceLanguage, 'en');
      expect(provider.targetLanguage, 'zh');
    });

    test('setLanguages updates language values', () {
      provider.setLanguages('ja', 'ko');
      expect(provider.sourceLanguage, 'ja');
      expect(provider.targetLanguage, 'ko');
    });

    test('updateTranslatedText updates last translated text', () {
      const testText = 'Hello World';
      provider.updateTranslatedText(testText);
      expect(provider.lastTranslatedText, testText);
    });

    test('stopTranslation sets isTranslating to false', () {
      provider.stopTranslation();
      expect(provider.isTranslating, false);
    });

    test('startTranslation throws exception when permissions denied', () async {
      expect(
        () => provider.startTranslation(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Required permissions were denied'),
        )),
      );
    });
  });
}
