import 'package:screen_translate/providers/translation_provider.dart';

class MockTranslationProvider extends TranslationProvider {
  @override
  Future<bool> requestPermissions() async {
    return false;  // Always return false for testing
  }
}
