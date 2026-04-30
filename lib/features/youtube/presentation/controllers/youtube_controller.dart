import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_app/core/services/youtube_explode_service.dart';
import 'package:super_app/core/services/youtube_download_service.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/features/home/data/datasources/home_local_data_source.dart';
import 'package:super_app/features/home/data/models/track_model.dart';
import 'package:super_app/injection_container.dart';
import 'package:uuid/uuid.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeController extends GetxController {
  final _ytService = sl<YouTubeExplodeService>();
  final _downloadService = sl<YoutubeDownloadService>();
  final _uuid = const Uuid();

  // Search State
  final RxString searchQuery = ''.obs;
  final RxList<Video> searchResults = <Video>[].obs;
  final RxBool isSearching = false.obs;
  final RxString searchError = ''.obs;

  // Download State - tracks progress per video
  final RxMap<String, DownloadState> downloadStates =
      <String, DownloadState>{}.obs;
  final RxMap<String, double> downloadProgress = <String, double>{}.obs;

  final TextEditingController searchTextController = TextEditingController();

  @override
  void onClose() {
    searchTextController.dispose();
    super.onClose();
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;

    isSearching.value = true;
    searchError.value = '';
    searchResults.clear();

    try {
      final results = await _ytService.searchVideos(query.trim());
      searchResults.assignAll(results);
    } catch (e) {
      searchError.value = 'Pencarian gagal: $e';
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> downloadVideo(Video video) async {
    final videoId = video.id.value;

    // Already downloading or done
    if (downloadStates[videoId]?.isDownloading == true) return;

    downloadStates[videoId] = DownloadState.downloading();
    downloadProgress[videoId] = 0.0;

    try {
      // Download using serious_python service
      final track = await _downloadService.downloadAndConvert(
        url: video.url,
        onProgress: (stage, progress) => downloadProgress[videoId] = progress,
      );

      if (track == null) throw Exception('Download gagal');

      // The download service returns a TrackModel with youtube ID.
      // We generate a local UUID for it to avoid conflicts if downloaded multiple times.
      final trackToSave = track.copyWith(id: _uuid.v4());

      await sl<HomeLocalDataSource>().addImportedTracks([trackToSave]);

      downloadStates[videoId] = DownloadState.done();
      downloadProgress.remove(videoId);

      _showSnackbar(
        'Berhasil! 🎵',
        '"${trackToSave.titleField}" telah ditambahkan ke Library.',
        backgroundColor: AppTheme.kPrimaryColor,
        colorText: Colors.black,
        icon: const Icon(Icons.check_circle_rounded, color: Colors.black),
      );
    } catch (e) {
      downloadStates[videoId] = DownloadState.error(e.toString());
      downloadProgress.remove(videoId);
      _showSnackbar(
        'Download Gagal',
        e.toString(),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        icon: const Icon(Icons.error_rounded, color: Colors.white),
      );
    }
  }

  String _cleanTitle(String title) {
    return title
        .replaceAll(' - YouTube Music', '')
        .replaceAll(' - YouTube', '')
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll(RegExp(r'\(Official.*?\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(Lyrics.*?\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(Audio.*?\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(Music Video.*?\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showSnackbar(
    String title,
    String message, {
    Color? backgroundColor,
    Color? colorText,
    Widget? icon,
  }) {
    // Delay to ensure overlay/context is ready after async operations
    Future.delayed(const Duration(milliseconds: 100), () {
      if (Get.context == null) {
        debugPrint('Snackbar skipped: no context — $title: $message');
        return;
      }
      try {
        Get.snackbar(
          title,
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: backgroundColor,
          colorText: colorText,
          margin: const EdgeInsets.all(16),
          borderRadius: 16,
          duration: const Duration(seconds: 4),
          icon: icon,
        );
      } catch (e) {
        debugPrint('Snackbar error (ignored): $e');
      }
    });
  }
}

enum _DownloadStatus { idle, extracting, downloading, done, error }

class DownloadState {
  final _DownloadStatus status;
  final String? errorMessage;

  const DownloadState._(this.status, {this.errorMessage});

  factory DownloadState.idle() => const DownloadState._(_DownloadStatus.idle);
  factory DownloadState.extracting() =>
      const DownloadState._(_DownloadStatus.extracting);
  factory DownloadState.downloading() =>
      const DownloadState._(_DownloadStatus.downloading);
  factory DownloadState.done() => const DownloadState._(_DownloadStatus.done);
  factory DownloadState.error(String message) =>
      DownloadState._(_DownloadStatus.error, errorMessage: message);

  bool get isDownloading =>
      status == _DownloadStatus.extracting ||
      status == _DownloadStatus.downloading;
  bool get isDone => status == _DownloadStatus.done;
  bool get isError => status == _DownloadStatus.error;
  bool get isIdle => status == _DownloadStatus.idle;
}
