import "package:flutter/foundation.dart";
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DownloadService {
  final Dio _dio = Dio();

  Future<String?> downloadTrack({
    required String url,
    required String trackId,
    Function(int received, int total)? onProgress,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory(p.join(appDir.path, 'music'));

      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }

      final extension = p.extension(url).isEmpty ? '.mp3' : p.extension(url);
      final savePath = p.join(musicDir.path, '$trackId$extension');

      await _dio.download(url, savePath, onReceiveProgress: onProgress);

      return savePath;
    } catch (e) {
      debugPrint("Download error: $e");
      return null;
    }
  }

  Future<String?> downloadFromStream({
    required String url,
    required String trackId,
    String extension = '.mp3',
    Function(double progress)? onProgress,
    int? totalSize,
  }) async {
    HttpClient? client;
    try {
      debugPrint("DownloadService: Starting download from $url");
      final appDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory(p.join(appDir.path, 'music'));

      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }

      final savePath = p.join(musicDir.path, '$trackId$extension');
      final file = File(savePath);

      client = HttpClient();
      // Set timeout to prevent hanging forever
      client.connectionTimeout = const Duration(seconds: 15);

      final request = await client.getUrl(Uri.parse(url));
      // Impersonate a real browser to avoid blocks
      request.headers.set(
        'User-Agent',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      );

      final response = await request.close();
      if (response.statusCode != 200) {
        debugPrint(
          "DownloadService: Server returned status code ${response.statusCode}",
        );
        return null;
      }

      final ios = file.openWrite();
      final actualSize = totalSize ?? response.contentLength;
      int received = 0;

      debugPrint(
        "DownloadService: Receiving data (size: $actualSize bytes)...",
      );

      await for (final data in response) {
        received += data.length;
        ios.add(data);

        if (onProgress != null && actualSize > 0) {
          onProgress(received / actualSize);
        }
      }

      await ios.flush();
      await ios.close();
      debugPrint("DownloadService: Download finished. Saved to $savePath");

      return savePath;
    } catch (e) {
      debugPrint("DownloadService Error: $e");
      return null;
    } finally {
      client?.close();
    }
  }

  Future<void> deleteDownloadedTrack(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
