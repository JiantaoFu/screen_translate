import 'dart:math';
import 'package:flutter/material.dart';

/// Measures the complete translation, including tiny map labels. A fixed
/// minimum font size can leave only a clipped line in those short boxes.
class FittedTranslationText extends StatelessWidget {
  const FittedTranslationText({super.key, required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, bounds) {
        final horizontal = min(4.0, bounds.maxWidth * .05);
        final vertical = min(2.0, bounds.maxHeight * .05);
        final width = bounds.maxWidth - horizontal * 2;
        final height = bounds.maxHeight - vertical * 2;
        if (width <= 0 || height <= 0) return const SizedBox.shrink();
        final direction = Directionality.of(context);
        final base = DefaultTextStyle.of(context).style.copyWith(color: color);
        final painter = TextPainter(
            textDirection: direction, textScaler: TextScaler.noScaling);
        var low = 0.0;
        var high = 100.0;
        for (var i = 0; i < 20; i++) {
          final size = (low + high) / 2;
          painter.text =
              TextSpan(text: text, style: base.copyWith(fontSize: size));
          painter.layout(maxWidth: width);
          if (painter.height <= height && painter.width <= width) {
            low = size;
          } else {
            high = size;
          }
        }
        painter.dispose();
        return Padding(
          padding:
              EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
          child: Text(text,
              style: base.copyWith(fontSize: low),
              textDirection: direction,
              textScaler: TextScaler.noScaling),
        );
      });
}
