import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_app/core/services/books/book_library_service.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/features/book_collection/data/models/local_book.dart';
import 'package:super_app/injection_container.dart';

import '../widgets/book_header.dart';
import '../widgets/book_library_grid.dart';
import '../widgets/book_tabs.dart';
import '../widgets/external_sources_list.dart';
import '../widgets/featured_book_card.dart';

class BookCollectionPage extends StatelessWidget {
  const BookCollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bookLibraryService = sl<BookLibraryService>();

    return Scaffold(
      backgroundColor: AppTheme.kBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const BookHeader(),
              const SizedBox(height: 24),
              const BookTabs(tabs: ['All', 'Reading', 'Finished', 'Sources']),
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
              const ExternalSourcesList(),
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
                        "No books downloaded yet. Go to Search to find some!",
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
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppTheme.kPrimaryColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.black, size: 32),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: AppTheme.kSurfaceContainerLowColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, Icons.book_outlined, 'LIBRARY', true),
          _buildNavItem(context, Icons.storefront_outlined, 'STORE', false),
          _buildNavItem(context, Icons.notes_outlined, 'NOTES', false),
          _buildNavItem(context, Icons.settings_outlined, 'SETTINGS', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isActive,
  ) {
    return Column(
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
    );
  }
}

Widget _buildBottomNav(BuildContext context) {
  return Container(
    height: 80,
    decoration: const BoxDecoration(color: AppTheme.kSurfaceContainerLowColor),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildNavItem(context, Icons.book_outlined, 'LIBRARY', true),
        _buildNavItem(context, Icons.storefront_outlined, 'STORE', false),
        _buildNavItem(context, Icons.notes_outlined, 'NOTES', false),
        _buildNavItem(context, Icons.settings_outlined, 'SETTINGS', false),
      ],
    ),
  );
}

Widget _buildNavItem(
  BuildContext context,
  IconData icon,
  String label,
  bool isActive,
) {
  return Column(
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
  );
}
