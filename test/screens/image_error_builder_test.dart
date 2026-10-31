import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('corrupt image bytes render errorBuilder instead of throwing',
      (tester) async {
    final bad = Uint8List.fromList(List<int>.generate(64, (i) => i));
    await tester.pumpWidget(MaterialApp(
      home: Image.memory(
        bad,
        errorBuilder: (c, e, s) => const Icon(Icons.broken_image_outlined,
            key: Key('image_decode_error')),
      ),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('image_decode_error')), findsOneWidget);
  });
}
