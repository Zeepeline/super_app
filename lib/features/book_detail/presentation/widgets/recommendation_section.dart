import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:super_app/core/services/books/book_store_service.dart';
import 'package:super_app/core/theme/app_theme.dart';

class RecommendationSection extends StatelessWidget {
  final List<BookRecommendation> recommendations;

  const RecommendationSection({super.key, required this.recommendations});

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECOMMENDATIONS',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.kPrimaryColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: recommendations.map((book) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: AppTheme.kSurfaceContainerLowColor,
                        ),
                        child:
                            book.coverUrl != null && book.coverUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: book.coverUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Shimmer.fromColors(
                                      baseColor:
                                          AppTheme.kSurfaceContainerLowColor,
                                      highlightColor:
                                          AppTheme.kSurfaceContainerHighColor,
                                      child: Container(color: Colors.white),
                                    ),
                                errorWidget: (context, url, error) {
                                  return _buildPlaceholder(context, book.title);
                                },
                              )
                            : _buildPlaceholder(context, book.title),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      book.title.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.kPrimaryColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(BuildContext context, String title) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.kSurfaceContainerLowColor,
            AppTheme.kSurfaceContainerHighColor,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.book_outlined,
                color: AppTheme.kPrimaryColor.withValues(alpha: 0.5),
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
