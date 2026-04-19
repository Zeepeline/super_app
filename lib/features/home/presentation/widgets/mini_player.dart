import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../music_player/presentation/cubit/player_cubit.dart';
import '../../../music_player/presentation/cubit/player_state.dart';
import '../../../music_player/presentation/pages/music_player_page.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  void _showFullPlayer(BuildContext context) {
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
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, state) {
        if (state is! PlayerLoaded) return const SizedBox.shrink();

        final track = state.track;

        return GestureDetector(
          onTap: () => _showFullPlayer(context),
          child: Container(
            height: 64,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.kSurfaceContainerColor.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              track.albumArtUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 40,
                                    height: 40,
                                    color:
                                        AppTheme.kSurfaceContainerHighestColor,
                                    child: const Icon(
                                      Icons.music_note,
                                      color: AppTheme.kPrimaryColor,
                                      size: 20,
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track.title,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  track.artist,
                                  style: Theme.of(context).textTheme.labelSmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              context.read<PlayerCubit>().toggleFavorite();
                              HapticFeedback.mediumImpact();
                            },
                            tooltip: track.isFavorite
                                ? 'Remove from favorites'
                                : 'Add to favorites',
                            icon: Icon(
                              track.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: AppTheme.kPrimaryColor,
                              size: 20,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              context.read<PlayerCubit>().togglePlayPause();
                              HapticFeedback.mediumImpact();
                            },
                            tooltip: track.isPlaying ? 'Pause' : 'Play',
                            icon: Icon(
                              track.isPlaying ? Icons.pause : Icons.play_arrow,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Progress bar at the top
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: StreamBuilder<Duration>(
                    stream: AudioService.position,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final duration = track.duration;
                      final progress = duration.inMilliseconds > 0
                          ? position.inMilliseconds / duration.inMilliseconds
                          : 0.0;

                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.kPrimaryColor,
                                Color(0xFF00E5FF),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(1),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.kPrimaryColor.withOpacity(0.5),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
