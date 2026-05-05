import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:super_app/core/services/books/book_store_service.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/features/book_collection/data/models/local_book.dart';
import 'package:super_app/injection_container.dart';

import '../widgets/book_action_buttons.dart';
import '../widgets/book_detail_status_card.dart';
import '../widgets/book_info_section.dart';
import '../widgets/recommendation_section.dart';

class BookDetailPage extends StatefulWidget {
  final LocalBook book;

  const BookDetailPage({super.key, required this.book});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  late LocalBook currentBook;
  bool isLoadingMetadata = false;
  List<BookRecommendation> recommendations = [];

  LocalBook get book => currentBook;

  @override
  void initState() {
    super.initState();
    currentBook = widget.book;
    _fetchMetadata();
  }

  Future<void> _fetchMetadata() async {
    // Fetch similar books in parallel or after metadata
    _fetchRecommendations();

    if (currentBook.synopsis != null) return;

    setState(() {
      isLoadingMetadata = true;
    });

    try {
      final metadata = await sl<BookStoreService>().getBookMetadata(
        currentBook.title,
        currentBook.author,
      );

      if (mounted) {
        setState(() {
          currentBook = LocalBook(
            id: currentBook.id,
            title: currentBook.title,
            author: currentBook.author,
            path: currentBook.path,
            format: currentBook.format,
            coverPath: currentBook.coverPath,
            dateAdded: currentBook.dateAdded,
            lastReadPage: currentBook.lastReadPage,
            synopsis: metadata['synopsis'],
            genreTags: List<String>.from(metadata['genreTags'] ?? []),
            publishDate: metadata['publishDate'],
          );
          isLoadingMetadata = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingMetadata = false;
        });
      }
    }
  }

  Future<void> _fetchRecommendations() async {
    try {
      final recs = await sl<BookStoreService>().getSimilarBooks(
        currentBook.title,
        currentBook.author,
      );
      if (mounted) {
        setState(() {
          recommendations = recs;
        });
      }
    } catch (e) {
      print("Error fetching recommendations: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = currentBook;
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
                  if (isLoadingMetadata)
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.kPrimaryColor,
                      ),
                    )
                  else
                    BookInfoSection(book: book),
                  const SizedBox(height: 40),
                  RecommendationSection(recommendations: recommendations),
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
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (book.coverPath != null)
                Image.file(File(book.coverPath!), fit: BoxFit.cover)
              else
                CachedNetworkImage(
                  imageUrl:
                      'https://images.unsplash.com/photo-1544947950-fa07a98d237f?auto=format&fit=crop&q=80&w=400',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: AppTheme.kSurfaceContainerLowColor,
                    highlightColor: AppTheme.kSurfaceContainerHighColor,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => _buildHeroPlaceholder(),
                ),
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
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
            ],
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

  Widget _buildHeroPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_rounded,
            color: AppTheme.kPrimaryColor.withValues(alpha: 0.3),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'NO COVER AVAILABLE',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
