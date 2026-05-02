import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/features/music_player/domain/entities/track_entity.dart';
import 'package:super_app/features/music_player/presentation/cubit/player_cubit.dart';
import 'package:super_app/features/music_player/presentation/widgets/lyrics_view.dart';
import 'package:super_app/features/music_player/presentation/widgets/playback_controls.dart';
import 'package:super_app/features/music_player/presentation/widgets/seek_bar.dart';
import 'package:super_app/features/music_player/presentation/widgets/track_info.dart';
import 'package:super_app/features/music_player/presentation/widgets/vinyl_record.dart';

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
            _buildBackground(track),
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
                                  letterSpacing: 2.2,
                                  color: AppTheme.kOnSurfaceVariantColor,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Midnight Sessions",
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

  Widget _buildBackground(TrackEntity track) {
    return Stack(
      children: [
        // Base Surface (#0e0e0e)
        Container(color: const Color(0xFF0E0E0E)),

        // Mesh gradient layer (4 corner radials, opacity 40%)
        Positioned.fill(
          child: Opacity(
            opacity: 0.40,
            child: Stack(
              children: [
                // Top-left: primary-container green
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topLeft,
                        radius: 0.8,
                        colors: [
                          const Color(0xFF1CB853).withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Top-right: primary green
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topRight,
                        radius: 0.8,
                        colors: [
                          const Color(0xFF72FE8F).withOpacity(0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Bottom-right: dark green
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.bottomRight,
                        radius: 0.8,
                        colors: [
                          const Color(0xFF006E2D).withOpacity(0.20),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Bottom-left: surface variant
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.bottomLeft,
                        radius: 0.8,
                        colors: [
                          const Color(0xFF262626),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Blurred album art ambient layer (blur 60px, saturate, opacity 60%)
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: 60,
              sigmaY: 60,
              tileMode: TileMode.decal,
            ),
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                1.5, 0, 0, 0, 0, // Red
                0, 1.5, 0, 0, 0, // Green (boosted for saturate)
                0, 0, 1.5, 0, 0, // Blue
                0, 0, 0, 0.6, 0, // Alpha (60% opacity)
              ]),
              child: Image.network(
                track.albumArtUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),

        // Gradient overlay: from-surface/20 via-surface/40 to-surface
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.5, 1.0],
                colors: [
                  const Color(0xFF0E0E0E).withOpacity(0.20),
                  const Color(0xFF0E0E0E).withOpacity(0.40),
                  const Color(0xFF0E0E0E),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildPortraitLayout(
    TrackEntity track,
    BuildContext context,
    PlayerUIController controller,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Main Content Area (Vinyl Record or Lyrics)
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Obx(
                        () => VinylRecord(
                          albumArtUrl: track.albumArtUrl,
                          isPlaying: controller.isPlaying.value,
                        ),
                      ),
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // Track Info & Metadata
        TrackInfo(
          onFavoriteToggle: () {
            context.read<PlayerCubit>().toggleFavorite();
          },
        ),

        const SizedBox(height: 24),

        // Progress Bar (SeekBar)
        SeekBar(
          track: track,
          onSeek: (position) {
            context.read<PlayerCubit>().seekTo(position);
          },
        ),

        const SizedBox(height: 24),

        // Playback Controls
        PlaybackControls(
          onPlayPause: () => context.read<PlayerCubit>().togglePlayPause(),
          onSkipNext: () => context.read<PlayerCubit>().skipToNext(),
          onSkipPrevious: () => context.read<PlayerCubit>().skipToPrevious(),
          onShuffle: () => context.read<PlayerCubit>().toggleShuffle(),
          onRepeat: () => context.read<PlayerCubit>().toggleRepeat(),
        ),

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
        // Left Side: Vinyl / Lyrics
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
                      child: Obx(
                        () => VinylRecord(
                          albumArtUrl: track.albumArtUrl,
                          isPlaying: controller.isPlaying.value,
                        ),
                      ),
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
            ],
          ),
        ),
      ],
    );
  }
}
