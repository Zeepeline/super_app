import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:super_app/core/theme/app_theme.dart';
import '../controllers/player_ui_controller.dart';

class TrackInfo extends StatelessWidget {
  final VoidCallback onFavoriteToggle;
  final PlayerUIController controller = Get.find<PlayerUIController>();

  TrackInfo({super.key, required this.onFavoriteToggle});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final track = controller.currentTrack.value;
      if (track == null) return const SizedBox.shrink();

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
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.64, // -2% of 32
                            height: 1.1,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Artist name - Utility Medium
                    Text(
                      track.artist,
                      style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.kOnSurfaceVariantColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Favorite button with Pulse effect
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
                              color: AppTheme.kPrimaryColor.withOpacity(0.4),
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
