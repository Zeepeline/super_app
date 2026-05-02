import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:super_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:super_app/features/home/presentation/bloc/home_event.dart';
import 'package:super_app/features/music_player/domain/entities/track_entity.dart'
    as player;
import 'package:super_app/features/music_player/presentation/cubit/player_cubit.dart';
import 'package:super_app/features/music_player/presentation/pages/music_player_page.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/track_entity.dart';

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
      duration: _parseDuration(track.duration),
      isFavorite: track.isFavorite,
      localPath: track.localPath,
    );

    // Play and open UI
    context.read<PlayerCubit>().selectAndPlay(playerTrack);

    // Navigate with slide-up transition
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MusicPlayerPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
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
                  child: const Icon(
                    Icons.music_note,
                    color: AppTheme.kPrimaryColor,
                  ),
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
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artist,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
            // Text(track.duration, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_horiz,
                color: AppTheme.kOnSurfaceVariantColor,
                size: 20,
              ),
              onSelected: (value) async {
                if (value == 'delete') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Hapus Musik?'),
                      content: Text(
                        'Apakah kamu yakin ingin menghapus "${track.title}" dari penyimpanan?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('BATAL'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'HAPUS',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    context.read<HomeBloc>().add(DeleteTrackEvent(track.id));
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Hapus dari Perangkat',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Duration _parseDuration(String durationStr) {
    if (durationStr.isEmpty) return Duration.zero;
    final parts = durationStr.split(':');
    if (parts.length == 2) {
      return Duration(
        minutes: int.tryParse(parts[0]) ?? 0,
        seconds: int.tryParse(parts[1]) ?? 0,
      );
    } else if (parts.length == 3) {
      return Duration(
        hours: int.tryParse(parts[0]) ?? 0,
        minutes: int.tryParse(parts[1]) ?? 0,
        seconds: int.tryParse(parts[2]) ?? 0,
      );
    }
    return Duration.zero;
  }
}
