import 'package:flutter/material.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/features/book_search/presentation/pages/book_search_page.dart';

class ExternalSourcesList extends StatelessWidget {
  const ExternalSourcesList({super.key});

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
                'External Sources',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BookSearchPage(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'EXPLORE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.kPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      color: AppTheme.kPrimaryColor,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: const [
              ExternalSourceCard(
                title: 'Library Genesis',
                desc: 'Search millions of scholarly articles and books.',
                icon: Icons.public,
              ),
              SizedBox(width: 16),
              ExternalSourceCard(
                title: 'Project Gutenberg',
                desc: '60,000+ free eBooks focusing on older works.',
                icon: Icons.auto_stories,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ExternalSourceCard extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;

  const ExternalSourceCard({
    super.key,
    required this.title,
    required this.desc,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BookSearchPage()),
        );
      },
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.kSurfaceContainerLowColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.kSurfaceContainerHighestColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.kPrimaryColor, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
