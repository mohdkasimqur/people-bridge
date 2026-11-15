import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

class ChatMediaCompressor {
  static Future<File> compressImage(File original) async {
    final directory = await getTemporaryDirectory();

    final targetPath =
        '${directory.path}/chat_${DateTime.now().microsecondsSinceEpoch}.jpg';

    final compressed = await FlutterImageCompress.compressAndGetFile(
      original.path,
      targetPath,
      quality: 78,
      minWidth: 1600,
      minHeight: 1600,
      format: CompressFormat.jpeg,
    );

    if (compressed == null) {
      throw Exception('Image compression failed.');
    }

    return File(compressed.path);
  }

  static Future<File> compressVideo(File original) async {
    final result = await VideoCompress.compressVideo(
      original.path,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false,
    );

    final compressed = result?.file;

    if (compressed == null || !await compressed.exists()) {
      throw Exception('Video compression failed.');
    }

    // Keep the original file; use the compressed copy for upload.
    return compressed;
  }
}