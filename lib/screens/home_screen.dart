import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:screen_translate/providers/translation_provider.dart';
import 'package:screen_translate/screens/model_management_screen.dart';
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

  Future<bool> _checkModelAvailability(String languageCode, TranslationMode mode) async {
    switch (mode) {
      case TranslationMode.onDevice:
        return await ModelDownloadService().isModelDownloaded(languageCode);
      case TranslationMode.onnx:
        // Check if either en-zh or ja-zh ONNX model is ready
        final svc = ModelDownloadService();
        final enZh = await svc.getOnnxModelStatus('opus-mt-en-zh');
        final jaZh = await svc.getOnnxModelStatus('opus-mt-jap-zh');
        return enZh == OnnxModelStatus.ready || jaZh == OnnxModelStatus.ready;
      case TranslationMode.llm:
        // For LLM, always consider the language "ready"
        return true;
    }
  }

  Widget _buildModelStatusIcon(String languageCode, TranslationMode mode) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FutureBuilder<bool>(
          future: _checkModelAvailability(languageCode, mode),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return SizedBox.shrink();
            }

            return snapshot.data!
              ? Icon(Icons.check_circle, color: Colors.green, size: 16)
              : (mode == TranslationMode.onDevice
                  ? Icon(Icons.download, color: Colors.orange, size: 16)
                  : SizedBox.shrink());
          },
        );
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
            items: TranslationProvider.supportedLanguages.keys
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
                      _buildModelStatusIcon(code , Provider.of<TranslationProvider>(context).translationMode),
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
              } else {
                // If in LLM (AI) mode, bypass local model downloads entirely!
                if (provider.translationMode == TranslationMode.llm) {
                  if (widget.onChanged != null) {
                    widget.onChanged!(selectedCode);
                  }
                  return;
                }

                // Check model download status for on-device translation
                final modelService = ModelDownloadService();
                modelService.isModelDownloaded(selectedCode!).then((isDownloaded) {
                  if (!isDownloaded) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: Provider.of<TranslationProvider>(context, listen: false),
                          child: const TranslationSettingsScreen(),
                        ),
                      ),
                    ).then((_) {
                      // Re-check model download status upon returning from download screen
                      modelService.isModelDownloaded(selectedCode).then((nowDownloaded) {
                        if (nowDownloaded && widget.onChanged != null) {
                          widget.onChanged!(selectedCode);
                        }
                      });
                    });
                  } else if (widget.onChanged != null) {
                    widget.onChanged!(selectedCode);
                  }
                });
              }
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

class _HomeScreenState extends State<HomeScreen> {
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initSharingIntent();
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

  Widget _buildLanguageSelector(BuildContext context) {
    return Consumer<TranslationProvider>(
      builder: (context, provider, child) {
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
                    final jaZhReady = await svc.getOnnxModelStatus('opus-mt-jap-zh');
                    final anyReady = enZhReady == OnnxModelStatus.ready ||
                        jaZhReady == OnnxModelStatus.ready;

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
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ChangeNotifierProvider.value(
                                        value: Provider.of<TranslationProvider>(context, listen: false),
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
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ChangeNotifierProvider.value(
                                        value: Provider.of<TranslationProvider>(context, listen: false),
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
