import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class EmptyLibraryView extends StatelessWidget {
  final VoidCallback onImportPressed;

  const EmptyLibraryView({super.key, required this.onImportPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Premium Illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.kPrimaryColor.withOpacity(0.2),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.music_note_rounded,
                    size: 64,
                    color: AppTheme.kPrimaryColor.withOpacity(0.8),
                  ),
                  Positioned(
                    right: 20,
                    top: 20,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E5FF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0xFF00E5FF), blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            // Typography
            Text(
              'THE CURATOR\'S\nSILENCE',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 32,
                height: 1.0,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your digital library is a blank canvas. Start importing your collection to define your rhythm.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.5),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            // Premium Button
            GestureDetector(
              onTap: onImportPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: AppTheme.kPrimaryColor.withOpacity(0.5),
                  ),
                  color: AppTheme.kPrimaryColor.withOpacity(0.05),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      color: AppTheme.kPrimaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'IMPORT COLLECTION',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.kPrimaryColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
