import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:dart_sentencepiece_tokenizer/dart_sentencepiece_tokenizer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// ─── Language pair metadata ──────────────────────────────────────────────────

/// Supported OPUS-MT language pairs for on-device ONNX inference.
///
/// Keys follow the HuggingFace model name convention (without the
/// "Helsinki-NLP/" prefix) and match the ZIP filename on the download server.
class OnnxLangPair {
  final String key;
  final String sourceBcp;
  final String targetBcp;
  final String displayName;
  /// If true, download fp16 ONNX files instead of quantized (for models that
  /// don't have a _quantized variant on onnx-community).
  final bool useFp16;

  const OnnxLangPair({
    required this.key,
    required this.sourceBcp,
    required this.targetBcp,
    required this.displayName,
    this.useFp16 = false,
  });

  @override
  bool operator ==(Object other) =>
      other is OnnxLangPair && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

const List<OnnxLangPair> kSupportedOnnxPairs = [
  // ── CJK ──────────────────────────────────────────────────────────────────
  OnnxLangPair(
    key: 'opus-mt-en-zh',
    sourceBcp: 'en',
    targetBcp: 'zh',
    displayName: 'English → Chinese',
  ),
  OnnxLangPair(
    key: 'opus-mt-zh-en',
    sourceBcp: 'zh',
    targetBcp: 'en',
    displayName: 'Chinese → English',
  ),
  OnnxLangPair(
    key: 'opus-mt-ja-en',
    sourceBcp: 'ja',
    targetBcp: 'en',
    displayName: 'Japanese → English',
  ),
  OnnxLangPair(
    key: 'opus-mt-ko-en',
    sourceBcp: 'ko',
    targetBcp: 'en',
    displayName: 'Korean → English',
    useFp16: true, // onnx-community only has fp16 for this pair
  ),
  // ── Southeast Asia ───────────────────────────────────────────────────────
  OnnxLangPair(
    key: 'opus-mt-th-en',
    sourceBcp: 'th',
    targetBcp: 'en',
    displayName: 'Thai → English',
    useFp16: true,
  ),
  OnnxLangPair(
    key: 'opus-mt-vi-en',
    sourceBcp: 'vi',
    targetBcp: 'en',
    displayName: 'Vietnamese → English',
  ),
  OnnxLangPair(
    key: 'opus-mt-id-en',
    sourceBcp: 'id',
    targetBcp: 'en',
    displayName: 'Indonesian → English',
    useFp16: true,
  ),
  // ── Europe ───────────────────────────────────────────────────────────────
  OnnxLangPair(
    key: 'opus-mt-de-en',
    sourceBcp: 'de',
    targetBcp: 'en',
    displayName: 'German → English',
  ),
  OnnxLangPair(
    key: 'opus-mt-es-en',
    sourceBcp: 'es',
    targetBcp: 'en',
    displayName: 'Spanish → English',
  ),
  OnnxLangPair(
    key: 'opus-mt-fr-en',
    sourceBcp: 'fr',
    targetBcp: 'en',
    displayName: 'French → English',
  ),
  OnnxLangPair(
    key: 'opus-mt-ru-en',
    sourceBcp: 'ru',
    targetBcp: 'en',
    displayName: 'Russian → English',
  ),
];

OnnxLangPair? findOnnxPair(String source, String target) {
  try {
    return kSupportedOnnxPairs
        .firstWhere((pair) => pair.sourceBcp == source && pair.targetBcp == target);
  } catch (_) {
    return null;
  }
}

// ─── Loaded model bundle ─────────────────────────────────────────────────────

class _OnnxModelBundle {
  final OrtSession encoder;
  final OrtSession decoder;
  final OrtSession decoderWithPast;
  final SentencePieceTokenizer sourceTokenizer;
  final SentencePieceTokenizer targetTokenizer;

  const _OnnxModelBundle({
    required this.encoder,
    required this.decoder,
    required this.decoderWithPast,
    required this.sourceTokenizer,
    required this.targetTokenizer,
  });

  Future<void> dispose() async {
    await encoder.close();
    await decoder.close();
    await decoderWithPast.close();
  }
}

// ─── Constants ─────────────────────────────────────────────────────────────────

const int _kMaxNewTokens = 128;
const int _kEosTokenId = 0;
const int _kDecoderStartTokenId = 65000;

// ─── LRU cache ──────────────────────────────────────────────────────────────

class _ModelLRUCache {
  final int maxSize;
  final _map = LinkedHashMap<String, _OnnxModelBundle>();

  _ModelLRUCache(this.maxSize);

  _OnnxModelBundle? get(String key) {
    if (!_map.containsKey(key)) return null;
    final value = _map.remove(key)!;
    _map[key] = value;
    return value;
  }

  Future<void> put(String key, _OnnxModelBundle bundle) async {
    if (_map.containsKey(key)) {
      await _map.remove(key)!.dispose();
    } else if (_map.length >= maxSize) {
      final oldest = _map.keys.first;
      await _map.remove(oldest)!.dispose();
      debugPrint('OnnxTranslation: Evicted "$oldest" from cache');
    }
    _map[key] = bundle;
  }

  Future<void> clear() async {
    for (final bundle in _map.values) {
      await bundle.dispose();
    }
    _map.clear();
  }
}

// ─── Main service ─────────────────────────────────────────────────────────────

class OnnxTranslationService {
  final _modelCache = _ModelLRUCache(2);

  Future<Directory> _modelDir(String langPairKey) async {
    final appSupport = await getApplicationSupportDirectory();
    return Directory(p.join(appSupport.path, 'onnx_models', langPairKey));
  }

  /// Returns true when all required model files are present on disk.
  Future<bool> isModelReady(String langPairKey) async {
    final dir = await _modelDir(langPairKey);
    if (!await dir.exists()) return false;
    const required = [
      'encoder_model.onnx',
      'decoder_model.onnx',
      'decoder_with_past_model.onnx',
      'source.spm',
      'target.spm',
    ];
    for (final f in required) {
      if (!await File(p.join(dir.path, f)).exists()) return false;
    }
    return true;
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  Future<_OnnxModelBundle> _loadModel(String langPairKey) async {
    final cached = _modelCache.get(langPairKey);
    if (cached != null) return cached;

    debugPrint('OnnxTranslation: Loading "$langPairKey"...');
    final dir = await _modelDir(langPairKey);
    final ort = OnnxRuntime();

    // createSession(path) is the correct API for file-system paths
    final encoder = await ort.createSession(
      p.join(dir.path, 'encoder_model.onnx'),
    );
    final decoder = await ort.createSession(
      p.join(dir.path, 'decoder_model.onnx'),
    );
    final decoderWithPast = await ort.createSession(
      p.join(dir.path, 'decoder_with_past_model.onnx'),
    );

    // MarianMT uses Unigram algorithm, no BOS, with EOS appended to source
    const srcConfig = SentencePieceConfig(addBosToken: false, addEosToken: true);
    const tgtConfig = SentencePieceConfig(addBosToken: false, addEosToken: false);

    final sourceTokenizer = SentencePieceTokenizer.fromModelFileSync(
      p.join(dir.path, 'source.spm'),
      config: srcConfig,
    );
    final targetTokenizer = SentencePieceTokenizer.fromModelFileSync(
      p.join(dir.path, 'target.spm'),
      config: tgtConfig,
    );

    final bundle = _OnnxModelBundle(
      encoder: encoder,
      decoder: decoder,
      decoderWithPast: decoderWithPast,
      sourceTokenizer: sourceTokenizer,
      targetTokenizer: targetTokenizer,
    );
    await _modelCache.put(langPairKey, bundle);
    debugPrint('OnnxTranslation: "$langPairKey" loaded.');
    return bundle;
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Translate [text] using a locally-stored ONNX MarianMT model.
  ///
  /// Throws [OnnxModelNotReadyException] when the model hasn't been downloaded.
  Future<String> translateText({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final pair = findOnnxPair(sourceLanguage, targetLanguage);
    if (pair == null) {
      throw UnsupportedError(
          'OnnxTranslation: No model for $sourceLanguage → $targetLanguage');
    }
    if (!await isModelReady(pair.key)) {
      throw OnnxModelNotReadyException(pair.key);
    }
    final bundle = await _loadModel(pair.key);
    // Cannot use Isolate.run because OrtSession contains native pointers
    // that cannot be sent across isolate boundaries.
    return _runInference(bundle: bundle, sourceText: text);
  }

  // ── Encoder-decoder loop ──────────────────────────────────────────────────

  static Map<String, OrtValue> _buildInputs({
    required OrtSession session,
    required OrtValue inputIds,
    required OrtValue attentionMask,
    OrtValue? encHidden,
    Map<String, OrtValue> pastKV = const {},
  }) {
    final map = <String, OrtValue>{};
    for (final name in session.inputNames) {
      if (pastKV.containsKey(name)) {
        map[name] = pastKV[name]!;
      } else if (name.contains('input_ids')) {
        map[name] = inputIds;
      } else if (name.contains('hidden_states') || name.contains('encoder_hidden')) {
        if (encHidden != null) map[name] = encHidden;
      } else if (name.contains('attention_mask')) {
        map[name] = attentionMask;
      }
    }
    return map;
  }

  static Future<String> _runInference({
    required _OnnxModelBundle bundle,
    required String sourceText,
  }) async {
    final sw = Stopwatch()..start();
    debugPrint('[ONNX] Translating "$sourceText"');

    // 1. Tokenize (EOS appended by srcConfig)
    final encoding = bundle.sourceTokenizer.encode(sourceText);
    final inputIds = encoding.ids.toList();
    debugPrint('[ONNX] Tokenized input (${inputIds.length} tokens): $inputIds');
    if (inputIds.isEmpty) return '';
    final attentionMask = List<int>.filled(inputIds.length, 1);

    final inputIdsTensor = await OrtValue.fromList(
        Int64List.fromList(inputIds), [1, inputIds.length]);
    final attentionMaskTensor = await OrtValue.fromList(
        Int64List.fromList(attentionMask), [1, attentionMask.length]);
    final initialDecoderTokenTensor = await OrtValue.fromList(
        Int64List.fromList([_kDecoderStartTokenId]), [1, 1]);

    final resourcesToRelease = <OrtValue>[
      inputIdsTensor,
      attentionMaskTensor,
      initialDecoderTokenTensor,
    ];

    // 2. Encoder (single pass)
    final encInputs = _buildInputs(
      session: bundle.encoder,
      inputIds: inputIdsTensor,
      attentionMask: attentionMaskTensor,
    );
    final encOut = await bundle.encoder.run(encInputs.isNotEmpty ? encInputs : {
      'input_ids': inputIdsTensor,
      'attention_mask': attentionMaskTensor,
    });
    final encHidden = encOut['last_hidden_state'] ??
        (encOut.isNotEmpty ? encOut.values.first : null);
        
    for (final v in encOut.values) {
      if (v != null && v != encHidden) resourcesToRelease.add(v);
    }
    if (encHidden != null) resourcesToRelease.add(encHidden);

    // 3. First decoder step
    final List<int> generated = [];
    final firstInputs = _buildInputs(
      session: bundle.decoder,
      inputIds: initialDecoderTokenTensor,
      attentionMask: attentionMaskTensor,
      encHidden: encHidden,
    );
    final firstOut = await bundle.decoder.run(firstInputs.isNotEmpty ? firstInputs : {
      'input_ids': initialDecoderTokenTensor,
      if (encHidden != null) 'encoder_hidden_states': encHidden,
      'encoder_attention_mask': attentionMaskTensor,
    });

    final logits = firstOut['logits'] ??
        (firstOut.isNotEmpty ? firstOut.values.first : null);

    if (logits != null) {
      final firstToken = await _argmaxLast(logits, generated);
      generated.add(firstToken);
      debugPrint('[ONNX] Decoder Step 0 -> Token: $firstToken');
    }
    
    var pastKV = _renamePresentToPast(firstOut);
    
    for (final v in firstOut.values) {
      if (v != null && v != logits && !pastKV.containsValue(v)) {
        resourcesToRelease.add(v);
      }
    }
    if (logits != null) resourcesToRelease.add(logits);
    
    if (logits == null) {
      for (final v in resourcesToRelease) { v.dispose(); }
      for (final v in pastKV.values) { v.dispose(); }
      return '';
    }

    // 4. Autoregressive decode loop
    for (int step = 1; step < _kMaxNewTokens; step++) {
      if (generated.last == _kEosTokenId) break;

      final stepTokenTensor = await OrtValue.fromList(
          Int64List.fromList([generated.last]), [1, 1]);
      final stepInputs = _buildInputs(
        session: bundle.decoderWithPast,
        inputIds: stepTokenTensor,
        attentionMask: attentionMaskTensor,
        encHidden: encHidden,
        pastKV: pastKV,
      );

      final stepOut = await bundle.decoderWithPast.run(stepInputs.isNotEmpty ? stepInputs : {
        'input_ids': stepTokenTensor,
        if (encHidden != null) 'encoder_hidden_states': encHidden,
        'encoder_attention_mask': attentionMaskTensor,
        ...pastKV,
      });

      final stepLogits = stepOut['logits'] ??
          (stepOut.isNotEmpty ? stepOut.values.first : null);
      if (stepLogits == null) {
        for (final v in stepOut.values) { if (v != null) v.dispose(); }
        break;
      }

      final nextToken = await _argmaxLast(stepLogits, generated);
      generated.add(nextToken);
      debugPrint('[ONNX] Decoder Step $step -> Token: $nextToken');
      
      final newPastKV = _renamePresentToPast(stepOut);
      final oldPastKV = pastKV;
      
      for (final key in oldPastKV.keys) {
        if (!newPastKV.containsKey(key)) {
          newPastKV[key] = oldPastKV[key]!;
        } else {
          // Release the old decoder past key value that is being replaced
          oldPastKV[key]?.dispose();
        }
      }
      pastKV = newPastKV;
      
      // Cleanup intermediate step tensors
      resourcesToRelease.add(stepTokenTensor);
      resourcesToRelease.add(stepLogits);
      for (final v in stepOut.values) {
        if (v != null && v != stepLogits && !pastKV.containsValue(v)) {
          resourcesToRelease.add(v);
        }
      }
    }

    // Release all accumulated resources
    for (final v in resourcesToRelease) { v.dispose(); }
    for (final v in pastKV.values) { v.dispose(); }

    // 5. Decode output tokens
    final cleanIds = generated.where((id) => id != _kEosTokenId).toList();
    debugPrint('[ONNX] Generated ${generated.length} tokens. Clean IDs (${cleanIds.length}): $cleanIds');
    if (cleanIds.isEmpty) return '';
    final result = bundle.targetTokenizer
        .decode(cleanIds, skipSpecialTokens: true)
        .trim();
    debugPrint('[ONNX] Inference finished in ${sw.elapsedMilliseconds}ms -> Result: "$result"');
    return result;
  }

  /// Greedy argmax at the last token position of logits with repetition penalty.
  static Future<int> _argmaxLast(OrtValue logits, List<int> generated) async {
    final rawData = await logits.asFlattenedList();
    final vocabSize = logits.shape[2];
    final offset = rawData.length - vocabSize;
    final generatedSet = generated.toSet();

    int best = 0;
    double bestVal = double.negativeInfinity;

    for (int i = 0; i < vocabSize; i++) {
      double val = (rawData[offset + i] as num).toDouble();
      
      // Apply repetition penalty (1.25) to prevent loops like "和与和与"
      if (generatedSet.contains(i)) {
        if (val < 0) {
          val *= 1.25;
        } else {
          val /= 1.25;
        }
      }

      if (val > bestVal) {
        bestVal = val;
        best = i;
      }
    }
    return best;
  }

  /// Renames "present.X" → "past_key_values.X" for decoder_with_past.
  static Map<String, OrtValue> _renamePresentToPast(
      Map<String, OrtValue?> outputs) {
    return {
      for (final entry in outputs.entries)
        if (entry.key.startsWith('present.') && entry.value != null)
          entry.key.replaceFirst('present.', 'past_key_values.'): entry.value!,
    };
  }

  Future<void> dispose() async {
    await _modelCache.clear();
  }
}

// ─── Exception ────────────────────────────────────────────────────────────────

class OnnxModelNotReadyException implements Exception {
  final String langPairKey;
  const OnnxModelNotReadyException(this.langPairKey);

  @override
  String toString() =>
      'OnnxModelNotReadyException: Model "$langPairKey" is not downloaded yet.';
}
