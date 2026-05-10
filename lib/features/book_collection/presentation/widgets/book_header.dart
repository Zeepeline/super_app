import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/features/book_search/presentation/pages/book_search_page.dart';

class BookHeader extends StatelessWidget {
  const BookHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OBSIDIAN RHYTHM',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.kPrimaryColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'MY LIBRARY',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BookSearchPage(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppTheme.kSurfaceContainerLowColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=100',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
