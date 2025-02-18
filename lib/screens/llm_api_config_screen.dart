import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../services/llm_translation_service.dart';
import '../providers/translation_provider.dart';

class LLMApiConfigScreen extends StatefulWidget {
  const LLMApiConfigScreen({Key? key}) : super(key: key);

  @override
  _LLMApiConfigScreenState createState() => _LLMApiConfigScreenState();
}

class _LLMApiConfigScreenState extends State<LLMApiConfigScreen> {
  final _apiKeyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _launchURL(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(
        url,
        mode: Platform.isAndroid 
          ? LaunchMode.externalApplication  // Use external browser on Android
          : LaunchMode.platformDefault,     // Use platform default on other platforms
      )) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error launching URL: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStoredApiKey();
  }

  Future<void> _loadStoredApiKey() async {
    final storedKey = await LLMTranslationService.getStoredApiKey();
    if (storedKey != null) {
      _apiKeyController.text = storedKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.api_key_dialog_title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                localizations.api_key_configuration_title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text: localizations.api_key_get_key_from,
                    ),
                    TextSpan(
                      text: 'BigModel.cn',
                      style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _launchURL('https://open.bigmodel.cn/'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Text(
                localizations.api_key_configuration_steps,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildConfigurationStep(
                localizations.api_key_step_1,
                Icons.account_circle,
              ),
              _buildConfigurationStep(
                localizations.api_key_step_2,
                Icons.settings,
              ),
              _buildConfigurationStep(
                localizations.api_key_step_3,
                Icons.key,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  labelText: localizations.api_key_input_label,
                  hintText: localizations.api_key_input_hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.vpn_key),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.api_key_input_error;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveApiKey,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator() 
                  : Text(localizations.api_key_save_button, style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 20),
              Text(
                localizations.api_key_note,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigurationStep(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<void> _saveApiKey() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });
      
      final apiKey = _apiKeyController.text.trim();
      final localizations = AppLocalizations.of(context)!;

      // First, do a basic validation
      if (apiKey.isEmpty || apiKey.length <= 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.api_key_input_error),
            backgroundColor: Colors.red,
          ),
        );
        setState(() { _isLoading = false; });
        return;
      }

      final llmService = LLMTranslationService();

      try {
        // Temporarily save the API key to test validation
        await llmService.saveApiKey(apiKey);
        
        // Validate the API key
        final isValidKey = await llmService.hasValidApiKey();
        
        if (!isValidKey) {
          // If invalid, remove the temporarily saved key
          await llmService.clearApiKey();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.api_key_save_error),
              backgroundColor: Colors.red,
            ),
          );
          setState(() { _isLoading = false; });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.api_key_save_success),
              backgroundColor: Colors.green,
            ),
          );
          setState(() { _isLoading = false; });
          Navigator.of(context).pop();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.api_key_save_error),
            backgroundColor: Colors.red,
          ),
        );
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
}
