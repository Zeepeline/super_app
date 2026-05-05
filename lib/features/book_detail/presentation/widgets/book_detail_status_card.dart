import 'package:flutter/material.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/features/book_collection/data/models/local_book.dart';
import 'package:super_app/features/book_reader/presentation/pages/book_reader_page.dart';

class BookDetailStatusCard extends StatelessWidget {
  final double progress;
  final String timeLeft;
  final LocalBook book;

  const BookDetailStatusCard({
    super.key,
    required this.progress,
    required this.timeLeft,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookReaderPage(book: book)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.kSurfaceContainerLowColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CURRENT STATUS',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${(progress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppTheme.kPrimaryColor,
                    fontSize: 40,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'REMAINING',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(fontSize: 8),
                    ),
                    Text(
                      '~ $timeLeft',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              'COMPLETED',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppTheme.kPrimaryColor,
                height: 0.8,
              ),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.kSurfaceContainerHighestColor,
                valueColor: const AlwaysStoppedAnimation(
                  AppTheme.kPrimaryColor,
                ),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
