import 'dart:io';

import 'package:flutter/material.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/features/book_collection/data/models/local_book.dart';

import '../widgets/book_action_buttons.dart';
import '../widgets/book_detail_status_card.dart';
import '../widgets/book_info_section.dart';
import '../widgets/recommendation_section.dart';

class BookDetailPage extends StatelessWidget {
  final LocalBook book;

  const BookDetailPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeroImage(context),
                  const SizedBox(height: 40),
                  _buildTitleAuthor(context),
                  const SizedBox(height: 16),
                  _buildMetadata(context),
                  const SizedBox(height: 40),
                   BookDetailStatusCard(
                    progress: 0.0,
                    timeLeft: 'Ready to read',
                    book: book,
                  ),
                  const SizedBox(height: 40),
                  BookActionButtons(book: book),
                  const SizedBox(height: 40),
                  const BookInfoSection(),
                  const SizedBox(height: 40),
                  const RecommendationSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () {},
        ),
      ],
      pinned: true,
    );
  }

  Widget _buildHeroImage(BuildContext context) {
    print(book.coverPath);
    return Center(
      child: Container(
        height: 320,
        width: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.kPrimaryColor.withValues(alpha: 0.2),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
          image: DecorationImage(
            image: book.coverPath != null
                ? FileImage(File(book.coverPath!))
                : const NetworkImage(
                        'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?auto=format&fit=crop&q=80&w=400',
                      )
                      as ImageProvider,
            fit: BoxFit.cover,
          ),
        ),
        alignment: Alignment.bottomLeft,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${book.format} EDITION',
            style: const TextStyle(
              color: AppTheme.kPrimaryColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleAuthor(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book.title.toUpperCase(),
          style: Theme.of(
            context,
          ).textTheme.displayLarge?.copyWith(fontSize: 32),
        ),
        const SizedBox(height: 4),
        Text(
          book.author.toUpperCase(),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.kPrimaryColor,
            fontSize: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadata(BuildContext context) {
    return Row(
      children: [
        _buildMetaItem(
          context,
          Icons.insert_drive_file_outlined,
          '${book.format} Format',
        ),
        const SizedBox(width: 16),
        _buildMetaItem(context, Icons.data_usage_outlined, 'Local File'),
        const SizedBox(width: 16),
        _buildMetaItem(context, Icons.menu_book_outlined, 'Offline'),
      ],
    );
  }

  Widget _buildMetaItem(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}
