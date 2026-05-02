import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_app/core/theme/app_theme.dart';
import '../controllers/player_ui_controller.dart';

class PlaybackControls extends StatelessWidget {
  final VoidCallback onPlayPause;
  final VoidCallback onSkipPrevious;
  final VoidCallback onSkipNext;
  final VoidCallback onShuffle;
  final VoidCallback onRepeat;
  final PlayerUIController controller = Get.find<PlayerUIController>();

  PlaybackControls({
    super.key,
    required this.onPlayPause,
    required this.onSkipPrevious,
    required this.onSkipNext,
    required this.onShuffle,
    required this.onRepeat,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isPlaying = controller.isPlaying.value;
      final isShuffle = controller.isShuffle.value;
      final isRepeat = controller.isRepeat.value;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Shuffle button
          IconButton(
            onPressed: onShuffle,
            icon: Icon(
              Icons.shuffle,
              color: isShuffle
                  ? AppTheme.kPrimaryColor
                  : AppTheme.kOnSurfaceVariantColor,
              shadows: isShuffle
                  ? [
                      Shadow(
                        color: AppTheme.kPrimaryColor.withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            iconSize: 24,
          ),
          // Previous button
          IconButton(
            onPressed: onSkipPrevious,
            icon: const Icon(Icons.skip_previous, color: Colors.white),
            iconSize: 40,
          ),
          // Play/Pause button with pulse gradient
          GestureDetector(
            onTap: onPlayPause,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.kPrimaryColor,
                    AppTheme.kPrimaryContainerColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.kPrimaryContainerColor.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: AppTheme.kOnPrimaryContainerColor,
                  size: 48,
                ),
              ),
            ),
          ),
          // Next button
          IconButton(
            onPressed: onSkipNext,
            icon: const Icon(Icons.skip_next, color: Colors.white),
            iconSize: 40,
          ),
          // Repeat button
          IconButton(
            onPressed: onRepeat,
            icon: Icon(
              Icons.repeat,
              color: isRepeat
                  ? AppTheme.kPrimaryColor
                  : AppTheme.kOnSurfaceVariantColor,
              shadows: isRepeat
                  ? [
                      Shadow(
                        color: AppTheme.kPrimaryColor.withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            iconSize: 24,
          ),
        ],
      );
    });
  }
}
