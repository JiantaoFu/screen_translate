import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'download_retry.dart';

/// A grayscale image: one byte per pixel, row-major.
class LumaImage {
  final int width;
  final int height;
  final Uint8List luma;
  const LumaImage(this.width, this.height, this.luma);
}

/// Reads text lines again with a recognizer for a script ML Kit lacks.
///
/// ML Kit's on-device recognizers cover Latin, Chinese, Devanagari,
/// Japanese and Korean only. Text in another script still comes back from
/// the Latin one with correct line boxes but garbled text (Cyrillic
/// "Привет" as "Npnbet"), which the source-language filter then dropped,
/// so Russian, Ukrainian... translated nothing at all. The boxes are kept
/// and each line is read again by a model for that script.
abstract class LineRereader {
  /// One text per rect in [lines] (same order); empty where nothing was read.
  Future<List<String>> reread(LumaImage image, List<Rect> lines);
}

/// PaddleOCR's PP-OCRv5 East Slavic line recognizer (Russian, Ukrainian,
/// Belarusian; Apache-2.0), converted to ONNX with an ArgMax appended so
/// it returns character ids. Downloaded on demand (about 8 MB).
class CyrillicLineRecognizer implements LineRereader {
  CyrillicLineRecognizer._();
  static final CyrillicLineRecognizer instance = CyrillicLineRecognizer._();

  static const Set<String> languages = {'ru', 'uk', 'be'};
  static bool supports(String languageCode) => languages.contains(languageCode);

  static const _baseUrl =
      'https://huggingface.co/fuji246/small-translation/resolve/main/ocr-eslav';
  static const _files = ['rec.onnx', 'dict.txt'];

  static const int _height = 48;
  static const int _maxWidth = 1600;
  static const int _batch = 8;

  OrtSession? _session;
  List<String>? _dict;
  Future<void>? _download;
  Future<void>? _loading;

  Future<Directory> _dir() async {
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, 'ocr_models', 'eslav'));
  }

  Future<bool> isDownloaded() async {
    final dir = await _dir();
    for (final f in _files) {
      if (!await File(p.join(dir.path, f)).exists()) return false;
    }
    return true;
  }

  /// Downloads the model if needed; concurrent callers share one download.
  Future<void> ensureDownloaded() {
    return _download ??= () async {
      try {
        if (await isDownloaded()) return;
        final dir = await _dir();
        await dir.create(recursive: true);
        final client = http.Client();
        try {
          // Each file only appears once complete (resumableDownload writes
          // to a .tmp first), and isDownloaded needs both.
          for (final f in _files) {
            await resumableDownload(
                client: client, url: '$_baseUrl/$f', target: File(p.join(dir.path, f)));
          }
        } finally {
          client.close();
        }
      } catch (e) {
        _download = null; // let a later call retry
        rethrow;
      }
    }();
  }

  Future<void> _load() {
    return _loading ??= () async {
      try {
        final dir = await _dir();
        _dict = await File(p.join(dir.path, 'dict.txt')).readAsLines();
        _session = await OnnxRuntime().createSession(
          p.join(dir.path, 'rec.onnx'),
          options: OrtSessionOptions(providers: [OrtProvider.XNNPACK, OrtProvider.CPU]),
        );
      } catch (e) {
        _loading = null;
        rethrow;
      }
    }();
  }

  @override
  Future<List<String>> reread(LumaImage image, List<Rect> lines) async {
    if (lines.isEmpty) return const [];
    await _load();
    final session = _session!;
    final dict = _dict!;
    final crops = [for (final r in lines) cropLine(image, r)];
    final out = List<String>.filled(lines.length, '');
    // Similar widths together, so a batch pads little.
    final order = List<int>.generate(lines.length, (i) => i)
      ..sort((a, b) => crops[a].width.compareTo(crops[b].width));
    for (var s = 0; s < order.length; s += _batch) {
      final idx = order.sublist(s, min(s + _batch, order.length));
      final width = idx.map((i) => crops[i].width).reduce(max);
      final input = batchTensor([for (final i in idx) crops[i]], width);
      final tensor = await OrtValue.fromList(input, [idx.length, 3, _height, width]);
      Map<String, OrtValue>? result;
      try {
        result = await session.run({session.inputNames.first: tensor});
        final ids = (await result.values.first.asFlattenedList()).cast<int>();
        final steps = ids.length ~/ idx.length;
        for (var k = 0; k < idx.length; k++) {
          out[idx[k]] = ctcDecode(ids.sublist(k * steps, (k + 1) * steps), dict);
        }
      } finally {
        await tensor.dispose();
        for (final v in result?.values ?? const <OrtValue>[]) {
          await v.dispose();
        }
      }
    }
    return out;
  }

  /// [line] cut out with a margin (ML Kit's boxes hug the glyphs; the model
  /// was trained on looser crops) and scaled to the model's height.
  @visibleForTesting
  static LumaImage cropLine(LumaImage image, Rect line) {
    final h = line.height;
    final left = max(0, (line.left - h * 0.25).floor());
    final right = min(image.width, (line.right + h * 0.25).ceil());
    final top = max(0, (line.top - h * 0.15).floor());
    final bottom = min(image.height, (line.bottom + h * 0.15).ceil());
    final cw = max(1, right - left);
    final ch = max(1, bottom - top);
    final outW = (cw * _height / ch).round().clamp(16, _maxWidth);
    final out = Uint8List(outW * _height);
    final sx = cw / outW;
    final sy = ch / _height;
    for (var y = 0; y < _height; y++) {
      final fy = (top + (y + 0.5) * sy - 0.5).clamp(0.0, image.height - 1.0);
      final y0 = fy.floor();
      final y1 = min(y0 + 1, image.height - 1);
      final wy = fy - y0;
      for (var x = 0; x < outW; x++) {
        final fx = (left + (x + 0.5) * sx - 0.5).clamp(0.0, image.width - 1.0);
        final x0 = fx.floor();
        final x1 = min(x0 + 1, image.width - 1);
        final wx = fx - x0;
        final a = image.luma[y0 * image.width + x0];
        final b = image.luma[y0 * image.width + x1];
        final c = image.luma[y1 * image.width + x0];
        final d = image.luma[y1 * image.width + x1];
        final top = a + (b - a) * wx;
        final bot = c + (d - c) * wx;
        out[y * outW + x] = (top + (bot - top) * wy).round();
      }
    }
    return LumaImage(outW, _height, out);
  }

  /// [N, 3, 48, width] floats, normalized to [-1, 1] as in training; gray
  /// in all three channels; zero (mid-gray) padding on the right.
  @visibleForTesting
  static Float32List batchTensor(List<LumaImage> crops, int width) {
    final plane = _height * width;
    final data = Float32List(crops.length * 3 * plane);
    for (var n = 0; n < crops.length; n++) {
      final c = crops[n];
      for (var y = 0; y < _height; y++) {
        for (var x = 0; x < c.width; x++) {
          final v = c.luma[y * c.width + x] / 127.5 - 1.0;
          final o = n * 3 * plane + y * width + x;
          data[o] = v;
          data[o + plane] = v;
          data[o + 2 * plane] = v;
        }
      }
    }
    return data;
  }

  /// CTC greedy decoding: 0 is the blank, 1..dict.length the dictionary,
  /// the one after it a space; repeats collapse unless split by a blank.
  @visibleForTesting
  static String ctcDecode(List<int> ids, List<String> dict) {
    final sb = StringBuffer();
    var prev = 0;
    for (final i in ids) {
      if (i != prev && i != 0) {
        if (i <= dict.length) {
          sb.write(dict[i - 1]);
        } else if (i == dict.length + 1) {
          sb.write(' ');
        }
      }
      prev = i;
    }
    return sb.toString().trim();
  }
}
