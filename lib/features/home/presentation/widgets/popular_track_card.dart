import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/track_entity.dart';
import 'package:super_app/features/music_player/domain/entities/track_entity.dart' as player;
import 'package:super_app/features/music_player/presentation/cubit/player_cubit.dart';
import 'package:super_app/features/music_player/presentation/pages/music_player_page.dart';

class PopularTrackCard extends StatelessWidget {
  final TrackEntity track;

  const PopularTrackCard({super.key, required this.track});

  void _playAndOpenPlayer(BuildContext context) {
    // Convert home TrackEntity to player TrackEntity
    final playerTrack = player.TrackEntity(
      id: track.id,
      title: track.title,
      artist: track.artist,
      albumArtUrl: track.albumArtUrl,
      audioUrl: track.audioUrl,
      duration: const Duration(minutes: 3, seconds: 45), // Mock duration for now
      localPath: track.localPath,
    );

    // Play and open UI
    context.read<PlayerCubit>().selectAndPlay(playerTrack);

    // Navigate with slide-up transition
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MusicPlayerPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _playAndOpenPlayer(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.kSurfaceContainerColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                track.albumArtUrl,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 52,
                  height: 52,
                  color: AppTheme.kSurfaceContainerHighestColor,
                  child: const Icon(Icons.music_note, color: AppTheme.kPrimaryColor),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title.toUpperCase(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artist,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Text(
              track.duration,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(width: 8),
            const Icon(Icons.more_horiz, color: AppTheme.kOnSurfaceVariantColor, size: 20),
          ],
        ),
      ),
    );
  }
}
