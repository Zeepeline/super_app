import 'package:flutter/material.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/features/book_collection/data/models/local_book.dart';
import 'package:super_app/features/book_reader/presentation/pages/book_reader_page.dart';

class BookActionButtons extends StatelessWidget {
  final LocalBook book;

  const BookActionButtons({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookReaderPage(book: book),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.kPrimaryColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.play_arrow, size: 24),
            label: const Text(
              'READ NOW',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSecondaryButton(
                context,
                icon: Icons.headphones_outlined,
                label: 'AUDIO',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSecondaryButton(
                context,
                icon: Icons.settings_outlined,
                label: 'CONFIG',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryButton(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.kSurfaceContainerLowColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
