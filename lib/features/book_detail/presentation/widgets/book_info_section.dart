import 'package:flutter/material.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/features/book_collection/data/models/local_book.dart';

class BookInfoSection extends StatelessWidget {
  final LocalBook book;

  const BookInfoSection({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'SYNOPSIS'),
        const SizedBox(height: 12),
        Text(
          book.synopsis ?? 'No synopsis available for this title.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.6,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 40),
        _buildSectionTitle(context, 'INFORMATION'),
        const SizedBox(height: 20),
        _buildInfoRow(context, 'PUBLISHED', book.publishDate ?? 'Unknown'),
        const SizedBox(height: 16),
        _buildInfoRow(context, 'LANGUAGE', 'English (US)'),
        const SizedBox(height: 16),
        _buildInfoRow(context, 'FORMAT', book.format),
        const SizedBox(height: 24),
        _buildSectionTitle(context, 'GENRE TAGS'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (book.genreTags ?? ['LOCAL'])
              .map((tag) => GenreTag(label: tag.toUpperCase()))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppTheme.kPrimaryColor,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class GenreTag extends StatelessWidget {
  final String label;

  const GenreTag({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.kSurfaceContainerHighestColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.kPrimaryColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
