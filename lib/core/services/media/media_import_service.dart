import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:super_app/features/home/data/models/track_model.dart';
import 'package:uuid/uuid.dart';

class MediaImportService {
  final _uuid = const Uuid();

  MediaImportService();

  /// Static flag to prevent concurrent calls across any instance or hot-restart
  static bool _isPickerActive = false;

  static final _ytPattern = RegExp(r"^(.*)\s\[([a-zA-Z0-9_-]{11})\]$");

  Future<bool> _checkPermissions() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      PermissionStatus status;
      if (sdkInt >= 33) {
        status = await Permission.audio.request();
      } else {
        status = await Permission.storage.request();
      }

      if (status.isGranted) return true;

      if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
      return false;
    } else if (Platform.isIOS) {
      // FilePicker on iOS handles permissions internally via the Files app.
      return true;
    }
    return true;
  }

  Future<List<TrackModel>> importLocalTracks() async {
    // Strict guard — static so it survives hot-restart within same isolate
    if (_isPickerActive) {
      return [];
    }
    _isPickerActive = true;

    try {
      // Check permissions first
      if (!await _checkPermissions()) {
        return [];
      }

      List<String?> filePaths = [];

      if (Platform.isIOS) {
        filePaths = await _pickFilesIOS();
      } else {
        filePaths = await _scanDirectoryDesktop();
      }

      if (filePaths.isEmpty) {
        return [];
      }

      return await _processFiles(filePaths);
    } catch (_) {
      return [];
    } finally {
      _isPickerActive = false;
    }
  }

  /// iOS: Use multi-file picker with retry logic for the common
  /// `multiple_request` PlatformException (happens after hot restart).
  Future<List<String?>> _pickFilesIOS() async {
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.audio,
          allowMultiple: true,
        );
        if (result != null && result.paths.isNotEmpty) {
          return result.paths;
        }

        return [];
      } on Exception {
        if (attempt == 1) {
          // First attempt failed — wait for native picker to fully release

          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
    return [];
  }

  /// Desktop/Android: Scan an entire directory recursively.
  Future<List<String?>> _scanDirectoryDesktop() async {
    final directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath == null) {
      return [];
    }

    final directory = Directory(directoryPath);
    final entities = await directory.list(recursive: true).toList();
    return entities.whereType<File>().map((e) => e.path).toList();
  }

  /// Process selected file paths into TrackModels.
  Future<List<TrackModel>> _processFiles(List<String?> filePaths) async {
    final List<TrackModel> importedTracks = [];
    final appDir = await getApplicationDocumentsDirectory();
    final musicDir = Directory(p.join(appDir.path, 'imported_music'));
    if (!await musicDir.exists()) await musicDir.create(recursive: true);

    final supportedExtensions = ['.mp3', '.m4a', '.wav', '.flac'];

    for (var path in filePaths) {
      if (path == null) continue;
      final ext = p.extension(path).toLowerCase();

      if (supportedExtensions.contains(ext)) {
        final file = File(path);
        final fileName = p.basename(path);
        final newPath = p.join(musicDir.path, fileName);

        // Copy to internal storage
        await file.copy(newPath);

        final title = p.basenameWithoutExtension(fileName);
        // lyrics are now fetched on-demand during playback or during direct download
        final durationText = await getAudioDurationText(newPath);

        importedTracks.add(
          TrackModel(
            idField: _uuid.v4(),
            titleField: title,
            artistField: 'Local Artist',
            albumField: 'Local Music',
            albumArtUrlField:
                'https://images.unsplash.com/photo-1514525253361-bee8ea36b745?auto=format&fit=crop&q=80&w=300',
            durationField: durationText,
            localPathField: newPath,
            audioUrlField: newPath,
            syncedLyricsField: null,
            plainLyricsField: null,
          ),
        );
      }
    }
    return importedTracks;
  }

  /// Load music files bundled with the app (from assets/music/).
  Future<List<TrackModel>> loadBundledAssets() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory(p.join(appDir.path, 'imported_music'));
      if (!await musicDir.exists()) await musicDir.create(recursive: true);

      // All files in assets/music/ — add new entries here when you add songs
      const bundledFiles = [
        'melodigne-champion-143955.mp3',
        'I Like You So Much, You\u2019ll Know It (\u6211\u591a\u559c\u6b22\u4f60\uff0c\u4f60\u4f1a\u77e5\u9053)- A Love So Beautiful OST -Wang Junqi [English Cover] [bS9eXS6VucU].mp3',
      ];

      final List<TrackModel> importedTracks = [];

      for (var fileName in bundledFiles) {
        final newPath = p.join(musicDir.path, fileName);
        final targetFile = File(newPath);

        if (!await targetFile.exists()) {
          try {
            final data = await rootBundle.load('assets/music/$fileName');
            await targetFile.writeAsBytes(data.buffer.asUint8List());
          } catch (e) {
            continue;
          }
        } else {}

        final title = p
            .basenameWithoutExtension(fileName)
            .replaceAll('-', ' ')
            .replaceAll('_', ' ');
        // lyrics are now fetched on-demand during playback
        final durationText = await getAudioDurationText(
          'assets/music/$fileName',
          isAsset: true,
        );

        importedTracks.add(
          TrackModel(
            idField: _uuid.v4(),
            titleField: title,
            artistField: 'Local Artist',
            albumField: 'Bundled Music',
            albumArtUrlField:
                'https://images.unsplash.com/photo-1514525253361-bee8ea36b745?auto=format&fit=crop&q=80&w=300',
            durationField: durationText,
            localPathField: newPath,
            audioUrlField: newPath,
            syncedLyricsField: null,
            plainLyricsField: null,
          ),
        );
      }

      return importedTracks;
    } catch (e) {
      return [];
    }
  }

  /// NEW: Scan the internal /music folder (where WebView downloads go).
  /// [existingPaths] optionally allows skipping tracks already in the library.
  Future<List<TrackModel>> scanDownloadedMusic({
    Set<String>? existingPaths,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory(p.join(appDir.path, 'music'));

      if (!await musicDir.exists()) {
        return [];
      }

      final List<String> filePaths = [];
      final entities = await musicDir.list(recursive: true).toList();
      for (var entity in entities) {
        if (entity is File) {
          filePaths.add(entity.path);
        }
      }

      if (filePaths.isEmpty) {
        return [];
      }

      final List<TrackModel> discoveredTracks = [];
      final supportedExtensions = ['.mp3', '.m4a', '.wav', '.flac'];

      for (var path in filePaths) {
        // QUICK EXIT: skip if we already have this in library
        if (existingPaths != null && existingPaths.contains(path)) continue;

        final ext = p.extension(path).toLowerCase();
        if (supportedExtensions.contains(ext)) {
          final fileName = p.basename(path);
          var title = p.basenameWithoutExtension(fileName);

          // Regex to match "Title [VideoID]" and extract "Title" and "VideoID"
          final match = _ytPattern.firstMatch(
            p.basenameWithoutExtension(fileName),
          );
          String stableId = _uuid.v4();

          if (match != null) {
            title = match.group(1)!;
            stableId = match.group(2)!; // Use YouTube ID as stable ID
          } else {
            // For non-YouTube files, use filename as a semi-stable ID
            // (Better than random UUID which causes duplicates on path change)
            stableId = "local_${p.basenameWithoutExtension(fileName)}";
          }

          // Replace underscores/hyphens with spaces if they look like they were sanitized
          title = title.replaceAll('_', ' ').replaceAll('-', ' ');

          // lyrics are now fetched on-demand during playback or during direct download
          final durationText = await getAudioDurationText(path);

          discoveredTracks.add(
            TrackModel(
              idField: stableId,
              titleField: title,
              artistField: 'Web Download',
              albumField: 'YouTube Download',
              albumArtUrlField:
                  'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&q=80&w=300',
              durationField: durationText,
              localPathField: path,
              audioUrlField: path,
              syncedLyricsField: null,
              plainLyricsField: null,
            ),
          );
        }
      }

      return discoveredTracks;
    } catch (e) {
      return [];
    }
  }

  /// Helper to get formatted duration (m:ss) from a file or asset.
  Future<String> getAudioDurationText(
    String path, {
    bool isAsset = false,
  }) async {
    final player = AudioPlayer();
    try {
      Duration? duration;
      if (isAsset) {
        duration = await player.setAsset(path);
      } else {
        duration = await player.setFilePath(path);
      }

      if (duration == null || duration == Duration.zero) return "0:00";

      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds.remainder(60);
      return "$minutes:${seconds.toString().padLeft(2, '0')}";
    } catch (e) {
      return "0:00";
    } finally {
      await player.dispose();
    }
  }
}
