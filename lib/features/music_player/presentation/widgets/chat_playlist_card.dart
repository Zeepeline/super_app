import 'package:flutter/material.dart';
import 'package:super_app/core/services/music/smart_playlist_service.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/features/music_player/presentation/cubit/player_cubit.dart';
import 'package:super_app/injection_container.dart';

class ChatPlaylistCard extends StatelessWidget {
  final SmartPlaylistResponse response;

  const ChatPlaylistCard({super.key, required this.response});

  void _playAll(BuildContext context) {
    if (response.tracks.isEmpty) return;

    final playerCubit = sl<PlayerCubit>();
    playerCubit.playPlaylist(response.tracks);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Memutar: ${response.playlistName}'),
        backgroundColor: AppTheme.kPrimaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppTheme.kSurfaceContainerLowColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.kPrimaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.queue_music,
                  color: AppTheme.kPrimaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      response.playlistName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${response.tracks.length} Lagu',
                      style: const TextStyle(
                        color: AppTheme.kPrimaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            response.reason,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // Daftar Lagu Teratas
          ...response.tracks
              .take(3)
              .map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.music_note_rounded,
                        size: 16,
                        color: Colors.white38,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${t.title} - ${t.artist}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (response.tracks.length > 3)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 4),
              child: Text(
                '+ ${response.tracks.length - 3} lagu lainnya',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _playAll(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.kPrimaryColor,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text(
              'Putar Semua',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
