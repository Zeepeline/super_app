import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_app/core/theme/app_theme.dart';
import '../controllers/player_ui_controller.dart';

class BottomActions extends StatelessWidget {
  final Function(String) onActionTap;
  final PlayerUIController controller = Get.find<PlayerUIController>();

  BottomActions({super.key, required this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLyricsActive = controller.showLyrics.value;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.lyrics_outlined,
            label: 'Lyrics',
            isActive: isLyricsActive,
            onTap: () => onActionTap('lyrics'),
          ),
          _ActionButton(
            icon: Icons.queue_music,
            label: 'Queue',
            onTap: () => onActionTap('queue'),
          ),
          _ActionButton(
            icon: Icons.devices,
            label: 'Output',
            onTap: () => onActionTap('devices'),
          ),
          _ActionButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () => onActionTap('share'),
          ),
        ],
      );
    });
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final RxBool _isHovered = false.obs;

  _ActionButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _isHovered.value = true,
      onExit: (_) => _isHovered.value = false,
      child: GestureDetector(
        onTap: onTap,
        child: Obx(
          () => AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: (_isHovered.value || isActive) ? 1.0 : 0.6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: (_isHovered.value || isActive)
                        ? Colors.white
                        : AppTheme.kOnSurfaceVariantColor,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label.toUpperCase(),
                    style: AppTheme.darkTheme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8, // 0.2em
                      color: (_isHovered.value || isActive)
                          ? AppTheme.kPrimaryColor
                          : AppTheme.kOnSurfaceVariantColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
