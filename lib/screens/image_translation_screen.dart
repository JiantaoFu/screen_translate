import 'dart:io';
import 'dart:math';
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

  /// Manual nudge per overlay box (by result index), for when the
  /// auto-placed position covers something the user wants to see — the
  /// live "Screen Translate" overlay already supports dragging a box out
  /// of the way; this brings the static "Translate Image" view to parity.
  final Map<int, Offset> _manualOffsets = {};

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

    // Pad each overlay slightly beyond the detected/merged bounding box —
    // OCR block boundaries are sometimes a few pixels tighter than the
    // actual glyph extents (e.g. a trailing character, or a name on its
    // own line just past the merged box), which otherwise "peeks out"
    // from behind the translated text. The padding is adaptive: on a
    // screen with tightly-packed blocks (chat bubbles, manga panels), a
    // flat padding on every box independently can make two neighboring
    // boxes intrude into each other even though their true (unpadded) text
    // regions don't overlap at all. Capping each box's padding to at most
    // half the real gap to its nearest vertical neighbor keeps boxes
    // exactly covering their own source text — never shifted away from it
    // — which matters because a translated overlay that moves off its
    // source position stops hiding the original text there, leaving the
    // untranslated original visible right next to its own translation.
    final baseBoxes = _ocrResults
        .map((r) => Rect.fromLTWH(r.x, r.y, r.width, r.height))
        .toList();

    final paddedBoxes = <Rect>[];
    for (int i = 0; i < _ocrResults.length; i++) {
      final result = _ocrResults[i];
      final base = baseBoxes[i];
      final desiredPad = result.height * 0.15;

      double padTop = desiredPad;
      double padBottom = desiredPad;
      for (int j = 0; j < baseBoxes.length; j++) {
        if (j == i) continue;
        final other = baseBoxes[j];
        final horizontalOverlap = base.left < other.right && base.right > other.left;
        if (!horizontalOverlap) continue;
        if (other.bottom <= base.top) {
          padTop = min(padTop, max(0.0, (base.top - other.bottom) / 2));
        } else if (other.top >= base.bottom) {
          padBottom = min(padBottom, max(0.0, (other.top - base.bottom) / 2));
        }
      }

      paddedBoxes.add(Rect.fromLTWH(
        base.left - desiredPad, base.top - padTop,
        base.width + desiredPad * 2, base.height + padTop + padBottom,
      ));
    }

    // Safety net for the rare case adaptive padding still leaves an
    // overlap (e.g. raw OCR boxes that themselves overlap slightly) —
    // should be a no-op in the common case since padding above is already
    // capped to the real gap between neighbors.
    final boxes = _resolveOverlaps(paddedBoxes);

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
            child: Container(
              // Container.clipBehavior only takes effect with a decoration —
              // color: alone takes a fast path (ColoredBox) that ignores it.
              decoration: BoxDecoration(color: result.backgroundColor),
              // Container does NOT clip its child by default — when
              // AutoSizeText hits minFontSize and still can't fit (routine
              // for translations much longer than the source), the text
              // renders past this box's edge and bleeds into whatever
              // overlay sits below it, undoing the overlap-avoidance layout
              // above even though the boxes themselves never touch.
              clipBehavior: Clip.hardEdge,
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
        ),
      );
    }
    return overlays;
  }

  /// Pushes boxes down (in image-space, reading order) just enough that
  /// none of them overlaps a box above/left of it that shares horizontal
  /// space. Processing top-to-bottom and always moving down (never up or
  /// sideways) guarantees zero overlaps as an invariant, at the cost of
  /// sometimes converting a side-by-side layout into a stacked one — a
  /// trade worth making, since the alternative is unreadable overlapping
  /// text.
  List<Rect> _resolveOverlaps(List<Rect> boxes) {
    final order = List<int>.generate(boxes.length, (i) => i)
      ..sort((a, b) {
        final byTop = boxes[a].top.compareTo(boxes[b].top);
        if (byTop != 0) return byTop;
        return boxes[a].left.compareTo(boxes[b].left);
      });

    final result = List<Rect>.from(boxes);
    final finalized = <int>[];

    for (final i in order) {
      var box = result[i];
      double minTop = box.top;
      for (final j in finalized) {
        final other = result[j];
        final horizontalOverlap = box.left < other.right && box.right > other.left;
        if (horizontalOverlap) {
          minTop = max(minTop, other.bottom);
        }
      }
      if (minTop != box.top) {
        box = Rect.fromLTWH(box.left, minTop, box.width, box.height);
        result[i] = box;
      }
      finalized.add(i);
    }

    return result;
  }
}
