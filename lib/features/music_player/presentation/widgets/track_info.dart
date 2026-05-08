import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/features/youtube/presentation/controllers/youtube_controller.dart';
import 'package:super_app/features/music_player/presentation/cubit/player_cubit.dart';

import '../controllers/player_ui_controller.dart';

class TrackInfo extends StatelessWidget {
  final VoidCallback onFavoriteToggle;
  final PlayerUIController controller = Get.find<PlayerUIController>();
  final YouTubeController ytController = Get.find<YouTubeController>();

  TrackInfo({super.key, required this.onFavoriteToggle});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final track = controller.currentTrack.value;
      if (track == null) return const SizedBox.shrink();

      final isStream = track.localPath == null || track.localPath!.isEmpty;
      final videoId = track.id;
      final downloadState = ytController.downloadStates[videoId];
      final isDownloading = downloadState?.isDownloading ?? false;
      final progress = ytController.downloadProgress[videoId] ?? 0.0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Track title - Editorial Headline
                    Text(
                      track.title,
                      style: AppTheme.darkTheme.textTheme.displayLarge
                          ?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.64, // -2% of 32
                            height: 1.1,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Artist name - Utility Medium
                    Text(
                      track.artist,
                      style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.kOnSurfaceVariantColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Action Button (Download if stream, Favorite if local)
              if (isStream)
                GestureDetector(
                  onTap: isDownloading
                      ? null
                      : () => ytController.downloadTrack(
                          track,
                          playerCubit: context.read<PlayerCubit>(),
                        ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: isDownloading
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  value: progress > 0 ? progress : null,
                                  color: AppTheme.kPrimaryColor,
                                  strokeWidth: 2,
                                ),
                              ),
                              const Icon(
                                Icons.download,
                                size: 16,
                                color: AppTheme.kPrimaryColor,
                              ),
                            ],
                          )
                        : const Icon(
                            Icons.download_rounded,
                            size: 32,
                            color: AppTheme.kOnSurfaceVariantColor,
                          ),
                  ),
                )
              else
                GestureDetector(
                  onTap: onFavoriteToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: track.isFavorite
                          ? [
                              BoxShadow(
                                color: AppTheme.kPrimaryColor.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      track.isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 32,
                      color: track.isFavorite
                          ? AppTheme.kPrimaryColor
                          : AppTheme.kOnSurfaceVariantColor,
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    });
  }
}
