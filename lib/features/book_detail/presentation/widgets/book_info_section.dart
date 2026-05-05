import 'package:flutter/material.dart';
import 'package:super_app/core/theme/app_theme.dart';

class BookInfoSection extends StatelessWidget {
  const BookInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'SYNOPSIS'),
        const SizedBox(height: 12),
        Text(
          'In the silence of the obsidian fields, the rhythm of the old world still beats. "Obsidian Rhythm" explores the intersection of ancient geology and futuristic sonic landscapes, following a curator who uncovers a digital signal frozen in volcanic glass for over three millennia.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.6,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'As the protagonist delves deeper into the...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.6,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 40),
        _buildSectionTitle(context, 'INFORMATION'),
        const SizedBox(height: 20),
        _buildInfoRow(context, 'PUBLISHED', 'October 2023'),
        const SizedBox(height: 16),
        _buildInfoRow(context, 'LANGUAGE', 'English (US)'),
        const SizedBox(height: 16),
        _buildInfoRow(context, 'ISBN', '978-3-16-148410-0'),
        const SizedBox(height: 24),
        _buildSectionTitle(context, 'GENRE TAGS'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            GenreTag(label: 'HARD SCIENCE'),
            GenreTag(label: 'CYBERPUNK'),
            GenreTag(label: 'EDITORIAL'),
          ],
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
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 10,
          ),
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
