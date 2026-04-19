import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../../home/domain/entities/track_entity.dart';
import '../../../music_player/presentation/pages/music_player_page.dart';
import '../bloc/library_bloc.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  void _showFullPlayer(BuildContext context, TrackEntity track) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MusicPlayerPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
              position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<LibraryBloc>()..add(LoadFavorites()),
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LIBRARY',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const Row(
                      children: [
                        Icon(Icons.search, size: 28),
                        SizedBox(width: 16),
                        Icon(Icons.add, size: 28),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildFilterChips(context),
                const SizedBox(height: 32),
                Expanded(
                  child: BlocBuilder<LibraryBloc, LibraryState>(
                    builder: (context, state) {
                      if (state is LibraryLoading) {
                        return const Center(child: CircularProgressIndicator(color: AppTheme.kPrimaryColor));
                      } else if (state is LibraryLoaded) {
                        final tracks = state.favoriteTracks;
                        if (tracks.isEmpty) {
                          return _buildEmptyState(context);
                        }
                        return ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: tracks.length,
                          itemBuilder: (context, index) {
                            final track = tracks[index];
                            return _buildLibraryItem(
                              context,
                              track,
                            );
                          },
                        );
                      } else if (state is LibraryError) {
                        return Center(child: Text(state.message));
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border, size: 64, color: AppTheme.kOnSurfaceVariantColor),
          const SizedBox(height: 16),
          Text(
            'No Liked Songs Yet',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.kOnSurfaceVariantColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep your favorite tracks here!',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(context, 'PLAYLISTS', isSelected: true),
          _filterChip(context, 'ARTISTS'),
          _filterChip(context, 'ALBUMS'),
          _filterChip(context, 'PODCASTS'),
        ],
      ),
    );
  }

  Widget _filterChip(BuildContext context, String label, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.kPrimaryColor : AppTheme.kSurfaceContainerHighestColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isSelected ? Colors.black : AppTheme.kOnSurfaceVariantColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
      ),
    );
  }

  Widget _buildLibraryItem(BuildContext context, TrackEntity track) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: GestureDetector(
        onTap: () => _showFullPlayer(context, track),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                track.albumArtUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 64,
                  height: 64,
                  color: AppTheme.kSurfaceContainerHighestColor,
                  child: const Icon(Icons.music_note, color: AppTheme.kPrimaryColor),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.push_pin, size: 14, color: AppTheme.kPrimaryColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "${track.artist} • ${track.duration}".toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
