import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
      print("Download error: $e");
      return null;
    }
  }

  Future<void> deleteDownloadedTrack(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
