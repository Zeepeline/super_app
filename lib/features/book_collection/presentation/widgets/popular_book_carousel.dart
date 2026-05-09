import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:super_app/core/services/books/book_store_service.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/features/book_collection/presentation/pages/book_recommendation_detail_page.dart';
import 'package:super_app/injection_container.dart';

class PopularBookCarousel extends StatelessWidget {
  const PopularBookCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BookRecommendation>>(
      future: sl<BookStoreService>().getPopularBooks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final books = snapshot.data ?? [];
        if (books.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.trending_up,
                    color: AppTheme.kPrimaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TRENDING NOW',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.85),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  return _buildCarouselItem(context, books[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCarouselItem(BuildContext context, BookRecommendation book) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                BookRecommendationDetailPage(recommendation: book),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.kSurfaceContainerLowColor,
              AppTheme.kBackgroundColor.withOpacity(0.5),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.auto_awesome,
                size: 100,
                color: AppTheme.kPrimaryColor.withOpacity(0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Hero(
                    tag: 'popular_${book.title}',
                    child: Container(
                      width: 100,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(5, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          book.coverUrl ??
                              'https://images.unsplash.com/photo-1544947950-fa07a98d237f?q=80&w=400',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: AppTheme.kSurfaceContainerHighColor,
                                child: const Icon(
                                  Icons.book,
                                  color: AppTheme.kPrimaryColor,
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.kPrimaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            book.genre.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.kPrimaryColor,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          book.title,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'by ${book.author}',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.kPrimaryColor,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            'EXPLORE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            width: 150,
            height: 15,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 24),
            itemCount: 2,
            itemBuilder: (context, index) => Container(
              width: 300,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
