import 'package:flutter/material.dart';
import 'package:super_app/core/services/infrastructure/python_worker_service.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/injection_container.dart';

import '../../domain/entities/book_search_result.dart';

class BookSearchResultItem extends StatelessWidget {
  final BookSearchResult result;

  const BookSearchResultItem({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.kSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 110,
            decoration: BoxDecoration(
              color: AppTheme.kSurfaceContainerHighestColor,
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(
                  result.coverUrl ??
                      'https://images.unsplash.com/photo-1543002588-bfa74002ed7e?auto=format&fit=crop&q=80&w=100',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  result.author,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 8),
                _buildSourceBadge(result.source),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildMetaInfo(
                      Icons.insert_drive_file_outlined,
                      result.format,
                    ),
                    if (result.size != null) ...[
                      const SizedBox(width: 12),
                      _buildMetaInfo(Icons.data_usage_outlined, result.size!),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.download_rounded,
              color: AppTheme.kPrimaryColor,
            ),
            onPressed: () async {
              try {
                final workerService = sl<PythonWorkerService>();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Downloading "${result.title}"...')),
                );
                
                await workerService.downloadBook(result);
                
                final error = workerService.getTaskError(result.id);
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
                  );
                  workerService.clearTaskError(result.id);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Download complete! Saved to Documents/SoundWave/Books')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to start download: $e'), backgroundColor: Colors.red),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSourceBadge(String source) {
    Color badgeColor;
    switch (source) {
      case 'Libgen':
        badgeColor = Colors.blueAccent;
        break;
      case 'Internet Archive':
        badgeColor = Colors.orangeAccent;
        break;
      case 'Project Gutenberg':
        badgeColor = Colors.greenAccent;
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        source.toUpperCase(),
        style: TextStyle(
          color: badgeColor,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetaInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 12),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}
