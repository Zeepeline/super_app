import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/features/music_player/domain/entities/track_entity.dart';
import '../controllers/player_ui_controller.dart';

class SeekBar extends StatelessWidget {
  final TrackEntity track;
  final ValueChanged<Duration> onSeek;
  final PlayerUIController controller = Get.find<PlayerUIController>();

  SeekBar({super.key, required this.track, required this.onSeek});

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: controller.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? track.currentPosition;
        final duration = track.duration;

        return Obx(() {
          // Calculate progress accurately
          double progress = controller.isDragging.value
              ? controller.dragValue.value
              : (duration.inMilliseconds > 0
                    ? position.inMilliseconds / duration.inMilliseconds
                    : 0.0);

          return Column(
            children: [
              // Liquid Slider
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape:
                      (controller.isDragging.value ||
                          controller.isAlbumArtHovered.value)
                      ? const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                          elevation: 4,
                        )
                      : const RoundSliderThumbShape(enabledThumbRadius: 0),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 12,
                  ),
                  activeTrackColor: AppTheme.kPrimaryColor,
                  inactiveTrackColor: AppTheme.kOutlineVariantColor.withValues(
                    alpha: 0.3,
                  ),
                  thumbColor: Colors.white,
                  overlayColor: AppTheme.kPrimaryColor.withValues(alpha: 0.2),
                  trackShape: const RectangularSliderTrackShape(),
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: (value) {
                    controller.startDragging(value);
                  },
                  onChangeEnd: (value) {
                    final newPosition = Duration(
                      milliseconds: (value * duration.inMilliseconds).round(),
                    );
                    onSeek(newPosition);
                    controller.stopDragging();
                  },
                ),
              ),
              const SizedBox(height: 4),
              // Time labels (Editorial Label)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(
                        controller.isDragging.value
                            ? Duration(
                                milliseconds:
                                    (controller.dragValue.value *
                                            duration.inMilliseconds)
                                        .round(),
                              )
                            : position,
                      ),
                      style: AppTheme.darkTheme.textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.55, // 0.05em
                        color: AppTheme.kOnSurfaceVariantColor,
                      ),
                    ),
                    Text(
                      _formatDuration(duration),
                      style: AppTheme.darkTheme.textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.55,
                        color: AppTheme.kOnSurfaceVariantColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        });
      },
    );
  }
}
