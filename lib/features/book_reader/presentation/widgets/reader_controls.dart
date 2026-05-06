import 'package:flutter/material.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/features/book_collection/data/models/local_book.dart';

class ReaderControls extends StatelessWidget {
  final LocalBook book;
  final bool isVerticalMode;
  final VoidCallback onToggleMode;

  const ReaderControls({
    super.key,
    required this.book,
    required this.isVerticalMode,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.kSurfaceContainerHighColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.list, color: Colors.white70),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              isVerticalMode ? Icons.swap_vert : Icons.swap_horiz,
              color: AppTheme.kPrimaryColor,
            ),
            onPressed: onToggleMode,
            tooltip: isVerticalMode ? 'Switch to Swipe' : 'Switch to Scroll',
          ),
          IconButton(
            icon: const Icon(Icons.wb_sunny_outlined, color: Colors.white70),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.white70),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
