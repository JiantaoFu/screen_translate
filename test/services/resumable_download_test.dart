import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:screen_translate/services/model_download_service.dart';

final _body = List<int>.generate(1000, (i) => i % 256);

/// Serves [_body], honouring Range requests. The first [failAfter] requests
/// send only half of what they promise and then stall (no more data).
MockClient _server({int failAfter = 0, bool honourRange = true, List<String?>? ranges}) {
  var requests = 0;
  return MockClient.streaming((request, _) async {
    requests++;
    final range = request.headers['range'];
    ranges?.add(range);
    var start = 0;
    var status = 200;
    final headers = <String, String>{};
    if (range != null && honourRange) {
      start = int.parse(range.substring('bytes='.length, range.length - 1));
      status = 206;
      headers['content-range'] = 'bytes $start-${_body.length - 1}/${_body.length}';
    }
    final rest = _body.sublist(start);
    final controller = StreamController<List<int>>();
    if (requests <= failAfter) {
      controller.add(rest.sublist(0, rest.length ~/ 2)); // then nothing: a stall
    } else {
      controller.add(rest);
      unawaited(controller.close());
    }
    return http.StreamedResponse(controller.stream, status,
        contentLength: rest.length, headers: headers);
  });
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('dl_test_'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> download(http.Client client, File target, {int maxAttempts = 6}) =>
      ModelDownloadService.downloadFileResumable(
        client: client,
        url: 'https://example.com/model.onnx',
        target: target,
        stallTimeout: const Duration(milliseconds: 100),
        retryDelay: Duration.zero,
        maxAttempts: maxAttempts,
      );

  test('a stalled download resumes with a Range request instead of restarting', () async {
    final ranges = <String?>[];
    final target = File('${dir.path}/model.onnx');
    await download(_server(failAfter: 2, ranges: ranges), target);

    expect(target.readAsBytesSync(), _body);
    expect(File('${target.path}.tmp').existsSync(), isFalse);
    // 500 bytes, then half of the remaining 500, then the rest.
    expect(ranges, [null, 'bytes=500-', 'bytes=750-']);
  });

  test('a partial file from an earlier attempt is resumed', () async {
    final target = File('${dir.path}/model.onnx');
    File('${target.path}.tmp').writeAsBytesSync(_body.sublist(0, 300));
    final ranges = <String?>[];
    await download(_server(ranges: ranges), target);
    expect(ranges, ['bytes=300-']);
    expect(target.readAsBytesSync(), _body);
  });

  test('a server that ignores Range restarts the file cleanly', () async {
    final target = File('${dir.path}/model.onnx');
    File('${target.path}.tmp').writeAsBytesSync(List.filled(300, 7));
    await download(_server(honourRange: false), target);
    expect(target.readAsBytesSync(), _body);
  });

  test('gives up after maxAttempts stalls, keeping the partial file', () async {
    final target = File('${dir.path}/model.onnx');
    await expectLater(download(_server(failAfter: 99), target, maxAttempts: 3), throwsA(anything));
    expect(target.existsSync(), isFalse);
    expect(File('${target.path}.tmp').existsSync(), isTrue);
  });

  test('a 404 is not retried', () async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return http.Response('not found', 404);
    });
    await expectLater(download(client, File('${dir.path}/model.onnx')), throwsA(isA<HttpException>()));
    expect(requests, 1);
  });
}
