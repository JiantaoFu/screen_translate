import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_translate/widgets/fitted_translation_text.dart';

void main() {
  for (final size in [
    const Size(45, 5),
    const Size(80, 14),
    const Size(180, 70)
  ]) {
    testWidgets('complete translation fits $size at large system text scale',
        (tester) async {
      const translation = '这是一个很长的地图说明文字，需要完整显示而不能截断。\n第二行也必须显示完整。';
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Center(
            child: SizedBox.fromSize(
                size: size,
                child: const FittedTranslationText(text: translation))),
      )));
      final paragraph =
          tester.renderObject<RenderParagraph>(find.text(translation));
      final painter = TextPainter(
          text: paragraph.text,
          textDirection: TextDirection.ltr,
          textScaler: paragraph.textScaler)
        ..layout(maxWidth: paragraph.size.width);
      expect(painter.height, lessThanOrEqualTo(paragraph.size.height));
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
      painter.dispose();
    });
  }
}
