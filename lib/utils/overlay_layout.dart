import 'dart:math';
import 'dart:ui';
import '../models/ocr_result.dart';

/// Source-anchored padding shared by live and image translation.
List<Rect> computeOverlayBoxes(List<OCRResult> results) {
  final baseBoxes =
      results.map((r) => Rect.fromLTWH(r.x, r.y, r.width, r.height)).toList();

  final paddedBoxes = <Rect>[];
  for (int i = 0; i < results.length; i++) {
    final result = results[i];
    final base = baseBoxes[i];
    final desiredPad = min(result.height, result.fontSize) * 0.15;

    double padTop = desiredPad;
    double padBottom = desiredPad;
    double padLeft = desiredPad;
    double padRight = desiredPad;
    for (int j = 0; j < baseBoxes.length; j++) {
      if (j == i) continue;
      final other = baseBoxes[j];
      final horizontalOverlap =
          base.left < other.right && base.right > other.left;
      final verticalOverlap =
          base.top < other.bottom && base.bottom > other.top;
      final nearX = base.left - desiredPad * 2 < other.right &&
          base.right + desiredPad * 2 > other.left;
      final nearY = base.top - desiredPad * 2 < other.bottom &&
          base.bottom + desiredPad * 2 > other.top;
      if (horizontalOverlap || nearX && nearY) {
        if (other.bottom <= base.top) {
          padTop = min(padTop, max(0.0, (base.top - other.bottom) / 2));
        } else if (other.top >= base.bottom) {
          padBottom = min(padBottom, max(0.0, (other.top - base.bottom) / 2));
        }
      }
      if (verticalOverlap || nearX && nearY) {
        // Same-row neighbor (adjacent tabs/buttons): cap the side padding
        // at half the gap, otherwise both boxes grow into each other and
        // _resolveOverlaps pushes one a full box height down, exposing
        // its original text and covering whatever is below.
        if (other.right <= base.left) {
          padLeft = min(padLeft, max(0.0, (base.left - other.right) / 2));
        } else if (other.left >= base.right) {
          padRight = min(padRight, max(0.0, (other.left - base.right) / 2));
        }
      }
    }

    final padded = Rect.fromLTWH(
      base.left - padLeft,
      base.top - padTop,
      base.width + padLeft + padRight,
      base.height + padTop + padBottom,
    );
    paddedBoxes.add(result.imgWidth > 0 && result.imgHeight > 0
        ? padded
            .intersect(Rect.fromLTWH(0, 0, result.imgWidth, result.imgHeight))
        : padded);
  }

  return _resolveOverlaps(paddedBoxes);
}

/// Pushes boxes down (reading order) just enough that none of them
/// overlaps a box above/left of it that shares horizontal space.
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
      final horizontalOverlap =
          box.left < other.right && box.right > other.left;
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
