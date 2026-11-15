import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ChatMediaCache {
  static Future<Directory> _mediaDirectory() async {
    final appDirectory = await getApplicationSupportDirectory();

    final directory = Directory(
      '${appDirectory.path}/chat_media',
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  static String _safeFileName(String messageId) {
    return messageId.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
  }

  static Future<File> getOrDownload({
    required String messageId,
    required String url,
    required String extension,
  }) async {
    final directory = await _mediaDirectory();
    final safeId = _safeFileName(messageId);

    final cleanExtension = extension.replaceAll('.', '');
    final file = File(
      '${directory.path}/$safeId.$cleanExtension',
    );

    // Reuse the existing local copy.
    if (await file.exists() && await file.length() > 0) {
      return file;
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw HttpException(
        'Media download failed: HTTP ${response.statusCode}',
      );
    }

    if (response.bodyBytes.isEmpty) {
      throw const HttpException('Downloaded media is empty.');
    }

    // Write to a temporary file first to avoid partial downloads
    // being treated as completed downloads.
    final temporaryFile = File('${file.path}.part');

    try {
      await temporaryFile.writeAsBytes(
        response.bodyBytes,
        flush: true,
      );

      if (await file.exists()) {
        await file.delete();
      }

      return await temporaryFile.rename(file.path);
    } catch (_) {
      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }
      rethrow;
    }
  }

  static Future<void> deleteLocalCopy(String messageId) async {
    final directory = await _mediaDirectory();
    final safeId = _safeFileName(messageId);

    // Delete cached copies for common media extensions.
    for (final extension in [
      'jpg', 'jpeg', 'png', 'webp',
      'mp4', 'mov', 'm4a', 'aac', 'mp3', 'ogg',
    ]) {
      final file = File(
        '${directory.path}/$safeId.$extension',
      );

      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}