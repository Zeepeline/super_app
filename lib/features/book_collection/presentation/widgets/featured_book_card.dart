import 'dart:io';

import 'package:flutter/material.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/features/book_collection/data/models/local_book.dart';
import 'package:super_app/features/book_detail/presentation/pages/book_detail_page.dart';

class FeaturedBookCard extends StatelessWidget {
  final LocalBook book;
  final double progress;
  final String timeLeft;

  const FeaturedBookCard({
    super.key,
    required this.book,
    required this.progress,
    required this.timeLeft,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookDetailPage(book: book)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.kSurfaceContainerLowColor,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          children: [
            Container(
              height: 240,
              width: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
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
            ),
            const SizedBox(height: 32),
            Text(
              'CURRENTLY READING',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.kPrimaryColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              book.title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 4),
            Text(book.author, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.kSurfaceContainerHighestColor,
                valueColor: const AlwaysStoppedAnimation(
                  AppTheme.kPrimaryColor,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toInt()}% Completed',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(timeLeft, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
