# Firebase Remote Config Setup

## How It Works

Firebase Remote Config allows you to control app behavior without publishing updates. Now `drawDebugBoxes` and other settings can be toggled from the Firebase Console.

## Configure in Firebase Console

1. Go to [https://console.firebase.google.com](https://console.firebase.google.com)
2. Select your project: **screentranslation-cff83**
3. Navigate to **Remote Config**

### Add Configuration Parameters

Click **Create Configuration** and add these parameters:

#### 1. Debug OCR Boxes
- **Parameter key**: `debug_ocr_boxes`
- **Default value**: `false`
- **Type**: Boolean
- **Description**: Enable/disable OCR bounding box debug visualization

#### 2. OCR Min Text Length
- **Parameter key**: `ocr_min_text_length`
- **Default value**: `1`
- **Type**: Number
- **Description**: Minimum character length for OCR text blocks

#### 3. Enable Analytics
- **Parameter key**: `enable_analytics`
- **Default value**: `true`
- **Type**: Boolean
- **Description**: Toggle analytics collection

#### 4. Translation Timeout
- **Parameter key**: `translation_timeout_seconds`
- **Default value**: `30`
- **Type**: Number
- **Description**: Translation request timeout in seconds

#### 5. Max Concurrent Translations
- **Parameter key**: `max_concurrent_translations`
- **Default value**: `3`
- **Type**: Number
- **Description**: Maximum parallel translation requests

## Usage in Code

### Get OCR Debug Setting
```dart
final remoteConfig = FirebaseRemoteConfigService();
bool debugEnabled = remoteConfig.isDebugOCRBoxesEnabled();
```

### Programmatically Check Configuration
```dart
// In OCRService - automatically handles remote config
await ocrService.processImage(
  imageData,
  script,
  // drawDebugBoxes defaults to Firebase Remote Config value
);

// Or explicitly override
await ocrService.processImage(
  imageData,
  script,
  drawDebugBoxes: true, // Override remote config
);
```

### Fetch Fresh Config (Optional)
```dart
final remoteConfig = FirebaseRemoteConfigService();
await remoteConfig.fetchAndActivate(); // Manually refresh
```

### View All Config Values
```dart
final remoteConfig = FirebaseRemoteConfigService();
remoteConfig.logAllValues(); // Prints all values to logs
```

## Development vs Production

### Development Settings
In `firebase_remote_config_service.dart`, currently set to:
```dart
minimumFetchInterval: const Duration(seconds: 0), // Fetch fresh every time
```

This ensures you see changes immediately during development.

### Production Settings
Change to:
```dart
minimumFetchInterval: const Duration(hours: 1), // Cache for 1 hour
```

This reduces network requests and server load.

## Rollout Strategy

### Test a Feature Gradually
1. Create a targeting rule in Firebase Console
2. Roll out `debug_ocr_boxes: true` to:
   - 10% of users first
   - Then 50%
   - Finally 100%

This lets you monitor for issues before full rollout.

## Cache Behavior

- **First launch**: Uses hardcoded defaults (in `setDefaults()`)
- **Subsequent launches**: Uses cached values from last fetch
- **Manual refresh**: Call `fetchAndActivate()` to get latest

## Analytics Integration

When debug boxes are enabled via Remote Config:
```dart
await analytics.trackFeatureUsage('ocr_debug_boxes_enabled');
```

Track which configuration values users have for insights.

## Debugging

View logs to confirm values are being loaded:
```
I/FirebaseRemoteConfigService: Firebase Remote Config initialized
I/FirebaseRemoteConfigService: debug_ocr_boxes: false
I/FirebaseRemoteConfigService: ocr_min_text_length: 1
```

## Fallback Behavior

If Firebase is unavailable:
1. Last cached values are used
2. If no cache, hardcoded defaults apply
3. App continues functioning normally

This ensures graceful degradation.
