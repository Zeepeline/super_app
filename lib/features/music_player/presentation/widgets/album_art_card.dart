import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_app/core/theme/app_theme.dart';

import '../controllers/player_ui_controller.dart';

class AlbumArtCard extends StatelessWidget {
  final String albumArtUrl;
  final PlayerUIController controller = Get.find<PlayerUIController>();

  AlbumArtCard({super.key, required this.albumArtUrl});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => controller.setAlbumArtHover(true),
      onExit: (_) => controller.setAlbumArtHover(false),
      child: Obx(
        () => AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..scale(controller.isAlbumArtHovered.value ? 1.02 : 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.7),
                blurRadius: 60,
                offset: const Offset(0, 30),
                spreadRadius: -15,
              ),
              if (controller.isAlbumArtHovered.value)
                BoxShadow(
                  color: AppTheme.kPrimaryColor.withOpacity(0.1),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.network(
              albumArtUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 420,
                  height: 420,
                  decoration: const BoxDecoration(
                    color: AppTheme.kSurfaceContainerLowColor,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.kSurfaceContainerLowColor,
                        AppTheme.kSurfaceContainerColor,
                      ],
                    ),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppTheme.kPrimaryColor.withOpacity(0.5),
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 420,
                  height: 420,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.kSurfaceContainerHighestColor,
                        AppTheme.kBackgroundColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_off_outlined,
                        size: 80,
                        color: AppTheme.kPrimaryColor.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Artwork Unavailable",
                        style: AppTheme.darkTheme.textTheme.labelSmall
                            ?.copyWith(
                              color: AppTheme.kOnSurfaceVariantColor.withValues(
                                alpha: 0.5,
                              ),
                              letterSpacing: 1.2,
                            ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
