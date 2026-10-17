# Lite flavor (com.lomoware.screen_translate.lite)

`google-services.json` for the lite package must be placed here:

    android/app/src/lite/google-services.json

It is not in the repo yet because the Firebase Android app for
`com.lomoware.screen_translate.lite` has not been created. Steps:

1. Firebase console → project `screentranslation-cff83` → Project settings →
   Add app → Android, package name `com.lomoware.screen_translate.lite`,
   nickname "Screen Translator Lite". Add the SHA-1/SHA-256 of the upload key
   and of Play App Signing (Play Console → Test and release → App integrity).
2. Download `google-services.json` and save it at the path above. Commit it
   like the paid app's `android/app/google-services.json` (it contains no
   secrets).
3. Remote Config (shared by both apps in the project): add
   `lite_daily_free_translations` (number, default 5).

Until the file exists, lite builds skip the google-services/Crashlytics tasks
(see `android/app/build.gradle`) and the lite app runs without Firebase:
the daily limit uses the built-in default of 5, analytics events are dropped.
`tools/build.py --flavor lite` refuses release builds (apk/aab) without it.
