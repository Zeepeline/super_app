import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/features/book_collection/data/models/local_book.dart';
import 'package:super_app/features/book_detail/presentation/pages/book_detail_page.dart';

class BookLibraryGrid extends StatelessWidget {
  final List<LocalBook> books;

  const BookLibraryGrid({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Library',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const Row(
                children: [
                  Icon(Icons.grid_view_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Icon(Icons.list_rounded, color: Colors.white70, size: 24),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 32,
            crossAxisSpacing: 20,
            childAspectRatio: 0.6,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return FutureBuilder<Map<String, int>>(
              future: () async {
                final prefs = await SharedPreferences.getInstance();
                final current = prefs.getInt('book_progress_${book.id}') ?? 0;
                final total = prefs.getInt('book_total_${book.id}') ?? 0;
                return {'current': current, 'total': total};
              }(),
              builder: (context, snapshot) {
                final current = snapshot.data?['current'] ?? 0;
                final total = snapshot.data?['total'] ?? 0;
                final percent = total > 0 ? (current / total) : 0.0;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailPage(book: book),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: book.coverPath != null
                                      ? FileImage(File(book.coverPath!))
                                      : const NetworkImage(
                                              'https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&q=80&w=400',
                                            )
                                            as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            // Format badge
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  book.format,
                                  style: const TextStyle(
                                    color: AppTheme.kPrimaryColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            // Progress bar at bottom of cover
                            if (percent > 0)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: percent,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: AppTheme.kPrimaryColor,
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              book.author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                            ),
                          ),
                          if (percent > 0)
                            Text(
                              '${(percent * 100).toInt()}%',
                              style: const TextStyle(
                                color: AppTheme.kPrimaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
