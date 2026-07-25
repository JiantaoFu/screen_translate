import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:io';

import '../l10n/app_localizations.dart';

import '../services/llm_translation_service.dart';
import '../services/model_download_service.dart';
import '../services/onnx_translation_service.dart';
import '../providers/translation_provider.dart';
import 'package:provider/provider.dart';

class LLMApiConfigScreen extends StatefulWidget {
  const LLMApiConfigScreen({Key? key}) : super(key: key);

  @override
  _LLMApiConfigScreenState createState() => _LLMApiConfigScreenState();
}

class _LLMApiConfigScreenState extends State<LLMApiConfigScreen> {
  final _apiKeyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // ONNX model download state
  final Map<String, OnnxModelStatus> _onnxStatus = {};
  final Map<String, double> _onnxProgress = {};

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
    _refreshOnnxStatus();
  }

  Future<void> _refreshOnnxStatus() async {
    final svc = ModelDownloadService();
    for (final pair in kSupportedOnnxPairs) {
      final status = await svc.getOnnxModelStatus(pair.key);
      if (mounted) {
        setState(() => _onnxStatus[pair.key] = status);
      }
    }
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
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 10),
              Text(
                'ONNX Local Models',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Download Helsinki-NLP OPUS-MT models for high-quality offline translation (~40MB each).',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ...kSupportedOnnxPairs.map((pair) => _buildOnnxModelTile(pair)),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 10),
              Text(
                'Advanced Settings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Consumer<TranslationProvider>(
                builder: (context, provider, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('OCR Merge Aggressiveness: ${provider.mergeAggressiveness.toStringAsFixed(1)}x'),
                      const SizedBox(height: 5),
                      const Text(
                        'Higher values merge distant text blocks. Default is 1.5x.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Slider(
                        value: provider.mergeAggressiveness,
                        min: 0.0,
                        max: 3.0,
                        divisions: 30,
                        label: '${provider.mergeAggressiveness.toStringAsFixed(1)}x',
                        onChanged: (value) {
                          provider.setMergeAggressiveness(value);
                        },
                      ),
                    ],
                  );
                },
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

  Widget _buildOnnxModelTile(OnnxLangPair pair) {
    final status = _onnxStatus[pair.key] ?? OnnxModelStatus.notDownloaded;
    final progress = _onnxProgress[pair.key];

    IconData icon;
    Color iconColor;
    String statusLabel;
    switch (status) {
      case OnnxModelStatus.ready:
        icon = Icons.check_circle;
        iconColor = Colors.green;
        statusLabel = 'Ready';
        break;
      case OnnxModelStatus.downloading:
        icon = Icons.downloading;
        iconColor = Colors.blue;
        statusLabel = 'Downloading...';
        break;
      case OnnxModelStatus.error:
        icon = Icons.error_outline;
        iconColor = Colors.red;
        statusLabel = 'Error';
        break;
      case OnnxModelStatus.notDownloaded:
      default:
        icon = Icons.download_outlined;
        iconColor = Colors.grey;
        statusLabel = 'Not downloaded';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pair.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        statusLabel,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (status == OnnxModelStatus.notDownloaded || status == OnnxModelStatus.error)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download', style: TextStyle(fontSize: 13)),
                    onPressed: () => _downloadOnnxModel(pair),
                  )
                else if (status == OnnxModelStatus.ready)
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(fontSize: 13, color: Colors.red)),
                    onPressed: () async {
                      await ModelDownloadService().deleteOnnxModel(pair.key);
                      _refreshOnnxStatus();
                    },
                  )
                else if (status == OnnxModelStatus.downloading)
                  const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            if (status == OnnxModelStatus.downloading && progress != null) ...
              [
                const SizedBox(height: 8),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 2),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
          ],
        ),
      ),
    );
  }

  Future<void> _downloadOnnxModel(OnnxLangPair pair) async {
    setState(() => _onnxStatus[pair.key] = OnnxModelStatus.downloading);
    try {
      await ModelDownloadService().downloadOnnxModel(
        pair.key,
        onProgress: (p) {
          if (mounted) setState(() => _onnxProgress[pair.key] = p);
        },
      );
      if (mounted) {
        // Immediately flip to ready and clear progress so spinner stops.
        setState(() {
          _onnxStatus[pair.key] = OnnxModelStatus.ready;
          _onnxProgress.remove(pair.key);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pair.displayName} downloaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _onnxStatus[pair.key] = OnnxModelStatus.error;
          _onnxProgress.remove(pair.key);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    await _refreshOnnxStatus();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
}
