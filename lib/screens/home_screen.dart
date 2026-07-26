import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:screen_translate/providers/translation_provider.dart';
import 'package:screen_translate/screens/translation_settings_screen.dart';
import 'package:screen_translate/l10n/app_localizations.dart';
import 'package:screen_translate/services/model_download_service.dart';
import 'package:screen_translate/l10n/localization_extension.dart';
import '../providers/translation_provider.dart';
import '../services/llm_translation_service.dart';
import '../services/onnx_translation_service.dart';
import 'llm_api_config_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';
import 'dart:io';
import 'dart:async';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screen_translate/screens/image_translation_screen.dart';

class ModelStatusDropdown extends StatefulWidget {
  final String? value;
  final void Function(String?)? onChanged;
  final String hint;
  final bool isSourceLanguage;

  const ModelStatusDropdown({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.hint,
    required this.isSourceLanguage,
  }) : super(key: key);

  @override
  _ModelStatusDropdownState createState() => _ModelStatusDropdownState();
}

class _ModelStatusDropdownState extends State<ModelStatusDropdown> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  /// Quick-mode (on-device) language codes currently being pre-warmed in the
  /// background after selection, so their status icon can show a spinner
  /// instead of silently sitting on the stale download-available icon.
  final Set<String> _downloadingCodes = {};

  @override
  void initState() {
    super.initState();
    // Create an animation controller that we'll use to force a rebuild
    _animationController = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // NOTE: this widget is only used for Quick (on-device) and Cloud (LLM)
  // modes now — AI (ONNX) mode uses _OnnxPairSelector instead, since ONNX
  // only supports a small curated set of (source, target) PAIRS, which two
  // independently-filtered dropdowns can't represent without either
  // blocking valid combinations (filtering each side against the other's
  // current value creates unreachable combinations) or offering invalid
  // ones (listing both sides independently lets you combine two
  // individually-valid languages into a pair that doesn't actually exist).
  // A single dropdown over the literal list of valid pairs has neither
  // problem.

  Widget _buildModelStatusIcon(String languageCode, TranslationMode mode) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        switch (mode) {
          case TranslationMode.llm:
            // Cloud AI has no local model to download — always "ready".
            return Icon(Icons.check_circle, color: Colors.green, size: 16);

          case TranslationMode.onDevice:
            if (_downloadingCodes.contains(languageCode)) {
              return const SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }
            return FutureBuilder<bool>(
              future: ModelDownloadService().isModelDownloaded(languageCode),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return SizedBox.shrink();
                return snapshot.data!
                    ? Icon(Icons.check_circle, color: Colors.green, size: 16)
                    : Icon(Icons.download, color: Colors.orange, size: 16);
              },
            );

          case TranslationMode.onnx:
            // Unreachable — this widget isn't used in AI mode anymore.
            return const SizedBox.shrink();
        }
      },
    );
  }

  String _getLocalizedLanguageName(BuildContext context, String languageCode) {
    final localizations = AppLocalizations.of(context);

    // Dynamically get the localized language name
    if (TranslationProvider.supportedLanguages.keys.contains(languageCode)) {
      return localizations?.getLocalizedValue('language_$languageCode') ?? languageCode;
    }

    // Fallback to the original language code
    return languageCode;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TranslationProvider>(
      builder: (context, provider, child) {
        final displayCodes = TranslationProvider.supportedLanguages.keys.toList();
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.blue, width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButton<String>(
            onTap: () {
              // Force a rebuild by triggering the animation controller
              _animationController.forward(from: 0);
            },
            value: widget.value,
            hint: Text(widget.hint),
            underline: SizedBox(), // Remove underline
            icon: Icon(Icons.arrow_drop_down, color: Colors.blue),
            isExpanded: true,
            items: displayCodes
              .map((String code) {
                return DropdownMenuItem<String>(
                  value: code,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _getLocalizedLanguageName(context, code),
                          style: TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 4),
                      // Check download status
                      _buildModelStatusIcon(code, provider.translationMode),
                    ],
                  ),
                );
              }).toList(),
            onChanged: (selectedCode) {
              final isSameLanguage = widget.isSourceLanguage
                ? selectedCode == provider.targetLanguage
                : selectedCode == provider.sourceLanguage;

              if (isSameLanguage) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.source_and_target_cannot_be_the_same),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              final code = selectedCode!;

              // If in LLM (AI) mode, bypass local model downloads entirely!
              if (provider.translationMode == TranslationMode.llm) {
                widget.onChanged?.call(code);
                return;
              }

              // Quick mode (on-device / Google ML Kit). Apply the selection
              // immediately — TranslationService.translateText() already
              // downloads a missing model on demand (with its own progress
              // toast) the moment it's actually needed, so there's nothing
              // here that needs to block the pick. We still pre-warm the
              // download in the background so it's likely ready by the time
              // they hit translate, showing a per-language spinner instead
              // of leaving the stale download-available icon showing.
              widget.onChanged?.call(code);
              final modelService = ModelDownloadService();
              modelService.isModelDownloaded(code).then((isDownloaded) async {
                if (isDownloaded || _downloadingCodes.contains(code)) return;
                if (mounted) setState(() => _downloadingCodes.add(code));
                try {
                  await modelService.downloadModelWithFallback(code);
                } catch (_) {
                  // Swallowed — translateText() retries on demand and will
                  // surface a real error there if it's still unavailable.
                } finally {
                  if (mounted) setState(() => _downloadingCodes.remove(code));
                }
              });
            },
          ),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late StreamSubscription _intentDataStreamSubscription;

  /// AI-mode pair-selector downloads currently in flight: "source|target"
  /// -> progress (0.0-1.0). The dropdown itself stays interactive the whole
  /// time — the user can pick a different pair, or leave the screen, without
  /// waiting on this; it's purely a status overlay on the affected item(s).
  final Map<String, double> _onnxDownloadProgress = {};

  /// Pairs (by "source|target" key) actively downloading when the app was
  /// last backgrounded. Android closes the app's raw network sockets a few
  /// seconds after backgrounding a plain process with no foreground
  /// service, so these reliably fail shortly after — not from a real
  /// network problem. Resumed automatically on return instead of leaving a
  /// dead-end failure the user has to notice and retry manually.
  final Set<String> _onnxInterruptedByBackground = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSharingIntent();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _onnxInterruptedByBackground.addAll(_onnxDownloadProgress.keys);
    } else if (state == AppLifecycleState.resumed && _onnxInterruptedByBackground.isNotEmpty) {
      final toResume = _onnxInterruptedByBackground.toList();
      _onnxInterruptedByBackground.clear();
      for (final key in toResume) {
        final parts = key.split('|');
        _joinOnnxDownload(key, parts[0], parts[1]);
      }
    }
  }

  void _initSharingIntent() {
    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _navigateToImageTranslation(File(value.first.path));
      }
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        // clear the intent so it doesn't fire again
        ReceiveSharingIntent.instance.reset();
        _navigateToImageTranslation(File(value.first.path));
      }
    });
  }

  void _navigateToImageTranslation(File file) {
    // Provide translation provider so ImageTranslationScreen can use it
    final provider = Provider.of<TranslationProvider>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: provider,
          child: ImageTranslationScreen(imageFile: file),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  Future<void> _trackTranslationAndPromptReview(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    int translationCount = prefs.getInt('translationCount') ?? 0;
    int promptCount = prefs.getInt('reviewPromptCount') ?? 0;

    translationCount++;
    await prefs.setInt('translationCount', translationCount);

    // Prompt at increasing translation milestones
    final promptThresholds = [10, 50, 100, 250, 500];

    if (promptCount < promptThresholds.length &&
        translationCount >= promptThresholds[promptCount]) {
      _showReviewPromptDialog(context);
      await prefs.setInt('reviewPromptCount', promptCount + 1);
    }
  }

  void _showReviewPromptDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.enjoying_app),
          content: Text(AppLocalizations.of(context)!.review_prompt_message),
          actions: [
            TextButton(
              child: Text(AppLocalizations.of(context)!.not_now),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.rate_now),
              onPressed: () {
                _launchInAppReview(context);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _launchInAppReview(BuildContext context) async {
    final InAppReview inAppReview = InAppReview.instance;

    if (await inAppReview.isAvailable()) {
      inAppReview.requestReview();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.cannot_open_store)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Attractive header
            _buildHeader(context),

            // Main action buttons
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Language Selection Row
                    _buildLanguageSelector(context),

                    SizedBox(height: 20),

                    _buildTranslationModeToggle(context),

                    Consumer<TranslationProvider>(
                      builder: (context, provider, child) {
                        return Column(
                          children: [
                            if (Platform.isAndroid)
                              _buildActionButton(
                                icon: Icons.screenshot,
                                label: provider.isTranslating ? AppLocalizations.of(context)!.stop_translation : AppLocalizations.of(context)!.translate_screen,
                                onTap: () async {
                                  try {
                                    if (provider.isTranslating) {
                                      provider.stopTranslation();
                                    } else {
                                      await provider.startTranslation();
                                    }
                                    await _trackTranslationAndPromptReview(context);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: ${e.toString()}')),
                                    );
                                  }
                                },
                                context: context,
                              ),
                            if (Platform.isIOS || Platform.isAndroid) ...[
                              if (Platform.isAndroid) SizedBox(height: 15),
                              _buildActionButton(
                                icon: Icons.image,
                                label: 'Translate Image',
                                onTap: () async {
                                  final picker = ImagePicker();
                                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                                  if (pickedFile != null) {
                                    _navigateToImageTranslation(File(pickedFile.path));
                                  }
                                },
                                context: context,
                              ),
                            ]
                          ],
                        );
                      },
                    ),

                    SizedBox(height: 20),

                    Consumer<TranslationProvider>(
                      builder: (context, provider, child) {
                        return SizedBox.shrink(); // Removed: now in settings screen
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final provider = Provider.of<TranslationProvider>(context, listen: false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider.value(
                value: provider,
                child: const TranslationSettingsScreen(),
              ),
            ),
          );
        },
        child: const Icon(Icons.settings),
      ),
    );
  }

  /// Every (source, target) combination AI mode actually supports, as a
  /// single unit — direct pairs plus pivots. Selecting a PAIR rather than
  /// two independent languages avoids two failure modes tried earlier:
  /// filtering each dropdown against the other's current value can make
  /// valid combinations unreachable (a deadlock — e.g. default en/zh could
  /// never reach zh/en, since only one pair targets zh and none targets
  /// en-from-en), while listing both sides independently lets you combine
  /// two individually-valid languages into a pair that was never actually
  /// supported (e.g. Russian source + Chinese target — Russian only pairs
  /// with English). Neither issue is possible when the pair is the unit of
  /// selection.
  List<(String source, String target, String displayName)> _allOnnxPairs() {
    return [
      for (final p in kSupportedOnnxPairs) (p.sourceBcp, p.targetBcp, p.displayName),
      for (final piv in kSupportedOnnxPivotPairs) (piv.sourceBcp, piv.targetBcp, piv.displayName),
    ];
  }

  Future<OnnxModelStatus> _onnxPairStatus(String source, String target) async {
    final svc = ModelDownloadService();
    final pair = findOnnxPair(source, target);
    if (pair != null) return svc.getOnnxModelStatus(pair.key);
    final pivot = findOnnxPivotPair(source, target);
    if (pivot != null) return svc.getOnnxPivotStatus(pivot);
    return OnnxModelStatus.notDownloaded; // shouldn't happen — list is curated
  }

  /// Attaches to a download already in progress (started from this screen's
  /// own onChanged handler, from Settings, or anywhere else) so this item's
  /// spinner shows live percentage instead of an indeterminate spinner that
  /// never changes until the download happens to finish. No-op if already
  /// attached — ModelDownloadService.downloadOnnxModel() is safe to call
  /// again mid-download; it registers this onProgress as an extra listener
  /// on the same underlying operation rather than starting a duplicate one.
  Future<void> _joinOnnxDownload(String key, String source, String target) async {
    if (_onnxDownloadProgress.containsKey(key)) return;
    final pair = findOnnxPair(source, target);
    final pivot = pair == null ? findOnnxPivotPair(source, target) : null;
    if (pair == null && pivot == null) return;
    if (mounted) setState(() => _onnxDownloadProgress[key] = 0.0);
    final modelService = ModelDownloadService();
    try {
      if (pair != null) {
        await modelService.downloadOnnxModel(pair.key, onProgress: (p) {
          if (mounted) setState(() => _onnxDownloadProgress[key] = p);
        });
      } else {
        await modelService.downloadOnnxPivot(pivot!, onProgress: (p) {
          if (mounted) setState(() => _onnxDownloadProgress[key] = p);
        });
      }
    } catch (_) {
      // This screen only joined to observe — whichever screen actually
      // started the download owns surfacing the failure to the user.
    } finally {
      if (mounted) setState(() => _onnxDownloadProgress.remove(key));
    }
  }

  Widget _buildOnnxPairSelector(BuildContext context, TranslationProvider provider) {
    final pairs = _allOnnxPairs();
    final currentKey = '${provider.sourceLanguage}|${provider.targetLanguage}';
    final hasCurrentPair = pairs.any((p) => '${p.$1}|${p.$2}' == currentKey);

    // The dropdown stays interactive at all times, even mid-download — an
    // earlier version replaced the whole control with a progress-only view
    // while downloading, which trapped the user with no way to back out or
    // pick something else until it finished. Instead, an in-progress pack
    // just shows a live percentage in place of its status icon (including
    // on the dropdown's own closed face, if it's the currently-selected
    // pair — DropdownButton renders the selected item's same child there).
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: hasCurrentPair ? currentKey : null,
        hint: const Text('Select a language pair'),
        underline: SizedBox(),
        icon: Icon(Icons.arrow_drop_down, color: Colors.blue),
        isExpanded: true,
        items: pairs.map((p) {
          final key = '${p.$1}|${p.$2}';
          return DropdownMenuItem<String>(
            value: key,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(p.$3, style: TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
                ),
                SizedBox(width: 4),
                _onnxDownloadProgress.containsKey(key)
                    ? SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: _onnxDownloadProgress[key],
                        ),
                      )
                    : FutureBuilder<OnnxModelStatus>(
                        future: _onnxPairStatus(p.$1, p.$2),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return SizedBox.shrink();
                          if (snapshot.data == OnnxModelStatus.downloading) {
                            // Started elsewhere (e.g. Settings) — join it
                            // after this build so the next frame shows live
                            // percentage instead of this indeterminate spin.
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _joinOnnxDownload(key, p.$1, p.$2);
                            });
                            return const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          }
                          return snapshot.data == OnnxModelStatus.ready
                              ? Icon(Icons.check_circle, color: Colors.green, size: 16)
                              : Icon(Icons.download, color: Colors.orange, size: 16);
                        },
                      ),
              ],
            ),
          );
        }).toList(),
        onChanged: (selectedKey) async {
          final parts = selectedKey!.split('|');
          final source = parts[0], target = parts[1];
          final status = await _onnxPairStatus(source, target);

          // Apply the selection immediately either way — if it's already
          // downloading (started from here or from Settings; both now share
          // the same tracking, see ModelDownloadService), there's nothing
          // more to do here but wait for that to finish.
          provider.setSourceLanguage(source);
          provider.setTargetLanguage(target);
          if (status == OnnxModelStatus.ready || status == OnnxModelStatus.downloading) {
            return;
          }

          // ONNX packs are large (100s of MB, vs ~30MB for Quick mode) —
          // after filling a device's storage with these during testing, a
          // one-tap confirmation is worth keeping. Once confirmed, download
          // inline with real progress (we have onProgress callbacks here,
          // unlike Google ML Kit's downloadModel(), which exposes none) —
          // no need to send the user to Settings and back, and the dropdown
          // remains free to use for something else in the meantime.
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Download local AI model?'),
              content: const Text(
                  'This pack is typically 100–500MB. It downloads in the background; this pair will be ready to use once it finishes.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Download')),
              ],
            ),
          );
          if (confirmed != true) return;

          setState(() => _onnxDownloadProgress[selectedKey] = 0.0);
          final modelService = ModelDownloadService();
          try {
            final pair = findOnnxPair(source, target);
            if (pair != null) {
              await modelService.downloadOnnxModel(pair.key, onProgress: (p) {
                if (mounted) setState(() => _onnxDownloadProgress[selectedKey] = p);
              });
            } else {
              final pivot = findOnnxPivotPair(source, target);
              if (pivot != null) {
                await modelService.downloadOnnxPivot(pivot, onProgress: (p) {
                  if (mounted) setState(() => _onnxDownloadProgress[selectedKey] = p);
                });
              }
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${pairs.firstWhere((x) => '${x.$1}|${x.$2}' == selectedKey).$3} ready'), backgroundColor: Colors.green),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download failed. Please check your connection.'), backgroundColor: Colors.red),
              );
            }
          } finally {
            if (mounted) setState(() => _onnxDownloadProgress.remove(selectedKey));
          }
        },
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    return Consumer<TranslationProvider>(
      builder: (context, provider, child) {
        if (provider.translationMode == TranslationMode.onnx) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _buildOnnxPairSelector(context, provider),
          );
        }
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16), // Add some padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded( // Changed from Flexible to Expanded
                flex: 2,
                child: ModelStatusDropdown(
                  value: provider.sourceLanguage,
                  onChanged: (language) {
                    provider.setSourceLanguage(language!);
                  },
                  hint: AppLocalizations.of(context)!.source_language,
                  isSourceLanguage: true,
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: IconButton(
                  icon: Icon(Icons.swap_horiz, color: Colors.blue),
                  onPressed: provider.swapLanguages,
                  constraints: BoxConstraints(minWidth: 40),
                ),
              ),

              Expanded( // Changed from Flexible to Expanded
                flex: 2,
                child: ModelStatusDropdown(
                  value: provider.targetLanguage,
                  onChanged: (language) {
                    provider.setTargetLanguage(language!);
                  },
                  hint: AppLocalizations.of(context)!.target_language,
                  isSourceLanguage: false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTranslationModeToggle(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Consumer<TranslationProvider>(
      builder: (context, translationProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Translation Mode',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.info_outline, size: 20),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(localizations.translation_mode_title),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${localizations.translation_mode_on_device}:',
                                style: Theme.of(context).textTheme.titleSmall
                              ),
                              Text(localizations.translation_mode_on_device_description),
                              SizedBox(height: 10),
                              Text(
                                '${localizations.translation_mode_ai}:',
                                style: Theme.of(context).textTheme.titleSmall
                              ),
                              Text(localizations.translation_mode_ai_description),
                            ],
                          ),
                          actions: [
                            TextButton(
                              child: Text(localizations.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              Text(
                'Choose how you want to translate text',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              ToggleButtons(
                isSelected: [
                  translationProvider.translationMode == TranslationMode.onDevice,
                  translationProvider.translationMode == TranslationMode.onnx,
                  translationProvider.translationMode == TranslationMode.llm,
                ],
                onPressed: (index) async {
                  if (index == 1) { // ONNX mode selected
                    // Check if at least one ONNX model is downloaded
                    final svc = ModelDownloadService();
                    final enZhReady = await svc.getOnnxModelStatus('opus-mt-en-zh');
                    final jaEnReady = await svc.getOnnxModelStatus('opus-mt-ja-en');
                    final anyReady = enZhReady == OnnxModelStatus.ready ||
                        jaEnReady == OnnxModelStatus.ready;

                    if (!anyReady) {
                      await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Download a Language Pack'),
                            content: const Text(
                              'To use AI Enhanced mode, download a language pack first.\n\nGo to Settings to download one.',
                            ),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              ElevatedButton(
                                child: const Text('Open Settings'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  // Show the AI Enhanced section expanded on
                                  // arrival — that's the pack the user is
                                  // actually trying to set up, not whatever
                                  // mode was active before this dialog.
                                  translationProvider.setTranslationMode(TranslationMode.onnx);
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ChangeNotifierProvider.value(
                                        value: translationProvider,
                                        child: const TranslationSettingsScreen(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      );
                      return; // Do not switch mode
                    }
                  } else if (index == 2) { // LLM mode selected
                    final hasApiKey = await LLMTranslationService.isApiKeyConfigured();

                    if (!hasApiKey) {
                      await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('API Key Required'),
                            content: const Text('Cloud AI requires an API key. Set it up in Settings.'),
                            actions: [
                              TextButton(
                                child: Text(localizations.cancel),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              ElevatedButton(
                                child: Text(localizations.go_to_settings),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  // Show the Cloud AI section expanded on
                                  // arrival — that's what the user was
                                  // trying to set up, not whatever mode was
                                  // active before this dialog.
                                  translationProvider.setTranslationMode(TranslationMode.llm);
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ChangeNotifierProvider.value(
                                        value: translationProvider,
                                        child: const TranslationSettingsScreen(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      );
                      return; // Exit without changing mode
                    }
                  }

                  // Change translation mode
                  const modes = [
                    TranslationMode.onDevice,
                    TranslationMode.onnx,
                    TranslationMode.llm,
                  ];
                  translationProvider.setTranslationMode(modes[index]);
                },
                color: Colors.grey,
                selectedColor: Colors.white,
                fillColor: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(10),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.flash_on_rounded, size: 14),
                        SizedBox(width: 4),
                        Text('Quick', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.memory_rounded, size: 14),
                        SizedBox(width: 4),
                        Text('AI', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.cloud_rounded, size: 14),
                        SizedBox(width: 4),
                        Text('Cloud', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade300, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)!.app_title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Icon(Icons.translate, color: Colors.white, size: 30),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minimumSize: Size(280, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Colors.blue.shade50,
        foregroundColor: Colors.blue.shade700,
        elevation: 1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
