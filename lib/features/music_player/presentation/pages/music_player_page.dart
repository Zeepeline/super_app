import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/features/music_player/domain/entities/track_entity.dart';
import 'package:super_app/features/music_player/presentation/cubit/player_cubit.dart';
import 'package:super_app/features/music_player/presentation/widgets/album_art_card.dart';
import 'package:super_app/features/music_player/presentation/widgets/lyrics_view.dart';
import 'package:super_app/features/music_player/presentation/widgets/playback_controls.dart';
import 'package:super_app/features/music_player/presentation/widgets/seek_bar.dart';
import 'package:super_app/features/music_player/presentation/widgets/track_info.dart';

import '../controllers/player_ui_controller.dart';

class MusicPlayerPage extends StatelessWidget {
  const MusicPlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PlayerUIController());
    controller.bindCubit(context.read<PlayerCubit>());

    // Trigger load if necessary (equivalent to initState)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlayerCubit>().loadPlayer();
    });

    return Obx(() {
      final track = controller.currentTrack.value;

      if (track == null) {
        return const Scaffold(
          backgroundColor: AppTheme.kBackgroundColor,
          body: Center(
            child: CircularProgressIndicator(color: AppTheme.kPrimaryColor),
          ),
        );
      }

      return Scaffold(
        backgroundColor: AppTheme.kBackgroundColor,
        body: Stack(
          children: [
            // Background Mesh & Blur
            Stack(
              children: [
                // Base Surface
                Container(color: AppTheme.kBackgroundColor),
                // Corner Gradients (Mesh)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topLeft,
                        radius: 1.0,
                        colors: [
                          AppTheme.kPrimaryContainerColor.withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topRight,
                        radius: 1.0,
                        colors: [
                          AppTheme.kPrimaryColor.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.bottomRight,
                        radius: 1.0,
                        colors: [
                          const Color(0xFF006E2D).withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Blurred album art background layer
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.25,
                    child: Image.network(
                      track.albumArtUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.0,
                            colors: [
                              AppTheme.kPrimaryColor.withOpacity(0.2),
                              AppTheme.kBackgroundColor,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Backdrop Blur
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.kBackgroundColor.withOpacity(0.2),
                          AppTheme.kBackgroundColor.withOpacity(0.4),
                          AppTheme.kBackgroundColor,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Header (Editorial Style)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.expand_more,
                        color: AppTheme.kOnSurfaceVariantColor,
                        size: 28,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "PLAYING FROM PLAYLIST",
                            style: AppTheme.darkTheme.textTheme.labelSmall
                                ?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.2, // 0.2em
                                  color: AppTheme.kOnSurfaceVariantColor,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Midnight Sessions", // Could be dynamic if available
                            style: AppTheme.darkTheme.textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.2,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        context.read<PlayerCubit>().toggleLyrics();
                      },
                      icon: const Icon(
                        Icons.lyrics_outlined,
                        color: AppTheme.kOnSurfaceVariantColor,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Main Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 900) {
                      return _buildLargeLayout(track, context, controller);
                    }
                    return _buildPortraitLayout(track, context, controller);
                  },
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPortraitLayout(
    TrackEntity track,
    BuildContext context,
    PlayerUIController controller,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Main Content Area (Album Art or Lyrics)
        Expanded(
          child: Obx(
            () => controller.showLyrics.value
                ? LyricsView(
                    key: const ValueKey('lyrics'),
                    syncedLyrics: track.syncedLyrics,
                    plainLyrics: track.plainLyrics,
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: AlbumArtCard(albumArtUrl: track.albumArtUrl),
                      ),
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 24),

        // Track Info & Metadata
        TrackInfo(
          onFavoriteToggle: () {
            context.read<PlayerCubit>().toggleFavorite();
          },
        ),

        const SizedBox(height: 32),

        // Progress Bar (SeekBar)
        SeekBar(
          track: track,
          onSeek: (position) {
            context.read<PlayerCubit>().seekTo(position);
          },
        ),

        const SizedBox(height: 32),

        // Playback Controls
        PlaybackControls(
          onPlayPause: () => context.read<PlayerCubit>().togglePlayPause(),
          onSkipNext: () => context.read<PlayerCubit>().skipToNext(),
          onSkipPrevious: () => context.read<PlayerCubit>().skipToPrevious(),
          onShuffle: () => context.read<PlayerCubit>().toggleShuffle(),
          onRepeat: () => context.read<PlayerCubit>().toggleRepeat(),
        ),

        // const SizedBox(height: 48),

        // Bottom Actions
        // BottomActions(
        //   onActionTap: (action) {
        //     if (action == 'lyrics') {
        //       context.read<PlayerCubit>().toggleLyrics();
        //     }
        //   },
        // ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLargeLayout(
    TrackEntity track,
    BuildContext context,
    PlayerUIController controller,
  ) {
    return Row(
      children: [
        // Left Side: Album Art / Lyrics
        Expanded(
          flex: 1,
          child: Obx(
            () => controller.showLyrics.value
                ? LyricsView(
                    key: const ValueKey('lyrics'),
                    syncedLyrics: track.syncedLyrics,
                    plainLyrics: track.plainLyrics,
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 500,
                        maxHeight: 500,
                      ),
                      child: AlbumArtCard(albumArtUrl: track.albumArtUrl),
                    ),
                  ),
          ),
        ),

        const SizedBox(width: 64),

        // Right Side: Info & Controls
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TrackInfo(
                onFavoriteToggle: () {
                  context.read<PlayerCubit>().toggleFavorite();
                },
              ),
              const SizedBox(height: 48),
              SeekBar(
                track: track,
                onSeek: (position) {
                  context.read<PlayerCubit>().seekTo(position);
                },
              ),
              const SizedBox(height: 48),
              PlaybackControls(
                onPlayPause: () =>
                    context.read<PlayerCubit>().togglePlayPause(),
                onSkipNext: () => context.read<PlayerCubit>().skipToNext(),
                onSkipPrevious: () =>
                    context.read<PlayerCubit>().skipToPrevious(),
                onShuffle: () => context.read<PlayerCubit>().toggleShuffle(),
                onRepeat: () => context.read<PlayerCubit>().toggleRepeat(),
              ),
              const SizedBox(height: 64),
              // BottomActions(
              //   onActionTap: (action) {
              //     if (action == 'lyrics') {
              //       context.read<PlayerCubit>().toggleLyrics();
              //     }
              //   },
              // ),
            ],
          ),
        ),
      ],
    );
  }
}
