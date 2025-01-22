import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_translate/providers/translation_provider.dart';
import 'package:screen_translate/screens/model_management_screen.dart';

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
              child: _buildLanguageDropdown(
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
              child: _buildLanguageDropdown(
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

  Widget _buildLanguageDropdown({
    required String? value,
    required void Function(String?)? onChanged,
    required String hint,
    required bool isSourceLanguage,
  }) {
    return Consumer<TranslationProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButton<String>(
            value: value,
            hint: Text(hint),
            underline: SizedBox(), // Remove underline
            icon: Icon(Icons.arrow_drop_down, color: Colors.blue),
            items: TranslationProvider.supportedLanguages.keys
              .map((String code) {
                return DropdownMenuItem<String>(
                  value: code,
                  child: Text(
                    TranslationProvider.supportedLanguages[code]!,
                  ),
                );
              }).toList(),
            onChanged: (selectedCode) {
              // Check for language conflict at the time of selection
              final isSameLanguage = isSourceLanguage 
                ? selectedCode == provider.targetLanguage 
                : selectedCode == provider.sourceLanguage;

              if (isSameLanguage) {
                // Show a snackbar or dialog to inform the user
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Source and target languages cannot be the same'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (onChanged != null) {
                onChanged(selectedCode);
              }
            },
          ),
        );
      },
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