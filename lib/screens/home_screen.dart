import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:screen_translate/providers/translation_provider.dart';
import 'package:screen_translate/screens/model_management_screen.dart';

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

  // Helper method to build model status icon
  Widget _buildModelStatusIcon(String languageCode) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FutureBuilder<bool>(
          future: OnDeviceTranslatorModelManager().isModelDownloaded(languageCode),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return SizedBox.shrink();
            }
            
            return snapshot.data! 
              ? Icon(Icons.check_circle, color: Colors.green, size: 16)
              : Icon(Icons.download, color: Colors.orange, size: 16);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TranslationProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
            items: TranslationProvider.supportedLanguages.keys
              .map((String code) {
                return DropdownMenuItem<String>(
                  value: code,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        TranslationProvider.supportedLanguages[code]!,
                      ),
                      // Check download status
                      _buildModelStatusIcon(code),
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
                    content: Text('Source and target languages cannot be the same'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Attractive header
            _buildHeader(),
            
            // Main action buttons
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Language Selection Row
                    _buildLanguageSelector(context),
                    
                    SizedBox(height: 20),

                    Consumer<TranslationProvider>(
                      builder: (context, provider, child) => _buildActionButton(
                        icon: Icons.screenshot,
                        label: provider.isTranslating ? 'Stop Translation' : 'Translate Screen',
                        onTap: () async {
                          try {
                            if (provider.isTranslating) {
                              provider.stopTranslation();
                            } else {
                              await provider.startTranslation();
                            }
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

                    _buildActionButton(
                      icon: Icons.language,
                      label: 'Manage Translation Models',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ModelManagementScreen(),
                          ),
                        );
                      },
                      context: context,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    return Consumer<TranslationProvider>(
      builder: (context, provider, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Source Language Dropdown
            Flexible(
              child: ModelStatusDropdown(
                value: provider.sourceLanguage,
                onChanged: (language) {
                  provider.setSourceLanguage(language!);
                },
                hint: 'From',
                isSourceLanguage: true,
              ),
            ),
            
            SizedBox(width: 10),
            
            // Swap Languages Button
            IconButton(
              icon: Icon(Icons.swap_horiz, color: Colors.blue),
              onPressed: provider.swapLanguages,
            ),
            
            SizedBox(width: 10),
            
            // Target Language Dropdown
            Flexible(
              child: ModelStatusDropdown(
                value: provider.targetLanguage,
                onChanged: (language) {
                  provider.setTargetLanguage(language!);
                },
                hint: 'To',
                isSourceLanguage: false,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
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
            'Screen Translate',
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