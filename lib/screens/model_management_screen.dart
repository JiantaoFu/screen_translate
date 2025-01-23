import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:screen_translate/l10n/localization_extension.dart';

enum ModelDownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
  error
}

class ModelManagementScreen extends StatefulWidget {
  @override
  _ModelManagementScreenState createState() => _ModelManagementScreenState();
}

class _ModelManagementScreenState extends State<ModelManagementScreen> {
  final modelManager = OnDeviceTranslatorModelManager();
  Map<TranslateLanguage, ModelDownloadStatus> _modelStatuses = {};

  @override
  void initState() {
    super.initState();
    _loadModelStatuses();
  }

  Future<void> _loadModelStatuses() async {
    final statuses = <TranslateLanguage, ModelDownloadStatus>{};
    
    for (var language in TranslateLanguage.values) {
      final isDownloaded = await modelManager.isModelDownloaded(language.bcpCode);
      statuses[language] = isDownloaded 
        ? ModelDownloadStatus.downloaded 
        : ModelDownloadStatus.notDownloaded;
    }

    setState(() {
      _modelStatuses = statuses;
    });
  }

  Future<void> _toggleModelDownload(TranslateLanguage language) async {
    final localizations = AppLocalizations.of(context)!;

    // Prevent multiple simultaneous actions
    if (_modelStatuses[language] == ModelDownloadStatus.downloading) return;

    // Check if model is already downloaded
    if (_modelStatuses[language] == ModelDownloadStatus.downloaded) {
      // Show confirmation dialog
      final confirmDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(localizations.remove_translation_model),
          content: Text(
            localizations.remove_translation_model_confirmation(localizations.getLocalizedValue('language_${language.bcpCode}')),
          ),
          actions: [
            TextButton(
              child: Text(localizations.cancel),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(localizations.remove),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );

      // Exit if user cancels
      if (confirmDelete != true) return;

      // Attempt to delete the model
      developer.log('Attempting to delete model for ${language.bcpCode}', 
        name: 'ModelManagement',
        error: 'Deletion attempt'
      );

      final success = await modelManager.deleteModel(language.bcpCode);
      
      developer.log('Model deletion result: $success', 
        name: 'ModelManagement',
        error: success ? null : 'Deletion failed'
      );

      setState(() {
        _modelStatuses[language] = success 
          ? ModelDownloadStatus.notDownloaded 
          : ModelDownloadStatus.error;
      });

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.failed_to_remove_model(localizations.getLocalizedValue('language_${language.bcpCode}')))),
        );
      }
      return;
    }

    // If not downloaded, proceed with download
    setState(() {
      _modelStatuses[language] = ModelDownloadStatus.downloading;
    });

    try {
      developer.log('Attempting to download model for ${language.bcpCode}', 
        name: 'ModelManagement'
      );

      final success = await modelManager.downloadModel(language.bcpCode);
      
      developer.log('Model download result: $success', 
        name: 'ModelManagement',
        error: success ? null : 'Download failed'
      );

      setState(() {
        _modelStatuses[language] = success 
          ? ModelDownloadStatus.downloaded 
          : ModelDownloadStatus.error;
      });

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.failed_to_download_model(localizations.getLocalizedValue('language_${language.bcpCode}')))),
        );
      }

    } catch (e) {
      developer.log('Error in model management', 
        name: 'ModelManagement',
        error: e
      );

      setState(() {
        _modelStatuses[language] = ModelDownloadStatus.error;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.manage_translation_models),
      ),
      body: ListView(
        children: TranslateLanguage.values.map((language) {
          final languageCode = language.bcpCode;
          final languageName = localizations.getLocalizedValue('language_$languageCode');

          return ListTile(
            title: Text(languageName),
            trailing: GestureDetector(
              onTap: () => _toggleModelDownload(language),
              child: _buildModelStatusIndicator(language),
            ),
            subtitle: Text(_getSubtitleText(language, context)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModelStatusIndicator(TranslateLanguage language) {
    final status = _modelStatuses[language] ?? ModelDownloadStatus.notDownloaded;

    switch (status) {
      case ModelDownloadStatus.notDownloaded:
        return Icon(Icons.download, color: Colors.grey);
      case ModelDownloadStatus.downloading:
        return CircularProgressIndicator(
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        );
      case ModelDownloadStatus.downloaded:
        return Icon(Icons.check_circle, color: Colors.green);
      case ModelDownloadStatus.error:
        return Icon(Icons.error, color: Colors.red);
    }
  }

  String _getSubtitleText(TranslateLanguage language, BuildContext context) {
    final status = _modelStatuses[language] ?? ModelDownloadStatus.notDownloaded;
    final localizations = AppLocalizations.of(context)!;

    switch (status) {
      case ModelDownloadStatus.notDownloaded:
        return localizations.not_installed;
      case ModelDownloadStatus.downloading:
        return localizations.downloading;
      case ModelDownloadStatus.downloaded:
        return localizations.installed;
      case ModelDownloadStatus.error:
        return localizations.download_failed;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return this[0].toUpperCase() + substring(1);
  }
}