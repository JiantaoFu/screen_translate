import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/overlay_layout.dart';
import '../widgets/fitted_translation_text.dart';
import '../models/ocr_result.dart';
import '../providers/translation_provider.dart';
import '../services/ocr_service.dart';
import 'package:screen_translate/l10n/app_localizations.dart';
import '../services/firebase_analytics_service.dart';
import '../lite/lite_gate.dart';
import '../lite/paywall_screen.dart';

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

  /// Manual nudge per overlay box (by result index), for when the
  /// auto-placed position covers something the user wants to see — the
  /// live "Screen Translate" overlay already supports dragging a box out
  /// of the way; this brings the static "Translate Image" view to parity.
  final Map<int, Offset> _manualOffsets = {};

  @override
  void initState() {
    super.initState();
    FirebaseAnalyticsService().trackScreenView('image_translation');
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
          mergeAggressiveness: translationProvider.mergeAggressiveness,
        );
      } else if (widget.imageFile != null) {
        debugPrint('[ImageTranslation] Processing image file via OCR: ${widget.imageFile!.path}');
        results = await ocrService.processFile(
          widget.imageFile!,
          translationProvider.currentOCRScript,
          mergeAggressiveness: translationProvider.mergeAggressiveness,
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

      // Lite: an image that produced text is one free translation; if it was
      // the last one, show the paywall now, over the result.
      final gate = LiteGate.instance;
      if (gate != null && results.isNotEmpty) {
        await gate.recordTranslationSuccess(kind: 'image');
        if (mounted && gate.takePendingPaywall()) {
          PaywallScreen.show(context, gate, trigger: 'limit_reached');
        }
      }
    } catch (e, stack) {
      debugPrint('[ImageTranslation] ERROR processing image: $e\n$stack');
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.error_prefix(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.image_translation_title),
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

    final boxes = computeOverlayBoxes(_ocrResults);

    List<Widget> overlays = [];
    for (int i = 0; i < _ocrResults.length; i++) {
      final result = _ocrResults[i];
      final translatedText = i < _translatedTexts.length ? _translatedTexts[i] : result.text;
      final box = boxes[i];

      overlays.add(
        Positioned(
          left: offsetX + (box.left * scaleX) + (_manualOffsets[i]?.dx ?? 0),
          top: offsetY + (box.top * scaleY) + (_manualOffsets[i]?.dy ?? 0),
          width: box.width * scaleX,
          height: box.height * scaleY,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // Lets the user nudge a box that's covering something they
            // want to see — matches the live "Screen Translate" overlay,
            // which already supports dragging. onPanUpdate wins the
            // gesture arena over the ancestor InteractiveViewer's pan/zoom
            // since it's the more specific (descendant) recognizer.
            onPanUpdate: (details) {
              setState(() {
                _manualOffsets[i] = (_manualOffsets[i] ?? Offset.zero) + details.delta;
              });
            },
            // Matches the live "Screen Translate" overlay's double-tap
            // expand — the box's own font can be scaled below a readable
            // size when a translation runs much longer than its source
            // line, so this is the escape hatch to actually read it.
            onDoubleTap: () => _showExpandedText(translatedText, result.isLight),
            child: Container(
              decoration: BoxDecoration(color: result.backgroundColor),
              clipBehavior: Clip.hardEdge,
              child: FittedTranslationText(
                text: translatedText,
                color: result.overlayColor,
              ),
            ),
          ),
        ),
      );
    }
    return overlays;
  }

  /// Full-text popup for a box whose translation got scaled down to (or
  /// past) legibility — mirrors OverlayService.kt's showExpandedTextDialog
  /// on the live overlay: dimmed background, tap-outside to dismiss,
  /// selectable text, capped height with its own scroll so a very long
  /// translation doesn't overflow the screen.
  void _showExpandedText(String text, bool isLight) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (dialogContext) => Dialog(
        backgroundColor: isLight ? Colors.grey[800] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(dialogContext).size.height * 0.7,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      text,
                      style: TextStyle(
                        fontSize: 22,
                        color: isLight ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tap outside to close',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
