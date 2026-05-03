import 'package:flutter/material.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/features/music_player/domain/entities/track_entity.dart';
import 'package:super_app/features/music_player/presentation/cubit/player_cubit.dart';
import 'package:super_app/features/music_player/presentation/pages/music_player_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LibraryDetailPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final List<TrackEntity> tracks;
  final bool isArtist;

  const LibraryDetailPage({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.tracks,
    this.isArtist = false,
  });

  void _playTrack(BuildContext context, TrackEntity track) {
    context.read<PlayerCubit>().selectAndPlay(track);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MusicPlayerPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If it's an artist, group their tracks by album
    Map<String, List<TrackEntity>> albums = {};
    if (isArtist) {
      for (var t in tracks) {
        if (!albums.containsKey(t.album)) {
          albums[t.album] = [];
        }
        albums[t.album]!.add(t);
      }
    }

    final albumList = albums.keys.toList();

    return Scaffold(
      backgroundColor: AppTheme.kBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppTheme.kBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null)
                    Image.network(imageUrl!, fit: BoxFit.cover)
                  else
                    Container(
                      color: AppTheme.kSurfaceContainerColor,
                      child: Icon(
                        isArtist ? Icons.person : Icons.album,
                        size: 80,
                        color: AppTheme.kPrimaryColor,
                      ),
                    ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.kBackgroundColor.withValues(alpha: 0.8),
                          AppTheme.kBackgroundColor,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.kOnSurfaceVariantColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isArtist
                        ? '${albums.length} albums • ${tracks.length} tracks'
                        : '${tracks.length} tracks',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 16),
                  if (!isArtist)
                    ElevatedButton.icon(
                      onPressed: () => _playTrack(context, tracks[0]),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.kPrimaryColor,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 32),
                      label: const Text(
                        'SHUFFLE PLAY',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isArtist)
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final albumName = albumList[index];
                final albumTracks = albums[albumName]!;
                final artUrl = albumTracks[0].albumArtUrl;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      artUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: AppTheme.kSurfaceContainerColor,
                        child: const Icon(
                          Icons.album,
                          color: AppTheme.kPrimaryColor,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    albumName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${albumTracks.length} tracks',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => LibraryDetailPage(
                          title: albumName,
                          subtitle: 'Album • $title',
                          imageUrl: artUrl,
                          tracks: albumTracks,
                          isArtist: false,
                        ),
                      ),
                    );
                  },
                );
              }, childCount: albumList.length),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final track = tracks[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      track.albumArtUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 48,
                        height: 48,
                        color: AppTheme.kSurfaceContainerColor,
                        child: const Icon(
                          Icons.music_note,
                          color: AppTheme.kPrimaryColor,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    track.artist,
                    style: TextStyle(
                      color: AppTheme.kOnSurfaceVariantColor,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(Icons.more_vert, size: 20),
                  onTap: () => _playTrack(context, track),
                );
              }, childCount: tracks.length),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }
}
