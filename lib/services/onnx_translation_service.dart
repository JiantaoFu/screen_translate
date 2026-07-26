import 'dart:async';
import 'dart:collection';
import 'dart:convert';
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
  /// If set, download this pair from "huggingface.co/<customRepo>/<key>/"
  /// instead of the default "huggingface.co/onnx-community/<key>/onnx/" —
  /// used for pairs we've converted and hosted ourselves (not available
  /// pre-converted on onnx-community). Files are expected flat (no "onnx/"
  /// subfolder) and always use the "_quantized" suffix.
  final String? customRepo;

  const OnnxLangPair({
    required this.key,
    required this.sourceBcp,
    required this.targetBcp,
    required this.displayName,
    this.useFp16 = false,
    this.customRepo,
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
  // ── Self-hosted (not on onnx-community) ─────────────────────────────────
  OnnxLangPair(
    key: 'opus-mt-ja-es',
    sourceBcp: 'ja',
    targetBcp: 'es',
    displayName: 'Japanese → Spanish',
    customRepo: 'fuji246/small-translation',
  ),
  // Also doubles as the second hop of the zh->es pivot below.
  OnnxLangPair(
    key: 'opus-mt-en-es',
    sourceBcp: 'en',
    targetBcp: 'es',
    displayName: 'English → Spanish',
    customRepo: 'fuji246/small-translation',
  ),
  OnnxLangPair(
    key: 'opus-mt-ja-pt',
    sourceBcp: 'ja',
    targetBcp: 'pt',
    displayName: 'Japanese → Portuguese',
    customRepo: 'fuji246/small-translation',
  ),
  // Also doubles as the second hop of the zh->pt pivot below. It's the
  // "tc-big" (larger) Transformer variant since no classic-sized en->pt
  // model exists.
  OnnxLangPair(
    key: 'opus-mt-tc-big-en-pt',
    sourceBcp: 'en',
    targetBcp: 'pt',
    displayName: 'English → Portuguese',
    customRepo: 'fuji246/small-translation',
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

// ─── Pivot pairs (chained translation via an intermediate language) ────────

/// A translation pair served by chaining two existing ONNX pairs through a
/// shared pivot language — used when no direct model exists for the
/// requested language pair (e.g. no usable zh→es model exists, but
/// zh→en and en→es do).
class OnnxPivotPair {
  final String sourceBcp;
  final String targetBcp;
  final String displayName;
  final String firstHopKey;
  final String secondHopKey;

  const OnnxPivotPair({
    required this.sourceBcp,
    required this.targetBcp,
    required this.displayName,
    required this.firstHopKey,
    required this.secondHopKey,
  });

  OnnxLangPair get firstHop =>
      kSupportedOnnxPairs.firstWhere((p) => p.key == firstHopKey);
  OnnxLangPair get secondHop =>
      kSupportedOnnxPairs.firstWhere((p) => p.key == secondHopKey);
}

const List<OnnxPivotPair> kSupportedOnnxPivotPairs = [
  OnnxPivotPair(
    sourceBcp: 'zh',
    targetBcp: 'es',
    displayName: 'Chinese → Spanish',
    firstHopKey: 'opus-mt-zh-en',
    secondHopKey: 'opus-mt-en-es',
  ),
  OnnxPivotPair(
    sourceBcp: 'zh',
    targetBcp: 'pt',
    displayName: 'Chinese → Portuguese',
    firstHopKey: 'opus-mt-zh-en',
    secondHopKey: 'opus-mt-tc-big-en-pt',
  ),
];

OnnxPivotPair? findOnnxPivotPair(String source, String target) {
  try {
    return kSupportedOnnxPivotPairs
        .firstWhere((p) => p.sourceBcp == source && p.targetBcp == target);
  } catch (_) {
    return null;
  }
}

// ─── Loaded model bundle ─────────────────────────────────────────────────────

class _OnnxModelBundle {
  final OrtSession encoder;
  final OrtSession decoder;
  final OrtSession decoderWithPast;

  /// Segments raw text into SentencePiece *pieces* (strings). Only used for
  /// tokenization of the source language — the resulting piece strings must
  /// still be mapped through [vocab] to get the model's actual token IDs.
  final SentencePieceTokenizer sourceTokenizer;

  /// Piece string -> model token ID. MarianMT models have a combined
  /// vocabulary (from `vocab.json`) that is DIFFERENT from — and usually much
  /// larger than — the internal piece IDs baked into `source.spm`/
  /// `target.spm`. Both encoding and decoding must go through this map.
  final Map<String, int> vocab;

  /// Inverse of [vocab], for decoding generated token IDs back to pieces.
  final Map<int, String> idToPiece;

  final int unkId;
  final int eosId;

  /// Also serves as the decoder's start token (Marian convention:
  /// decoder_start_token_id == pad_token_id). Varies per language pair —
  /// must never be hardcoded.
  final int padId;

  const _OnnxModelBundle({
    required this.encoder,
    required this.decoder,
    required this.decoderWithPast,
    required this.sourceTokenizer,
    required this.vocab,
    required this.idToPiece,
    required this.unkId,
    required this.eosId,
    required this.padId,
  });

  Future<void> dispose() async {
    await encoder.close();
    await decoder.close();
    await decoderWithPast.close();
  }
}

// ─── Constants ─────────────────────────────────────────────────────────────────

/// Floor/ceiling for the generation length cap — see [_maxNewTokensFor].
const int _kMaxNewTokensFloor = 64;
const int _kMaxNewTokensCeiling = 256;

/// Scales the generation cap with input length so long merged OCR blocks
/// don't get silently cut off mid-sentence, while keeping the tight 64-token
/// cap (fast decode) for the short single-line text screen-OCR usually
/// produces.
int _maxNewTokensFor(int inputTokenCount) {
  return (inputTokenCount * 3).clamp(_kMaxNewTokensFloor, _kMaxNewTokensCeiling);
}

/// Fraction of the source token count that must be generated before EOS is
/// allowed. Verified against the real ONNX model: pure greedy decoding will
/// otherwise sometimes jump straight to EOS after translating only the
/// "easy" tail of a longer/compound source sentence (e.g. "I am building X,
/// and looking for Y" translates only the "looking for Y" half), silently
/// dropping earlier clauses with no error or indication.
const double _kMinLengthFraction = 0.5;

int _minNewTokensFor(int inputTokenCount) {
  return (inputTokenCount * _kMinLengthFraction).ceil().clamp(1, 1 << 30);
}

// ─── Moses English pre-tokenizer ─────────────────────────────────────────────

/// Matches a URL so it can be protected from punctuation-splitting below.
final RegExp _kUrlPattern = RegExp(r'https?://\S+');

/// Trailing punctuation that commonly attaches to a URL in prose (e.g. the
/// comma in "see https://example.com, thanks") but isn't actually part of it.
const String _kUrlTrailingPunctuation = '.,;:!?)]}"\'';

/// Applies a subset of the Moses tokenizer rules that the opus-mt-en-zh model
/// was trained with.  Without this step, SentencePiece produces wrong token IDs
/// and the translation quality degrades significantly.
///
/// Rules implemented (matching sacremoses behaviour for English source):
///  - Separate punctuation from adjacent words with spaces
///  - Expand common English contractions (n't, 've, 're, 'll, 'm, 's, 'd)
///  - Collapse multiple spaces and strip leading/trailing whitespace
///
/// URLs are protected from the punctuation-splitting step. Verified against
/// the real ONNX model: splitting "https://example.com" into stray
/// "http", "s", ":", "/", "/" fragments produces an encoder input so far
/// outside the model's training distribution that it silently drops
/// unrelated nearby clauses from the translation entirely (not just mangles
/// the URL itself) -- this isn't cosmetic, it corrupts the whole sentence.
String _mosesTokenizeEnglish(String text) {
  // 1. Unicode normalise (collapse no-break spaces etc.)
  final normalized = text.replaceAll(' ', ' ').replaceAll('​', '');

  // 2. Split into URL / non-URL segments, applying punctuation-splitting and
  //    contraction expansion only to the non-URL parts.
  final buffer = StringBuffer();
  int lastEnd = 0;
  for (final match in _kUrlPattern.allMatches(normalized)) {
    buffer.write(_splitPunctuationAndContractions(normalized.substring(lastEnd, match.start)));

    // Strip trailing punctuation off the greedy \S+ URL match -- it belongs
    // to the surrounding sentence, not the URL -- then split it normally.
    var url = match.group(0)!;
    var trailing = '';
    while (url.isNotEmpty && _kUrlTrailingPunctuation.contains(url[url.length - 1])) {
      trailing = url[url.length - 1] + trailing;
      url = url.substring(0, url.length - 1);
    }
    buffer.write(' $url ');
    buffer.write(_splitPunctuationAndContractions(trailing));

    lastEnd = match.end;
  }
  buffer.write(_splitPunctuationAndContractions(normalized.substring(lastEnd)));

  // 3. Collapse runs of whitespace and trim
  return buffer.toString().replaceAll(RegExp(r' {2,}'), ' ').trim();
}

/// Punctuation-spacing + contraction-expansion rules, applied only to
/// non-URL segments of the source text -- see [_mosesTokenizeEnglish].
String _splitPunctuationAndContractions(String text) {
  // Separate punctuation with spaces (Moses rule: add space before & after)
  //    Handled characters: . , ! ? ; : ( ) [ ] { } " -
  //    We deliberately skip apostrophe here -- handled separately below.
  var s = text.replaceAllMapped(
    RegExp(r'([.,!?;:(\[\]{}"\-])'),
    (m) => ' ${m[0]} ',
  );

  // English contractions -- must come after punctuation separation so that
  // the apostrophe is still attached to the word.
  // Order matters: longer suffixes first.
  final contractions = [
    (RegExp(r"n't", caseSensitive: false), " n't"),
    (RegExp(r"'ve", caseSensitive: false), " 've"),
    (RegExp(r"'re", caseSensitive: false), " 're"),
    (RegExp(r"'ll", caseSensitive: false), " 'll"),
    (RegExp(r"'m",  caseSensitive: false), " 'm"),
    (RegExp(r"'s",  caseSensitive: false), " 's"),
    (RegExp(r"'d",  caseSensitive: false), " 'd"),
  ];
  for (final (pattern, replacement) in contractions) {
    s = s.replaceAll(pattern, replacement);
  }

  return s;
}

// ─── Marian language-prefix token IDs ────────────────────────────────────────────

/// Token IDs for the language-direction prefix that MarianMT models require.
///
/// opus-mt-en-zh is multilingual and uses a shared source+target vocabulary.
/// The tokenizer prepends a special token (e.g. `>>cmn_Hans<<`) as the FIRST
/// source token to tell the model which language to generate.
/// Without this prefix the model defaults to the most probable Chinese
/// token (ID 18 = "\u548c" = "和") and produces garbage.
///
/// Token IDs sourced from the vocab.json of onnx-community/opus-mt-en-zh.
/// key  ->  prefix-token-id  (null means no prefix needed)
const Map<String, int?> _kLangPrefixTokenId = {
  'opus-mt-en-zh': 5,   // >>cmn_Hans<< (token 5 in shared vocab)
};


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
      'vocab.json',
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

    // source.spm is used only for *segmentation* into pieces (strings); the
    // resulting pieces are then mapped through vocab.json below to get the
    // model's real token IDs — the .spm file's own internal piece IDs do NOT
    // match the ONNX model's embedding table and must never be used directly.
    final sourceTokenizer = SentencePieceTokenizer.fromModelFileSync(
      p.join(dir.path, 'source.spm'),
    );

    final vocabJson = jsonDecode(
      await File(p.join(dir.path, 'vocab.json')).readAsString(),
    ) as Map<String, dynamic>;
    final vocab = <String, int>{
      for (final entry in vocabJson.entries) entry.key: (entry.value as num).toInt(),
    };
    final idToPiece = <int, String>{
      for (final entry in vocab.entries) entry.value: entry.key,
    };
    final unkId = vocab['<unk>'] ?? 1;
    final eosId = vocab['</s>'] ?? 0;
    // Marian convention: decoder_start_token_id == pad_token_id. This differs
    // per language pair (vocab sizes range ~54k-65k) — never hardcode it.
    final padId = vocab['<pad>'] ?? (vocab.length - 1);

    final bundle = _OnnxModelBundle(
      encoder: encoder,
      decoder: decoder,
      decoderWithPast: decoderWithPast,
      sourceTokenizer: sourceTokenizer,
      vocab: vocab,
      idToPiece: idToPiece,
      unkId: unkId,
      eosId: eosId,
      padId: padId,
    );
    await _modelCache.put(langPairKey, bundle);
    debugPrint('OnnxTranslation: "$langPairKey" loaded.');
    return bundle;
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Translate [text] using a locally-stored ONNX MarianMT model.
  ///
  /// Falls back to a pivot pair (e.g. zh→en→es) when no direct model exists
  /// for the requested language pair — see [kSupportedOnnxPivotPairs].
  ///
  /// Throws [OnnxModelNotReadyException] when the model hasn't been downloaded.
  Future<String> translateText({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final pair = findOnnxPair(sourceLanguage, targetLanguage);
    if (pair == null) {
      final pivot = findOnnxPivotPair(sourceLanguage, targetLanguage);
      if (pivot == null) {
        throw UnsupportedError(
            'OnnxTranslation: No model for $sourceLanguage → $targetLanguage');
      }
      final intermediate = await translateText(
        text: text,
        sourceLanguage: pivot.firstHop.sourceBcp,
        targetLanguage: pivot.firstHop.targetBcp,
      );
      return translateText(
        text: intermediate,
        sourceLanguage: pivot.secondHop.sourceBcp,
        targetLanguage: pivot.secondHop.targetBcp,
      );
    }
    if (!await isModelReady(pair.key)) {
      throw OnnxModelNotReadyException(pair.key);
    }
    final bundle = await _loadModel(pair.key);
    // Look up the language-prefix token ID for this model pair (may be null).
    final langPrefixId = _kLangPrefixTokenId[pair.key];
    return _runInference(
        bundle: bundle, sourceText: text, langPrefixId: langPrefixId);
  }

  // ── Encoder-decoder loop ──────────────────────────────────────────────────

  static Future<String> _runInference({
    required _OnnxModelBundle bundle,
    required String sourceText,
    int? langPrefixId,
  }) async {
    final sw = Stopwatch()..start();
    debugPrint('[ONNX] Translating "$sourceText"');

    // ── 1. Tokenize source ────────────────────────────────────────────────────
    // Moses pre-tokenize first (sacremoses normalization for English)
    final preprocessed = _mosesTokenizeEnglish(sourceText);
    debugPrint('[ONNX] Moses pre-tokenized: "$preprocessed"');

    final pieces = bundle.sourceTokenizer.tokenize(preprocessed);
    debugPrint('[ONNX] SPM pieces (${pieces.length}): $pieces');
    if (pieces.isEmpty) return '';

    // Map pieces through the model's real vocab (vocab.json), NOT the
    // .spm file's internal piece IDs — those are different vocabularies.
    var inputIds = [for (final piece in pieces) bundle.vocab[piece] ?? bundle.unkId];

    // Prepend language-direction prefix if required (e.g. >>cmn_Hans<< = 5)
    if (langPrefixId != null) {
      inputIds = [langPrefixId, ...inputIds];
      debugPrint('[ONNX] With lang prefix $langPrefixId: $inputIds');
    }
    inputIds = [...inputIds, bundle.eosId];
    debugPrint('[ONNX] Vocab-mapped tokens: $inputIds');
    final attnMask = List<int>.filled(inputIds.length, 1);

    // Greedy decoding with no beam search will happily emit EOS after only
    // translating the "easy" tail of a longer/compound sentence, silently
    // dropping earlier clauses (verified: forcing a minimum length recovers
    // the dropped content without needing full beam search). Block EOS until
    // at least half the source length has been generated.
    final minNewTokens = _minNewTokensFor(inputIds.length);
    final maxNewTokens = _maxNewTokensFor(inputIds.length);

    final inputIdsTensor = await OrtValue.fromList(
        Int64List.fromList(inputIds), [1, inputIds.length]);
    final attnMaskTensor = await OrtValue.fromList(
        Int64List.fromList(attnMask), [1, attnMask.length]);
    final decStartTensor = await OrtValue.fromList(
        Int64List.fromList([bundle.padId]), [1, 1]);

    // All OrtValues that must be freed at the end
    final toRelease = <OrtValue>[inputIdsTensor, attnMaskTensor, decStartTensor];

    // ── 2. Encoder ────────────────────────────────────────────────────────────
    // Build inputs strictly from session.inputNames
    final encMap = <String, OrtValue>{};
    for (final name in bundle.encoder.inputNames) {
      if (name.contains('input_ids'))      encMap[name] = inputIdsTensor;
      else if (name.contains('attention_mask')) encMap[name] = attnMaskTensor;
    }
    final encOut = await bundle.encoder.run(
      encMap.isNotEmpty ? encMap : {'input_ids': inputIdsTensor, 'attention_mask': attnMaskTensor},
    );

    // The encoder's primary output is last_hidden_state (or the first output)
    final encHidden = encOut['last_hidden_state'] ??
        (encOut.isNotEmpty ? encOut.values.first : null);
    for (final v in encOut.values) {
      if (v != null && v != encHidden) toRelease.add(v);
    }
    if (encHidden != null) toRelease.add(encHidden);
    if (encHidden == null) {
      for (final v in toRelease) v.dispose();
      return '';
    }

    // ── 3. First decoder step ─────────────────────────────────────────────────
    // decoder_model inputs: input_ids, encoder_hidden_states, encoder_attention_mask
    final dec1Map = <String, OrtValue>{};
    for (final name in bundle.decoder.inputNames) {
      if (name == 'input_ids' || name.contains('input_ids')) {
        dec1Map[name] = decStartTensor;
      } else if (name.contains('hidden_states') || name.contains('encoder_hidden')) {
        dec1Map[name] = encHidden;
      } else if (name.contains('attention_mask')) {
        dec1Map[name] = attnMaskTensor;
      }
    }
    final firstOut = await bundle.decoder.run(
      dec1Map.isNotEmpty ? dec1Map : {
        'input_ids': decStartTensor,
        'encoder_hidden_states': encHidden,
        'encoder_attention_mask': attnMaskTensor,
      },
    );

    final logits0 = firstOut['logits'] ??
        (firstOut.isNotEmpty ? firstOut.values.first : null);
    if (logits0 == null) {
      for (final v in toRelease) v.dispose();
      for (final v in firstOut.values) { v?.dispose(); }
      return '';
    }

    final List<int> generated = [];
    final firstToken = await _argmaxLast(logits0, generated,
        eosId: bundle.eosId, padId: bundle.padId, minNewTokens: minNewTokens);
    generated.add(firstToken);
    debugPrint('[ONNX] Step 0 -> token $firstToken');

    // Extract past_key_values from first decoder output
    var pastKV = _renamePresentToPast(firstOut);
    for (final v in firstOut.values) {
      if (v != null && v != logits0 && !pastKV.containsValue(v)) toRelease.add(v);
    }
    toRelease.add(logits0);

    // ── 4. Autoregressive loop ────────────────────────────────────────────────
    // decoder_with_past inputs: input_ids, encoder_attention_mask, past_key_values.*
    // NOTE: decoder_with_past does NOT take encoder_hidden_states — those are
    //       already "baked into" the past encoder key/values.
    // Cap scales with input length: a fixed 64-token cap silently truncates
    // (no ellipsis, no error — it just stops) once the OCR merging step
    // glues multiple lines/bubbles into one longer source text.
    //
    // Also stop on padId: verified against the real opus-mt-id-en model that
    // it can start oscillating between a real word and the PAD token
    // mid-generation on very short/low-information inputs (e.g. a bare
    // "Halo" greeting) — PAD is never a legitimate generated token, and left
    // unchecked this loops all the way to maxNewTokens, producing a wall of
    // repeated garbage once PAD is stripped back out at decode time.
    for (int step = 1; step < maxNewTokens; step++) {
      if (generated.last == bundle.eosId || generated.last == bundle.padId) break;

      final stepTok = await OrtValue.fromList(
          Int64List.fromList([generated.last]), [1, 1]);

      // Build strictly from session.inputNames
      final stepMap = <String, OrtValue>{};
      for (final name in bundle.decoderWithPast.inputNames) {
        if (pastKV.containsKey(name)) {
          stepMap[name] = pastKV[name]!;
        } else if (name == 'input_ids' || name.contains('input_ids')) {
          stepMap[name] = stepTok;
        } else if (name.contains('attention_mask')) {
          // encoder_attention_mask — use the source attention mask
          stepMap[name] = attnMaskTensor;
        }
        // encoder_hidden_states is intentionally NOT passed to decoder_with_past
      }

      final stepOut = await bundle.decoderWithPast.run(
        stepMap.isNotEmpty ? stepMap : {
          'input_ids': stepTok,
          'encoder_attention_mask': attnMaskTensor,
          ...pastKV,
        },
      );

      final stepLogits = stepOut['logits'] ??
          (stepOut.isNotEmpty ? stepOut.values.first : null);
      if (stepLogits == null) {
        for (final v in stepOut.values) { v?.dispose(); }
        toRelease.add(stepTok);
        break;
      }

      final nextToken = await _argmaxLast(stepLogits, generated,
          eosId: bundle.eosId, padId: bundle.padId, minNewTokens: minNewTokens);
      generated.add(nextToken);
      debugPrint('[ONNX] Step $step -> token $nextToken');

      // Rotate past_key_values: new replaces old
      final newPastKV = _renamePresentToPast(stepOut);
      for (final key in pastKV.keys) {
        if (newPastKV.containsKey(key)) {
          pastKV[key]?.dispose(); // release old KV that was just replaced
        } else {
          newPastKV[key] = pastKV[key]!; // keep encoder KV (doesn't change)
        }
      }
      pastKV = newPastKV;

      toRelease.add(stepTok);
      toRelease.add(stepLogits);
      for (final v in stepOut.values) {
        if (v != null && v != stepLogits && !pastKV.containsValue(v)) {
          toRelease.add(v);
        }
      }
    }

    // ── 5. Release all tensors ─────────────────────────────────────────────────
    for (final v in toRelease) { v.dispose(); }
    for (final v in pastKV.values) { v.dispose(); }

    // ── 6. Decode output token IDs ─────────────────────────────────────────────
    // Map generated IDs back to pieces via vocab.json (inverse), NOT via a
    // target.spm-based tokenizer — same vocabulary mismatch as encoding.
    final specialIds = {bundle.eosId, bundle.padId, bundle.unkId};
    final cleanIds = generated.where((id) => !specialIds.contains(id)).toList();
    debugPrint('[ONNX] Generated ${generated.length} tokens, clean: $cleanIds');
    if (cleanIds.isEmpty) return '';
    final result = cleanIds
        .map((id) => bundle.idToPiece[id] ?? '')
        .join()
        .replaceAll('▁', ' ')
        .trim();
    debugPrint('[ONNX] Done in ${sw.elapsedMilliseconds}ms -> "$result"');
    return result;
  }

  /// Greedy argmax at the last token position of logits with repetition
  /// penalty.
  ///
  /// - EOS is suppressed until [minNewTokens] tokens have been generated —
  ///   without this, greedy decoding will happily jump straight to EOS after
  ///   translating only the "easy" tail of a longer/compound sentence,
  ///   silently dropping earlier clauses.
  /// - PAD is always excluded from candidates, not just treated as a stop
  ///   signal after the fact. Verified against the real opus-mt-ja-pt model:
  ///   its PAD logit can be the single highest-scoring candidate at the very
  ///   FIRST decode step (a quantization artifact), which — if only handled
  ///   as a post-hoc stop condition — produces an empty translation instead
  ///   of forcing the decoder toward the real next-best (actual) token.
  static Future<int> _argmaxLast(
    OrtValue logits,
    List<int> generated, {
    required int eosId,
    required int padId,
    required int minNewTokens,
  }) async {
    final rawData = await logits.asFlattenedList();
    final vocabSize = logits.shape[2];
    final offset = rawData.length - vocabSize;
    final generatedSet = generated.toSet();
    final suppressEos = generated.length < minNewTokens;

    int best = 0;
    double bestVal = double.negativeInfinity;

    for (int i = 0; i < vocabSize; i++) {
      if (i == padId) continue;
      if (i == eosId && suppressEos) continue;
      double val = (rawData[offset + i] as num).toDouble();
      // Apply repetition penalty (1.3) to prevent loops
      if (generatedSet.contains(i)) {
        val = val < 0 ? val * 1.3 : val / 1.3;
      }
      if (val > bestVal) { bestVal = val; best = i; }
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
