import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

class CustomModelManager {
  // IMPORTANT: This URL points to your local development machine for testing.
  // - Use 'http://10.0.2.2:8000' for the Android Emulator.
  // - For a physical device, replace '10.0.2.2' with your computer's
  //   local network IP (e.g., 'http://192.168.1.5:8000').
  // - For production, replace this with your actual public server URL.
  final String baseUrl = 'https://huggingface.co/fuji246/small-translation/resolve/main';

  /// Gets the directory where the ML Kit model folder should be unzipped.
  Future<Directory> _getExtractionDir() async {
    final appDir = await getApplicationSupportDirectory();
    return Directory(path.join(appDir.parent.path, 'no_backup'));
  }

  Future<void> downloadAndInstallModel(
    String langCode, {
    void Function(double progress)? onProgress,
  }) async {
    final url = '$baseUrl/$langCode.zip';
    print('Fallback: Downloading model for $langCode from $url...');

    final client = http.Client();
    try {
      final response = await client.send(http.Request('GET', Uri.parse(url)));

      if (response.statusCode == 200) {
        final total = response.contentLength;
        final builder = BytesBuilder(copy: false);
        await for (final chunk in response.stream) {
          builder.add(chunk);
          if (total != null && total > 0) onProgress?.call(builder.length / total);
        }
        final bytes = builder.takeBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        final extractionDir = await _getExtractionDir();

        if (!await extractionDir.exists()) {
          await extractionDir.create(recursive: true);
        }

        print('Unzipping and installing model files to ${extractionDir.path}...');
        for (final file in archive) {
          final filename = path.join(extractionDir.path, file.name);
          if (file.isFile) {
            final outFile = File(filename);
            await outFile.create(recursive: true);
            await outFile.writeAsBytes(file.content as List<int>);
            print('Extracted: $filename');
          }
        }
        print('Fallback model for $langCode installed successfully.');
      } else {
        await response.stream.drain<void>();
        throw Exception('Fallback failed: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Error during fallback download for $langCode: $e');
      rethrow;
    } finally {
      client.close();
    }
  }
}
