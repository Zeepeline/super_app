import 'dart:convert';
import 'dart:developer';

import 'package:hive/hive.dart';
import 'package:super_app/core/services/ai/gemini_service.dart';
import 'package:super_app/core/services/download/youtube_explode_service.dart';
import 'package:super_app/core/services/infrastructure/python_worker_service.dart';
import 'package:super_app/core/utils/hive_box_constants.dart';
import 'package:super_app/features/home/data/models/track_model.dart'
    as home_model;
import 'package:super_app/features/music_player/domain/entities/track_entity.dart'
    as player_entity;

class SmartPlaylistResponse {
  final String playlistName;
  final String reason;
  final List<player_entity.TrackEntity> tracks;

  SmartPlaylistResponse({
    required this.playlistName,
    required this.reason,
    required this.tracks,
  });
}

class SmartPlaylistService {
  final GeminiService _geminiService;
  final YouTubeExplodeService _ytService;
  final PythonWorkerService _workerService;

  SmartPlaylistService(
    this._geminiService,
    this._ytService,
    this._workerService,
  );

  Future<SmartPlaylistResponse?> generatePlaylist(String userQuery) async {
    // ... existing generatePlaylist logic (Local) ...
    try {
      final box = await Hive.openBox<home_model.TrackModel>(
        HiveBoxConstants.tracksBox,
      );
      final allTracks = box.values.toList();

      if (allTracks.isEmpty) {
        return null;
      }

      final trackListJson = jsonEncode(
        allTracks
            .map(
              (t) => {
                'id': t.idField,
                'title': t.titleField,
                'artist': t.artistField,
                'album': t.albumField,
              },
            )
            .toList(),
      );

      final response = await _geminiService.createSmartPlaylist(
        trackListJson: trackListJson,
        userQuery: userQuery,
      );

      return _processResponse(response, allTracks);
    } catch (e) {
      log('SmartPlaylistService (Local) Error: $e');
      return null;
    }
  }

  Future<SmartPlaylistResponse?> generateYouTubePlaylist(
    String userQuery,
  ) async {
    try {
      // --- OPTION 1: TRY YT MUSIC CURATED PLAYLIST FIRST ---
      if (_workerService.isReady) {
        try {
          final workerResponse = await _workerService.postSync(
            '/yt_smart_playlist',
            {'query': userQuery},
          );
          if (workerResponse['status'] == 'ok' &&
              workerResponse['playlist'] != null) {
            final p = workerResponse['playlist'];
            final List<player_entity.TrackEntity> tracks = (p['tracks'] as List)
                .map((t) {
                  return player_entity.TrackEntity(
                    id: t['id'],
                    title: t['title'],
                    artist: t['artist'],
                    album: t['album'] ?? 'YouTube Music',
                    albumArtUrl: t['albumArtUrl'] ?? '',
                    audioUrl: '',
                    duration: Duration(seconds: t['duration_seconds'] ?? 0),
                    localPath: null,
                    isFavorite: false,
                    syncedLyrics: null,
                    plainLyrics: null,
                  );
                })
                .toList();

            if (tracks.isNotEmpty) {
              log('✅ Generated playlist via YTMusicAPI curated suggestions');
              return SmartPlaylistResponse(
                playlistName:
                    p['playlistName'] ?? 'YouTube Music Recommendation',
                reason:
                    p['reason'] ??
                    'Berdasarkan pencarian Anda di YouTube Music.',
                tracks: tracks,
              );
            }
          }
        } catch (e) {
          log('⚠️ Worker Smart Playlist Failed: $e');
        }
      }

      // --- OPTION 2: GEMINI + INDIVIDUAL SEARCH (FALLBACK) ---
      final response = await _geminiService.createYoutubeSmartPlaylist(
        userQuery: userQuery,
      );

      // Clean the response
      String cleanJson = response;
      if (cleanJson.contains('```json')) {
        cleanJson = cleanJson.split('```json')[1].split('```')[0];
      } else if (cleanJson.contains('```')) {
        cleanJson = cleanJson.split('```')[1].split('```')[0];
      }
      cleanJson = cleanJson.trim();

      final decoded = jsonDecode(cleanJson);
      final List<dynamic> recommendedTrackData = decoded['tracks'] ?? [];

      final List<player_entity.TrackEntity> recommendedTracks = [];

      // Buka box cache
      final cacheBox = await Hive.openBox<String>(
        HiveBoxConstants.youtubeSearchCacheBox,
      );

      for (var data in recommendedTrackData) {
        final title = data['title'];
        final artist = data['artist'];
        final searchQuery = "$title $artist audio";

        try {
          String? cachedData = cacheBox.get(searchQuery);

          if (cachedData != null) {
            // Gunakan cache
            final cachedJson = jsonDecode(cachedData);
            final entity = player_entity.TrackEntity(
              id: cachedJson['id'],
              title: cachedJson['title'],
              artist: cachedJson['artist'],
              album: 'YouTube Music',
              albumArtUrl: cachedJson['albumArtUrl'],
              audioUrl:
                  '', // This will be resolved by the player using YouTubeExplode
              duration: Duration(seconds: cachedJson['duration_seconds']),
              localPath: null,
              isFavorite: false,
              syncedLyrics: null,
              plainLyrics: null,
            );
            recommendedTracks.add(entity);
            continue; // Skip the search
          }

          // --- TRY WORKER SEARCH FIRST (YTMUSICAPI) ---
          dynamic videoData;
          if (_workerService.isReady) {
            try {
              final response = await _workerService.postSync('/yt_search', {
                'query': searchQuery,
              });
              if (response['status'] == 'ok' &&
                  (response['results'] as List).isNotEmpty) {
                videoData = response['results'][0];
                log('✅ Found via YTMusicAPI: ${videoData['title']}');
              }
            } catch (e) {
              log('⚠️ Worker Search Failed: $e');
            }
          }

          if (videoData != null) {
            final durationSeconds = videoData['duration_seconds'] ?? 0;

            final cacheEntry = {
              'id': videoData['id'],
              'title': videoData['title'],
              'artist': videoData['artist'],
              'albumArtUrl': videoData['albumArtUrl'],
              'duration_seconds': durationSeconds,
            };
            await cacheBox.put(searchQuery, jsonEncode(cacheEntry));

            final entity = player_entity.TrackEntity(
              id: videoData['id'],
              title: videoData['title'],
              artist: videoData['artist'],
              album: 'YouTube Music',
              albumArtUrl: videoData['albumArtUrl'],
              audioUrl: '',
              duration: Duration(seconds: durationSeconds),
              localPath: null,
              isFavorite: false,
              syncedLyrics: null,
              plainLyrics: null,
            );
            recommendedTracks.add(entity);
            continue;
          }

          // --- FALLBACK TO YOUTUBE EXPLODE ---
          // Delay hanya dilakukan jika terpaksa menggunakan YouTubeExplode untuk menghindari rate limit
          await Future.delayed(const Duration(milliseconds: 1500));

          final results = await _ytService.searchVideos(searchQuery);
          if (results.isNotEmpty) {
            final video = results.first;

            final durationSeconds = video.duration?.inSeconds ?? 0;

            // Simpan ke cache
            final cacheEntry = {
              'id': video.id.value,
              'title': video.title,
              'artist': video.author,
              'albumArtUrl': video.thumbnails.highResUrl,
              'duration_seconds': durationSeconds,
            };
            await cacheBox.put(searchQuery, jsonEncode(cacheEntry));

            final entity = player_entity.TrackEntity(
              id: video.id.value,
              title: video.title,
              artist: video.author,
              album: 'YouTube Music',
              albumArtUrl: video.thumbnails.highResUrl,
              audioUrl: video
                  .url, // This will be resolved by the player using YouTubeExplode
              duration: video.duration ?? Duration.zero,
              localPath: null,
              isFavorite: false,
              syncedLyrics: null,
              plainLyrics: null,
            );

            recommendedTracks.add(entity);
          }
        } catch (e) {
          log('YouTube search error for $searchQuery: $e');
        }
      }

      return SmartPlaylistResponse(
        playlistName: decoded['playlist_name'] ?? 'AI YouTube Playlist',
        reason: decoded['reason'] ?? 'Menemukan musik yang cocok di YouTube.',
        tracks: recommendedTracks,
      );
    } catch (e) {
      log('SmartPlaylistService (YouTube) Error: $e');
      return null;
    }
  }

  SmartPlaylistResponse? _processResponse(
    String response,
    List<home_model.TrackModel> allTracks,
  ) {
    // Clean the response (sometimes AI adds markdown blocks)
    String cleanJson = response;
    if (cleanJson.contains('```json')) {
      cleanJson = cleanJson.split('```json')[1].split('```')[0];
    } else if (cleanJson.contains('```')) {
      cleanJson = cleanJson.split('```')[1].split('```')[0];
    }
    cleanJson = cleanJson.trim();

    final decoded = jsonDecode(cleanJson);
    final List<dynamic> recommendedTrackData = decoded['tracks'] ?? [];

    final List<player_entity.TrackEntity> recommendedTracks = [];
    for (var data in recommendedTrackData) {
      final trackId = data['id'];
      final homeTrack = allTracks.firstWhere(
        (t) => t.idField == trackId,
        orElse: () => allTracks.firstWhere(
          (t) =>
              t.titleField.toLowerCase() ==
              data['title'].toString().toLowerCase(),
          orElse: () => allTracks.first, // Fallback if not found
        ),
      );

      final parts = homeTrack.durationField.split(':');
      int minutes = 0;
      int seconds = 0;
      if (parts.length > 1) {
        minutes = int.tryParse(parts[0]) ?? 0;
        seconds = int.tryParse(parts[1]) ?? 0;
      } else {
        seconds = int.tryParse(parts[0]) ?? 0;
      }

      final entity = player_entity.TrackEntity(
        id: homeTrack.idField,
        title: homeTrack.titleField,
        artist: homeTrack.artistField,
        album: homeTrack.albumField,
        albumArtUrl: homeTrack.albumArtUrlField,
        audioUrl: homeTrack.audioUrlField,
        duration: Duration(minutes: minutes, seconds: seconds),
        localPath: homeTrack.localPathField,
        isFavorite: homeTrack.isFavoriteField,
        syncedLyrics: homeTrack.syncedLyricsField,
        plainLyrics: homeTrack.plainLyricsField,
      );

      if (!recommendedTracks.any((t) => t.id == entity.id)) {
        recommendedTracks.add(entity);
      }
    }

    return SmartPlaylistResponse(
      playlistName: decoded['playlist_name'] ?? 'AI Recommended Playlist',
      reason: decoded['reason'] ?? 'Cocok untuk suasana hati Anda.',
      tracks: recommendedTracks,
    );
  }
}
