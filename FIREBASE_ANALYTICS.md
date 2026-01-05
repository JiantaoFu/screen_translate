# Firebase Analytics Integration Guide

## Setup Complete ✓

Firebase Analytics has been integrated into your Screen Translate app. Here's how to use it:

## Basic Usage

### Import the service:
```dart
import 'services/firebase_analytics_service.dart';

final analytics = FirebaseAnalyticsService();
```

## Available Methods

### 1. Log Custom Events
```dart
// Simple event
await analytics.logEvent('button_clicked');

// Event with parameters
await analytics.logEvent('translation_completed', {
  'source_lang': 'en',
  'target_lang': 'es',
  'duration_ms': 1500,
});
```

### 2. Track Screen Views
```dart
await analytics.trackScreenView('home_screen');
await analytics.trackScreenView('settings_screen');
```

### 3. Track Translation
```dart
await analytics.trackTranslation(
  sourceLanguage: 'en',
  targetLanguage: 'fr',
  translationType: 'text',
);
```

### 4. Track OCR Operations
```dart
await analytics.trackOCR(
  textBlocksFound: 25,
  language: 'en',
);
```

### 5. Track Errors
```dart
await analytics.trackError(
  errorType: 'network_error',
  errorMessage: 'Failed to fetch translations',
);
```

### 6. Track Feature Usage
```dart
await analytics.trackFeatureUsage('screen_capture');
await analytics.trackFeatureUsage('text_selection');
```

### 7. Set User Information
```dart
// Set user ID (for tracking specific users)
await analytics.setUserId('user_123');

// Set custom user properties
await analytics.setUserProperty('premium_user', 'true');
await analytics.setUserProperty('preferred_language', 'spanish');
```

### 8. Reset Analytics Data
```dart
// Reset all analytics for current user
await analytics.resetUserData();
```

## Integration Locations

### 1. Add to OCR Service
In `lib/services/ocr_service.dart`, after processing images:
```dart
final analytics = FirebaseAnalyticsService();
await analytics.trackOCR(
  textBlocksFound: results.length,
  language: script.toString(),
);
```

### 2. Add to Translation Provider
In `lib/providers/translation_provider.dart`, after translations:
```dart
await analytics.trackTranslation(
  sourceLanguage: sourceLanguage,
  targetLanguage: targetLanguage,
  translationType: 'screen_translation',
);
```

### 3. Add to Screen Navigation
In each screen's `initState()`:
```dart
@override
void initState() {
  super.initState();
  final analytics = FirebaseAnalyticsService();
  analytics.trackScreenView('my_screen_name');
}
```

## Firebase Console

View your analytics data in the Firebase Console:
1. Go to [https://console.firebase.google.com](https://console.firebase.google.com)
2. Select your project "screentranslation-cff83"
3. Navigate to **Analytics** → **Dashboard**

## Data Privacy

- Data is collected automatically after app initialization
- User data is anonymized by default
- Check Firebase settings for GDPR/privacy compliance
- Users can opt-out of analytics collection via their device settings

## Event Naming Constraints

Firebase enforces these rules (automatically handled by the service):
- Event names: max 40 characters, alphanumeric + underscore only
- Parameter names: max 40 characters, alphanumeric + underscore only
- Parameter values (string): max 100 characters

## Notes

- Amplitude integration still exists in `lib/services/amplitude_service.dart` for backward compatibility
- Firebase Analytics can be used alongside Amplitude
- Remove `FirebaseAnalyticsService()` calls if you switch to Amplitude-only
