import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:screen_translate/providers/translation_provider.dart';
import 'package:screen_translate/screens/model_management_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:screen_translate/l10n/localization_extension.dart';
import '../providers/translation_provider.dart';
import '../services/llm_translation_service.dart';
import 'llm_api_config_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
        return await OnDeviceTranslatorModelManager().isModelDownloaded(languageCode);
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
                      Text(
                        _getLocalizedLanguageName(context, code),
                        style: TextStyle(fontSize: 14), // Reduced font size
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(width: 1), // Small spacing
                      // Check download status
                      _buildModelStatusIcon(code , Provider.of<TranslationProvider>(context).translationMode),
                    ],
                  ),
                );
              }).toList(),
            onChanged: (selectedCode) {
              // Existing selection logic remains the same
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
                // Check model download status
                final modelManager = OnDeviceTranslatorModelManager();
                modelManager.isModelDownloaded(selectedCode!).then((isDownloaded) {
                  if (!isDownloaded) {
                    // Navigate to Model Management Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ModelManagementScreen(),
                      ),
                    );
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

class HomeScreen extends StatelessWidget {

  const HomeScreen({Key? key}) : super(key: key);

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
                _launchGooglePlayReview(context);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _launchGooglePlayReview(BuildContext context) async {
    const String googlePlayUrl = 'https://play.google.com/store/apps/details?id=com.lomoware.screen_translate';
    if (await canLaunch(googlePlayUrl)) {
      await launch(googlePlayUrl);
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
                      builder: (context, provider, child) => _buildActionButton(
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
                    ),

                    SizedBox(height: 20),

                    Consumer<TranslationProvider>(
                      builder: (context, provider, child) {
                        if (provider.translationMode == TranslationMode.onDevice)
                          return _buildActionButton(
                            icon: Icons.language,
                            label: AppLocalizations.of(context)!.manage_translation_models,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ModelManagementScreen(),
                                ),
                              );
                            },
                            context: context,
                          );
                        else
                          return SizedBox.shrink();
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
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => const LLMApiConfigScreen()
            )
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
    return Consumer<TranslationProvider>(
      builder: (context, translationProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Translation Mode', 
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                  translationProvider.translationMode == TranslationMode.llm
                ],
                onPressed: (index) async {
                  if (index == 1) { // LLM mode selected
                    final llmService = LLMTranslationService();
                    final hasApiKey = await LLMTranslationService.isApiKeyConfigured();

                    if (!hasApiKey) {
                      // Show dialog to guide user to API key settings
                      await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('API Key Required'),
                            content: const Text('Please set up your ChatGLM API key to use AI translation.'),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              ElevatedButton(
                                child: const Text('Go to Settings'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const LLMApiConfigScreen(),
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
                  translationProvider.setTranslationMode(
                    index == 0 
                      ? TranslationMode.onDevice 
                      : TranslationMode.llm
                  );
                },
                color: Colors.grey,
                selectedColor: Colors.white,
                fillColor: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(10),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text('On-Device', style: TextStyle(fontSize: 16)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text('AI', style: TextStyle(fontSize: 16)),
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
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        backgroundColor: Colors.blue.shade50,
        elevation: 5,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.blue.shade700),
          SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}