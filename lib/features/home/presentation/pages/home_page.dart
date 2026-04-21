import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:super_app/core/network/network_info.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/core/theme/widgets/offline_badge.dart';
import 'package:super_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:super_app/features/home/presentation/bloc/home_event.dart';
import 'package:super_app/features/home/presentation/bloc/home_state.dart';
import 'package:super_app/features/home/presentation/widgets/featured_playlist_card.dart';
import 'package:super_app/features/home/presentation/widgets/popular_track_card.dart';
import 'package:super_app/features/settings/presentation/pages/settings_page.dart';
import 'package:super_app/injection_container.dart';

import '../widgets/empty_library_view.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              color: AppTheme.kBackgroundColor,
              child: BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  if (state is HomeLoading || state is HomeInitial) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.kPrimaryColor,
                      ),
                    );
                  } else if (state is HomeLoaded) {
                    if (state.popularTracks.isEmpty &&
                        state.featuredPlaylists.isEmpty) {
                      return EmptyLibraryView(
                        onImportPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsPage(),
                            ),
                          );
                        },
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<HomeBloc>().add(LoadHomeDataEvent());
                      },
                      color: AppTheme.kPrimaryColor,
                      backgroundColor: Colors.black,
                      child: CustomScrollView(
                        slivers: [
                          _buildHeader(context),
                          _buildAsymmetricalHero(context, state),
                          _buildFeaturedPlaylists(context, state),
                          _buildPopularTracksHeader(context),
                          _buildPopularTracksList(context, state),
                          const SliverPadding(
                            padding: EdgeInsets.only(bottom: 100),
                          ),
                        ],
                      ),
                    );
                  } else if (state is HomeError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.kPrimaryColor,
                    ),
                  );
                },
              ),
            ),
            // Connection Status Indicator
            Positioned(
              bottom: 120,
              left: 24,
              child: StreamBuilder<List<ConnectivityResult>>(
                stream: sl<NetworkInfo>().onConnectivityChanged,
                builder: (context, snapshot) {
                  final results = snapshot.data ?? [];
                  final isOffline =
                      results.isEmpty ||
                      results.contains(ConnectivityResult.none);
                  if (isOffline) {
                    return const OfflineBadge();
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GOOD EVENING,',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  'DIGITAL CURATOR',
                  style: Theme.of(
                    context,
                  ).textTheme.displayLarge?.copyWith(fontSize: 28),
                ),
              ],
            ),
            const CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=100',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAsymmetricalHero(BuildContext context, HomeLoaded state) {
    return SliverToBoxAdapter(
      child: Container(
        height: 220,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [AppTheme.kPrimaryColor, AppTheme.kPrimaryContainerColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              right: -30,
              bottom: -30,
              child: Opacity(
                opacity: 0.15,
                child: Icon(Icons.music_note, size: 240, color: Colors.black),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'FEATURED MIX',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.kPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'NEON PULSE\nCOLLECTIVE',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.black,
                      fontSize: 36,
                      height: 0.9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedPlaylists(BuildContext context, HomeLoaded state) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 48, bottom: 24),
            child: Text(
              'YOUR ATMOSPHERE',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          SizedBox(
            height: 260,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemCount: state.featuredPlaylists.length,
              itemBuilder: (context, index) {
                return FeaturedPlaylistCard(
                  playlist: state.featuredPlaylists[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularTracksHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 24, top: 48, bottom: 24),
        child: Text(
          'ON THE RISE',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }

  Widget _buildPopularTracksList(BuildContext context, HomeLoaded state) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: PopularTrackCard(track: state.popularTracks[index]),
        );
      }, childCount: state.popularTracks.length),
    );
  }
}
