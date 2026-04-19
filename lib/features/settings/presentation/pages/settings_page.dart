import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:super_app/core/theme/app_theme.dart';

import '../../../../injection_container.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../widgets/audio_quality_selector.dart';
import '../widgets/import_library_button.dart';
import '../widgets/logout_button.dart';
import '../widgets/settings_toggle_widget.dart';
import '../widgets/user_profile_card.dart';
import '../widgets/youtube_download_card.dart';
import 'youtube_webview_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<SettingsBloc>()..add(const LoadSettingsEvent()),
      child: BlocListener<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsImportSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Successfully imported ${state.count} tracks!',
                  style: const TextStyle(color: Colors.black),
                ),
                backgroundColor: AppTheme.kPrimaryColor,
              ),
            );
          } else if (state is SettingsDownloadSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Downloaded: ${state.title}',
                  style: const TextStyle(color: Colors.black),
                ),
                backgroundColor: AppTheme.kPrimaryColor,
              ),
            );
          } else if (state is SettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        child: const SettingsView(),
      ),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0e0e0e),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF72fe8f)),
            );
          }

          if (state is SettingsError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (state is SettingsLoaded) {
            return _buildContent(context, state);
          }

          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF72fe8f)),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, SettingsLoaded state) {
    return CustomScrollView(
      slivers: [
        // Top App Bar
        SliverToBoxAdapter(child: _buildAppBar(context)),

        // User Profile Section
        SliverToBoxAdapter(child: UserProfileCard(user: state.user)),

        // Download Settings Section
        SliverToBoxAdapter(child: _buildSectionTitle('Download Settings')),
        SliverToBoxAdapter(
          child: AudioQualitySelector(
            currentQuality: state.settings.audioQuality,
            onQualityChanged: (quality) {
              context.read<SettingsBloc>().add(
                UpdateAudioQualityEvent(quality),
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: SettingsToggleWidget(
            title: 'Download over cellular',
            subtitle: 'May increase data usage',
            value: state.settings.downloadOverCellular,
            onChanged: (value) {
              context.read<SettingsBloc>().add(
                UpdateDownloadOverCellularEvent(value),
              );
            },
          ),
        ),

        // YouTube Download Section
        SliverToBoxAdapter(
          child: YoutubeDownloadCard(
            isDownloading: state is SettingsDownloadingYoutube,
            stage: state is SettingsDownloadingYoutube ? (state).stage : null,
            progress: state is SettingsDownloadingYoutube
                ? (state).progress
                : null,
            onDownload: (url) {
              context.read<SettingsBloc>().add(DownloadYoutubeTrackEvent(url));
            },
          ),
        ),
        SliverToBoxAdapter(
          child: ImportLibraryButton(
            icon: Icons.public,
            title: 'Survivor Web Downloader',
            subtitle: 'Manual download via y2mate (Clean UI)',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const YouTubeWebViewPage(),
                ),
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: ImportLibraryButton(
            icon: Icons.sync,
            title: 'Sync Local Downloads',
            subtitle: 'Add WebView downloads to library',
            isLoading: state is SettingsImporting,
            onTap: () {
              context.read<SettingsBloc>().add(
                const SyncDownloadedMusicEvent(),
              );
            },
          ),
        ),

        // Import Library Section
        SliverToBoxAdapter(child: _buildSectionTitle('Import Library')),

        SliverToBoxAdapter(
          child: ImportLibraryButton(
            icon: Icons.cloud_download,
            title: 'Cloud import',
            subtitle: 'Sync from Drive or Dropbox',
            onTap: () {
              context.read<SettingsBloc>().add(const CloudImportEvent());
            },
          ),
        ),

        // Notifications Section
        SliverToBoxAdapter(child: _buildSectionTitle('Notifications')),
        SliverToBoxAdapter(
          child: SettingsToggleWidget(
            title: 'Push notifications',
            subtitle: 'New releases & alerts',
            value: state.settings.pushNotifications,
            onChanged: (value) {
              context.read<SettingsBloc>().add(
                UpdatePushNotificationsEvent(value),
              );
            },
          ),
        ),

        // Logout & Footer
        SliverToBoxAdapter(
          child: LogoutButton(
            onTap: () {
              context.read<SettingsBloc>().add(const LogoutEvent());
            },
          ),
        ),

        // Bottom padding for navigation bar
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        left: 24,
        right: 24,
        bottom: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'SETTINGS',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: 32,
              letterSpacing: -1.5,
            ),
          ),
          Text(
            'OBSIDIAN RHYTHM',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.kPrimaryColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFFadaaaa),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
