import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/core/services/books/book_store_service.dart';

class BookRecommendationDetailPage extends StatelessWidget {
  final BookRecommendation recommendation;

  const BookRecommendationDetailPage({super.key, required this.recommendation});

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
                  _buildCoverImage(),
                  const SizedBox(height: 40),
                  _buildTitleSection(),
                  const SizedBox(height: 32),
                  _buildInfoCards(),
                  const SizedBox(height: 40),
                  _buildReasonSection(),
                  const SizedBox(height: 40),
                  _buildActionButtons(context),
                  const SizedBox(height: 60),
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
      backgroundColor: AppTheme.kBackgroundColor,
      elevation: 0,
      pinned: true,
      centerTitle: true,
      title: Text(
        'RECOMMENDATION',
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 2,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildCoverImage() {
    return Center(
      child: Hero(
        tag: 'popular_${recommendation.title}',
        child: Container(
          height: 320,
          width: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.kPrimaryColor.withOpacity(0.2),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.network(
              recommendation.coverUrl ?? 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?q=80&w=400',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          recommendation.title.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          recommendation.author.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.kPrimaryColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoItem(Icons.category_outlined, recommendation.genre),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoItem(Icons.star_outline, 'Trending'),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.kSurfaceContainerLowColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.kPrimaryColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHY WE RECOMMEND THIS',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          recommendation.reason,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 15,
            height: 1.6,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          // Future: Navigate to store search with this title
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.kPrimaryColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 20),
            const SizedBox(width: 12),
            Text(
              'FIND IN STORE',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
