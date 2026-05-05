import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:super_app/core/services/book_store_service.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/injection_container.dart';
import '../bloc/book_search_bloc.dart';
import '../widgets/book_search_result_item.dart';

class BookSearchPage extends StatelessWidget {
  const BookSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<BookSearchBloc>(),
      child: const BookSearchView(),
    );
  }
}

class BookSearchView extends StatefulWidget {
  const BookSearchView({super.key});

  @override
  State<BookSearchView> createState() => _BookSearchViewState();
}

class _BookSearchViewState extends State<BookSearchView> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _genres = ['Fiction', 'Technology', 'Self-Help', 'History', 'Science', 'Mystery'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Book Store'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSearchField(context),
          Expanded(
            child: BlocBuilder<BookSearchBloc, BookSearchState>(
              builder: (context, state) {
                if (state is BookSearchInitial) {
                  return _buildStoreHome(context);
                } else if (state is BookSearchLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.kPrimaryColor));
                } else if (state is BookSearchLoaded) {
                  if (state.results.isEmpty) {
                    return const Center(child: Text('No results found.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: state.results.length,
                    itemBuilder: (context, index) {
                      return BookSearchResultItem(result: state.results[index]);
                    },
                  );
                } else if (state is BookSearchError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.kSurfaceContainerLowColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Title, author, or genre...',
            hintStyle: TextStyle(color: Colors.white38),
            border: InputBorder.none,
            icon: Icon(Icons.search, color: AppTheme.kPrimaryColor),
          ),
          onSubmitted: (value) {
            context.read<BookSearchBloc>().add(PerformBookSearch(value));
          },
        ),
      ),
    );
  }

  Widget _buildStoreHome(BuildContext context) {
    final storeService = sl<BookStoreService>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Genre Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Wrap(
              spacing: 8,
              children: _genres.map((genre) {
                return ActionChip(
                  label: Text(genre),
                  backgroundColor: AppTheme.kSurfaceContainerLowColor,
                  labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                  onPressed: () {
                    _searchController.text = genre;
                    context.read<BookSearchBloc>().add(PerformBookSearch(genre));
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),

          // AI Recommendations
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.kPrimaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Recommended for You',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<BookRecommendation>>(
            future: storeService.getAiRecommendations(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('AI is sleeping. Try again later.'),
                );
              }

              final recommendations = snapshot.data!;
              return SizedBox(
                height: 220,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  itemCount: recommendations.length,
                  itemBuilder: (context, index) {
                    final rec = recommendations[index];
                    return _buildRecommendationCard(context, rec);
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // Popular Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Trending Books',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 16),
          _buildStaticTrendingList(context),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, BookRecommendation rec) {
    return GestureDetector(
      onTap: () {
        _searchController.text = rec.title;
        context.read<BookSearchBloc>().add(PerformBookSearch(rec.title));
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppTheme.kSurfaceContainerLowColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.menu_book, color: Colors.white24, size: 40),
            ),
            const SizedBox(height: 12),
            Text(
              rec.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              rec.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const Spacer(),
            Text(
              rec.genre,
              style: const TextStyle(color: AppTheme.kPrimaryColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticTrendingList(BuildContext context) {
    final trending = [
      {'title': 'Sapiens', 'author': 'Yuval Noah Harari'},
      {'title': 'The Alchemist', 'author': 'Paulo Coelho'},
      {'title': 'Deep Work', 'author': 'Cal Newport'},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: trending.length,
      itemBuilder: (context, index) {
        final item = trending[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 40,
            height: 50,
            color: Colors.white10,
            child: const Icon(Icons.book, size: 20),
          ),
          title: Text(item['title']!, style: const TextStyle(color: Colors.white, fontSize: 14)),
          subtitle: Text(item['author']!, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white24),
          onTap: () {
            _searchController.text = item['title']!;
            context.read<BookSearchBloc>().add(PerformBookSearch(item['title']!));
          },
        );
      },
    );
  }
}
