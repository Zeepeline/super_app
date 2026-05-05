import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_app/core/services/books/book_library_service.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/features/book_collection/data/models/local_book.dart';
import 'package:super_app/features/book_search/presentation/pages/book_search_page.dart';
import 'package:super_app/injection_container.dart';

import '../widgets/book_header.dart';
import '../widgets/book_library_grid.dart';
import '../widgets/book_tabs.dart';
import '../widgets/featured_book_card.dart';

class BookCollectionPage extends StatefulWidget {
  const BookCollectionPage({super.key});

  @override
  State<BookCollectionPage> createState() => _BookCollectionPageState();
}

class _BookCollectionPageState extends State<BookCollectionPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: [
                _buildLibraryView(context),
                const BookSearchPage(showAppBar: false),
                const Center(
                  child: Text(
                    'Notes Coming Soon',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const Center(
                  child: Text(
                    'Settings Coming Soon',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomNav(context),
            ),
          ],
        ),
      ),
      floatingActionButton:
          _currentIndex == 0
              ? Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: FloatingActionButton(
                  onPressed: () {},
                  backgroundColor: AppTheme.kPrimaryColor,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add, color: Colors.black, size: 32),
                ),
              )
              : null,
    );
  }

  Widget _buildLibraryView(BuildContext context) {
    final bookLibraryService = sl<BookLibraryService>();
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const BookHeader(),
          const SizedBox(height: 24),
          const BookTabs(tabs: ['All', 'Reading', 'Finished']),
          const SizedBox(height: 24),
          FutureBuilder<List<LocalBook>>(
            future: bookLibraryService.getDownloadedBooks(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final featured = snapshot.data!.first;

                return FutureBuilder<Map<String, int>>(
                  future: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final current =
                        prefs.getInt('book_progress_${featured.id}') ?? 0;
                    final total =
                        prefs.getInt('book_total_${featured.id}') ?? 0;
                    return {'current': current, 'total': total};
                  }(),
                  builder: (context, progressSnapshot) {
                    final current = progressSnapshot.data?['current'] ?? 0;
                    final total = progressSnapshot.data?['total'] ?? 0;
                    final percent = total > 0 ? (current / total) : 0.0;

                    return FeaturedBookCard(
                      book: featured,
                      progress: percent,
                      timeLeft: percent > 0
                          ? '${(100 - (percent * 100)).toInt()}% left'
                          : 'Ready to read',
                    );
                  },
                );
              }

              // Fallback dummy book
              final dummyBook = LocalBook(
                id: 'dummy',
                title: 'The Great Gatsby',
                author: 'F. Scott Fitzgerald',
                path: '',
                format: 'EPUB',
              );

              return FeaturedBookCard(
                book: dummyBook,
                progress: 0.65,
                timeLeft: '2 hours left',
              );
            },
          ),
          const SizedBox(height: 40),
          FutureBuilder<List<LocalBook>>(
            future: bookLibraryService.getDownloadedBooks(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final books = snapshot.data ?? [];

              if (books.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "No books downloaded yet. Go to Store to find some!",
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              return BookLibraryGrid(books: books);
            },
          ),
          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppTheme.kBackgroundColor.withValues(alpha: 0.4),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, Icons.book_outlined, 'LIBRARY', 0),
              _buildNavItem(context, Icons.storefront_outlined, 'STORE', 1),
              _buildNavItem(context, Icons.notes_outlined, 'NOTES', 2),
              _buildNavItem(context, Icons.settings_outlined, 'SETTINGS', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
  ) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        color: Colors.transparent, // Expand tap area
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.kPrimaryColor : Colors.white70,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.kPrimaryColor : Colors.white70,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
