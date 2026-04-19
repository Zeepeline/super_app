import 'package:flutter/material.dart';
import 'package:super_app/core/theme/app_theme.dart';

class PlayerBackground extends StatelessWidget {
  final String? albumArtUrl;
  final Widget child;

  const PlayerBackground({super.key, this.albumArtUrl, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppTheme.kBackgroundColor),
      child: Stack(
        children: [
          // Mesh gradient background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.kPrimaryColor.withOpacity(0.15),
                    AppTheme.kBackgroundColor,
                    AppTheme.kPrimaryContainerColor.withOpacity(0.2),
                  ],
                ),
              ),
            ),
          ),
          // Blurred album art
          if (albumArtUrl != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.4,
                child: Image.network(
                  albumArtUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: AppTheme.kBackgroundColor);
                  },
                ),
              ),
            ),
          // Gradient overlay
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
          // Content
          child,
        ],
      ),
    );
  }
}
