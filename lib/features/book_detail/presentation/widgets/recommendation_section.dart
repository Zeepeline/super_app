import 'package:flutter/material.dart';
import 'package:super_app/core/theme/app_theme.dart';

class RecommendationSection extends StatelessWidget {
  const RecommendationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final recommendations = [
      {'title': 'SILICONPULSE', 'author': 'MARCUS VANE', 'image': 'https://images.unsplash.com/photo-1614850523296-d8c1af93d400?q=80&w=200'},
      {'title': 'DEEP GLASS', 'author': 'ELIAS THORNE', 'image': 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=200'},
    ];

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
          children: recommendations.map((book) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppTheme.kSurfaceContainerLowColor,
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(book['image']!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      book['title']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      book['author']!,
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
}
