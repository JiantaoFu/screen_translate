import 'dart:typed_data';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'firebase_remote_config_service.dart';

/// Metadata about a sampled OCR image for analysis
class SampleMetadata {
  final String sampleId;
  final DateTime timestamp;
  final int imageWidth;
  final int imageHeight;
  final int detectedTextBlocks;
  final String detectedScript;
  final double processingTimeMs;
  final String? deviceId;
  final String? osVersion;
  final double? devicePixelRatio;
  final List<TextBlockMetadata> textBlocks;
  final String? cloudinaryUrl;

  SampleMetadata({
    required this.sampleId,
    required this.timestamp,
    required this.imageWidth,
    required this.imageHeight,
    required this.detectedTextBlocks,
    required this.detectedScript,
    required this.processingTimeMs,
    this.deviceId,
    this.osVersion,
    this.devicePixelRatio,
    required this.textBlocks,
    this.cloudinaryUrl,
  });

  Map<String, dynamic> toJson() => {
    'sampleId': sampleId,
    'timestamp': timestamp.toIso8601String(),
    'imageWidth': imageWidth,
    'imageHeight': imageHeight,
    'detectedTextBlocks': detectedTextBlocks,
    'detectedScript': detectedScript,
    'processingTimeMs': processingTimeMs,
    'deviceId': deviceId,
    'osVersion': osVersion,
    'devicePixelRatio': devicePixelRatio,
    'textBlocks': textBlocks.map((b) => b.toJson()).toList(),
    'cloudinaryUrl': cloudinaryUrl,
  };
}

class TextBlockMetadata {
  final String text;
  final double x;
  final double y;
  final double width;
  final double height;
  final int textLength;
  final double? confidence;

  TextBlockMetadata({
    required this.text,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.textLength,
    this.confidence,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'textLength': textLength,
    'confidence': confidence,
  };
}

class OCRSamplingService {
  static final OCRSamplingService _instance = OCRSamplingService._internal();
  final Logger _logger = Logger('OCRSamplingService');

  late String _cloudinaryCloudName;
  late String _cloudinaryUploadPreset;
  bool _isInitialized = false;

  factory OCRSamplingService() {
    return _instance;
  }

  OCRSamplingService._internal();

  /// Initialize with Cloudinary credentials
  Future<void> init({
    required String cloudinaryCloudName,
    required String cloudinaryUploadPreset,
  }) async {
    _cloudinaryCloudName = cloudinaryCloudName;
    _cloudinaryUploadPreset = cloudinaryUploadPreset;
    _isInitialized = true;
    _logger.info('OCR Sampling Service initialized');
  }

  /// Determine if this image should be sampled based on sampling rate
  bool shouldSample() {
    final remoteConfig = FirebaseRemoteConfigService();
    final samplingRate = remoteConfig.getOcrSamplingRate();
    final rand = Random().nextDouble();
    return rand < samplingRate;
  }

  /// Compress NV21 image to JPEG bytes with quality optimization
  Uint8List compressImageToJPEG(
    Uint8List nv21Bytes,
    int width,
    int height, {
    int quality = 60,
  }) {
    try {
      _logger.info('Compressing NV21 to JPEG: ${width}x${height}, quality=$quality');

      final image = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final yIndex = y * width + x;
          final uvIndex = width * height + (y >> 1) * width + (x & ~1);

          final yComponent = nv21Bytes[yIndex] & 0xFF;
          final uComponent = nv21Bytes[uvIndex] & 0xFF;
          final vComponent = nv21Bytes[uvIndex + 1] & 0xFF;

          final c = yComponent - 16;
          final d = uComponent - 128;
          final e = vComponent - 128;

          final r = (298 * c + 409 * e + 128) >> 8;
          final g = (298 * c - 100 * d - 208 * e + 128) >> 8;
          final b = (298 * c + 516 * d + 128) >> 8;

          image.setPixelRgb(
            x,
            y,
            r.clamp(0, 255),
            g.clamp(0, 255),
            b.clamp(0, 255),
          );
        }
      }

      final jpegBytes = img.encodeJpg(image, quality: quality);
      _logger.info('Compressed to JPEG: ${jpegBytes.length} bytes');

      return Uint8List.fromList(jpegBytes);
    } catch (e, stackTrace) {
      _logger.severe('Error compressing image to JPEG', e, stackTrace);
      return Uint8List(0);
    }
  }

  /// Upload JPEG to Cloudinary with metadata
  Future<String?> uploadToCloudinary(
    Uint8List jpegBytes,
    String sampleId,
    SampleMetadata metadata,
  ) async {
    if (!_isInitialized) {
      _logger.warning('Sampling service not initialized');
      return null;
    }

    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload'
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _cloudinaryUploadPreset
        ..fields['public_id'] = sampleId
        ..fields['tags'] = 'ocr_sample,screen_translate';

      if (metadata.deviceId != null && metadata.deviceId!.isNotEmpty) {
        request.fields['asset_folder'] = 'screen_translation/${metadata.deviceId}';
      }

      request
        ..fields['context'] = [
          'textBlocks=${metadata.detectedTextBlocks}',
          'script=${metadata.detectedScript.replaceAll('=', r'\=').replaceAll('|', r'\|')}',
          'processingTimeMs=${metadata.processingTimeMs}',
        ].join('|')
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            jpegBytes,
            filename: '$sampleId.jpg',
          ),
        );

      _logger.info('Uploading sample to Cloudinary: $sampleId');
      final response = await request.send().timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final jsonResponse = jsonDecode(utf8.decode(responseData));
        final cloudinaryUrl = jsonResponse['secure_url'];
        _logger.info('Sample uploaded successfully: $cloudinaryUrl');
        return cloudinaryUrl;
      } else {
        _logger.severe('Upload failed with status ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      _logger.severe('Error uploading to Cloudinary', e, stackTrace);
      return null;
    }
  }

  /// Complete sampling pipeline: compress, upload, and return metadata
  Future<SampleMetadata?> captureSample({
    required Uint8List nv21Bytes,
    required int width,
    required int height,
    required int detectedTextBlocks,
    required String detectedScript,
    required double processingTimeMs,
    required List<TextBlockMetadata> textBlocks,
    String? deviceId,
    String? osVersion,
    double? devicePixelRatio,
    int jpegQuality = 60,
  }) async {
    try {
      final sampleId = 'sample_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';

      final jpegBytes = compressImageToJPEG(
        nv21Bytes,
        width,
        height,
        quality: jpegQuality,
      );

      if (jpegBytes.isEmpty) {
        _logger.warning('Compression failed, skipping sample');
        return null;
      }

      final metadata = SampleMetadata(
        sampleId: sampleId,
        timestamp: DateTime.now(),
        imageWidth: width,
        imageHeight: height,
        detectedTextBlocks: detectedTextBlocks,
        detectedScript: detectedScript,
        processingTimeMs: processingTimeMs,
        deviceId: deviceId,
        osVersion: osVersion,
        devicePixelRatio: devicePixelRatio,
        textBlocks: textBlocks,
      );

      final cloudinaryUrl = await uploadToCloudinary(jpegBytes, sampleId, metadata);

      final metadataWithUrl = SampleMetadata(
        sampleId: sampleId,
        timestamp: metadata.timestamp,
        imageWidth: metadata.imageWidth,
        imageHeight: metadata.imageHeight,
        detectedTextBlocks: metadata.detectedTextBlocks,
        detectedScript: metadata.detectedScript,
        processingTimeMs: metadata.processingTimeMs,
        deviceId: metadata.deviceId,
        osVersion: metadata.osVersion,
        devicePixelRatio: metadata.devicePixelRatio,
        textBlocks: metadata.textBlocks,
        cloudinaryUrl: cloudinaryUrl,
      );

      _logger.info('Sample capture complete: $sampleId');
      return metadataWithUrl;
    } catch (e, stackTrace) {
      _logger.severe('Error in sample capture pipeline', e, stackTrace);
      return null;
    }
  }
}
