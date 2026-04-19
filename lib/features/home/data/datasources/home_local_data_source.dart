import 'package:hive/hive.dart';

import '../../../../core/utils/hive_box_constants.dart';
import '../models/playlist_model.dart';
import '../models/track_model.dart';

abstract class HomeLocalDataSource {
  Future<List<PlaylistModel>> getFeaturedPlaylists();
  Future<void> cacheFeaturedPlaylists(List<PlaylistModel> playlistsToCache);

  Future<List<TrackModel>> getPopularTracks();
  Future<void> cachePopularTracks(List<TrackModel> tracksToCache);
  Future<void> addImportedTracks(List<TrackModel> tracksToAdd);
  Future<void> updateTrackFavoriteStatus(String id, bool isFavorite);
  Future<void> updateTrackDuration(String path, String duration);
  Stream<void> watchTracks();
}

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  final HiveInterface hive;
  Box<PlaylistModel>? _playlistsBox;
  Box<TrackModel>? _tracksBox;

  HomeLocalDataSourceImpl({required this.hive});

  Future<Box<PlaylistModel>> _getPlaylistsBox() async {
    if (_playlistsBox != null && _playlistsBox!.isOpen) return _playlistsBox!;
    _playlistsBox = await hive.openBox<PlaylistModel>(
      HiveBoxConstants.playlistsBox,
    );
    return _playlistsBox!;
  }

  Future<Box<TrackModel>> _getTracksBox() async {
    if (_tracksBox != null && _tracksBox!.isOpen) return _tracksBox!;
    _tracksBox = await hive.openBox<TrackModel>(HiveBoxConstants.tracksBox);
    return _tracksBox!;
  }

  @override
  Future<void> cacheFeaturedPlaylists(
    List<PlaylistModel> playlistsToCache,
  ) async {
    final box = await _getPlaylistsBox();
    await box.clear();
    await box.addAll(playlistsToCache);
  }

  @override
  Future<void> cachePopularTracks(List<TrackModel> tracksToCache) async {
    final box = await _getTracksBox();
    await box.clear();
    await box.addAll(tracksToCache);
  }

  @override
  Future<void> addImportedTracks(List<TrackModel> tracksToAdd) async {
    try {
      final box = await _getTracksBox();
      final existingPaths = box.values.map((t) => t.localPath).toSet();

      final newTracks = tracksToAdd
          .where((t) => !existingPaths.contains(t.localPath))
          .toList();
      if (newTracks.isNotEmpty) {
        await box.addAll(newTracks);
        print(
          "HomeLocalDataSource: Successfully added ${newTracks.length} new tracks to library.",
        );
      }
    } catch (e) {
      print("HomeLocalDataSource: Error adding tracks to library: $e");
      // Fallback: try to wipe and add if really stuck
      try {
        await hive.deleteBoxFromDisk(HiveBoxConstants.tracksBox);
        _tracksBox = null;
        final box = await _getTracksBox();
        await box.addAll(tracksToAdd);
      } catch (inner) {
        print(
          "HomeLocalDataSource: Fatal failure in track persistence: $inner",
        );
      }
    }
  }

  @override
  Future<List<PlaylistModel>> getFeaturedPlaylists() async {
    try {
      final box = await _getPlaylistsBox();
      return box.values.toList();
    } catch (e) {
      print("HomeLocalDataSource: Corrupted box detected, clearing...");
      await hive.deleteBoxFromDisk(HiveBoxConstants.playlistsBox);
      _playlistsBox = null;
      final box = await _getPlaylistsBox();
      return box.values.toList();
    }
  }

  @override
  Future<List<TrackModel>> getPopularTracks() async {
    try {
      final box = await _getTracksBox();
      return box.values.toList();
    } catch (e) {
      print("HomeLocalDataSource: Critical Hive Error: $e");
      print(
        "HomeLocalDataSource: Attempting to clear corrupted 'tracks' box...",
      );
      try {
        await hive.deleteBoxFromDisk(HiveBoxConstants.tracksBox);
        _tracksBox = null;
        final box = await _getTracksBox();
        return box.values.toList();
      } catch (innerError) {
        print(
          "HomeLocalDataSource: Recursive failure while clearing box: $innerError",
        );
        return [];
      }
    }
  }

  @override
  Future<void> updateTrackFavoriteStatus(String id, bool isFavorite) async {
    try {
      final box = await _getTracksBox();
      // Find by idField since that's what we use in our TrackModel
      final trackIndex = box.values.toList().indexWhere((t) => t.id == id);

      if (trackIndex != -1) {
        final track = box.getAt(trackIndex);
        if (track != null) {
          final updatedTrack = track.copyWith(isFavorite: isFavorite);
          await box.putAt(trackIndex, updatedTrack);
          print(
            "HomeLocalDataSource: Updated favorite status for $id to $isFavorite",
          );
        }
      }
    } catch (e) {
      print("HomeLocalDataSource: Error updating favorite status: $e");
    }
  }

  @override
  Future<void> updateTrackDuration(String path, String duration) async {
    try {
      final box = await _getTracksBox();
      final trackIndex = box.values.toList().indexWhere((t) => t.localPath == path);

      if (trackIndex != -1) {
        final track = box.getAt(trackIndex);
        if (track != null) {
          final updatedTrack = track.copyWith(duration: duration);
          await box.putAt(trackIndex, updatedTrack);
        }
      }
    } catch (e) {
      print("HomeLocalDataSource: Error updating duration: $e");
    }
  }

  @override
  Stream<void> watchTracks() async* {
    final box = await _getTracksBox();
    yield* box.watch();
  }
}
