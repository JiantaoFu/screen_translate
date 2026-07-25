import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../models/ocr_result.dart';
import '../providers/translation_provider.dart';
import '../services/ocr_service.dart';
import 'package:screen_translate/l10n/app_localizations.dart';
import '../services/firebase_analytics_service.dart';

class ImageTranslationScreen extends StatefulWidget {
  final File? imageFile;
  final Uint8List? memoryImage;

  const ImageTranslationScreen({Key? key, this.imageFile, this.memoryImage}) : super(key: key);

  @override
  _ImageTranslationScreenState createState() => _ImageTranslationScreenState();
}

class _ImageTranslationScreenState extends State<ImageTranslationScreen> {
  bool _isProcessing = true;
  List<OCRResult> _ocrResults = [];
  List<String> _translatedTexts = [];

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    setState(() {
      _isProcessing = true;
    });

    final stopwatch = Stopwatch()..start();
    debugPrint('[ImageTranslation] Starting image processing...');

    try {
      final translationProvider = Provider.of<TranslationProvider>(context, listen: false);
      final ocrService = OCRService();

      List<OCRResult> results = [];
      if (widget.memoryImage != null) {
        debugPrint('[ImageTranslation] Processing memory image via OCR...');
        results = await ocrService.processImage(
          {'bytes': widget.memoryImage, 'width': 0, 'height': 0},
          translationProvider.currentOCRScript,
        );
      } else if (widget.imageFile != null) {
        debugPrint('[ImageTranslation] Processing image file via OCR: ${widget.imageFile!.path}');
        results = await ocrService.processFile(
          widget.imageFile!,
          translationProvider.currentOCRScript,
        );
      }

      final ocrMs = stopwatch.elapsedMilliseconds;
      debugPrint('[ImageTranslation] OCR completed in ${ocrMs}ms. Found ${results.length} text blocks.');
      for (var i = 0; i < results.length; i++) {
        debugPrint('[ImageTranslation] OCR Block $i: "${results[i].text}"');
      }

      stopwatch.reset();
      final textsToTranslate = results.map((r) => r.text).toList();
      debugPrint('[ImageTranslation] Requesting batch translation for ${textsToTranslate.length} texts (mode=${translationProvider.translationMode.name})...');
      
      final translated = await translationProvider.translateBatch(textsToTranslate);
      final transMs = stopwatch.elapsedMilliseconds;
      debugPrint('[ImageTranslation] Batch translation completed in ${transMs}ms.');
      for (var i = 0; i < translated.length; i++) {
        debugPrint('[ImageTranslation] Result Block $i: "${results[i].text}" -> "${translated[i]}"');
      }

      setState(() {
        _ocrResults = results;
        _translatedTexts = translated;
        _isProcessing = false;
      });

      FirebaseAnalyticsService().trackTranslation(
        sourceLanguage: translationProvider.sourceLanguage,
        targetLanguage: translationProvider.targetLanguage,
        translationType: 'image_${translationProvider.translationMode.name}',
      );
    } catch (e, stack) {
      debugPrint('[ImageTranslation] ERROR processing image: $e\n$stack');
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Translation'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _processImage,
          ),
        ],
      ),
      body: _isProcessing
          ? Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return InteractiveViewer(
                  maxScale: 5.0,
                  child: Stack(
                    children: [
                      Center(
                        child: widget.imageFile != null
                            ? Image.file(widget.imageFile!)
                            : Image.memory(widget.memoryImage!),
                      ),
                      // We need to render the translations over the image.
                      // Calculating the exact position requires knowing the image's displayed size versus actual size.
                      // For a simple MVP, we can list the translations below or attempt to overlay.
                      // Since mapping coordinates can be tricky without exact image dimensions, let's overlay them if possible or just show a list.
                      // Wait, OCRResult contains x, y, width, height, and imgWidth, imgHeight.
                      ..._buildOverlays(constraints),
                    ],
                  ),
                );
              },
            ),
    );
  }

  List<Widget> _buildOverlays(BoxConstraints constraints) {
    if (_ocrResults.isEmpty) return [];
    
    // Attempting to calculate scale based on the first result's imgWidth/imgHeight
    final imgWidth = _ocrResults.first.imgWidth;
    final imgHeight = _ocrResults.first.imgHeight;
    
    if (imgWidth == 0 || imgHeight == 0) return [];

    // Calculate how the image is scaled in the view (assuming BoxFit.contain centered)
    final viewAspectRatio = constraints.maxWidth / constraints.maxHeight;
    final imgAspectRatio = imgWidth / imgHeight;

    double displayWidth, displayHeight;
    double offsetX = 0, offsetY = 0;

    if (viewAspectRatio > imgAspectRatio) {
      displayHeight = constraints.maxHeight;
      displayWidth = displayHeight * imgAspectRatio;
      offsetX = (constraints.maxWidth - displayWidth) / 2;
    } else {
      displayWidth = constraints.maxWidth;
      displayHeight = displayWidth / imgAspectRatio;
      offsetY = (constraints.maxHeight - displayHeight) / 2;
    }

    final scaleX = displayWidth / imgWidth;
    final scaleY = displayHeight / imgHeight;

    List<Widget> overlays = [];
    for (int i = 0; i < _ocrResults.length; i++) {
      final result = _ocrResults[i];
      final translatedText = i < _translatedTexts.length ? _translatedTexts[i] : result.text;

      overlays.add(
        Positioned(
          left: offsetX + (result.x * scaleX),
          top: offsetY + (result.y * scaleY),
          width: result.width * scaleX,
          height: result.height * scaleY,
          child: Container(
            color: result.backgroundColor,
            child: AutoSizeText(
              translatedText,
              style: TextStyle(
                color: result.overlayColor,
                backgroundColor: result.backgroundColor,
                fontSize: 100, // Large base size so it can scale down to fit perfectly
              ),
              minFontSize: 6,
              maxLines: 15,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }
    return overlays;
  }
}
