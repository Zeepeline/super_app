import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_app/features/youtube/presentation/controllers/youtube_controller.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../../../core/theme/app_theme.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Reuse the YouTubeController for search functionality
    final controller = Get.put(YouTubeController());

    return Scaffold(
      backgroundColor: AppTheme.kBackgroundColor,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 80),
                _SearchBar(controller: controller),
                Expanded(child: _SearchResults(controller: controller)),
              ],
            ),
          ),

          // Floating blurred header
          Positioned(top: 0, left: 0, right: 0, child: _Header()),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 80 + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: AppTheme.kBackgroundColor.withValues(alpha: 0.75),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: AppTheme.kPrimaryColor,
                size: 28,
              ),
              SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXPLORE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.kPrimaryColor,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'Search Music',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final YouTubeController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: controller.searchTextController,
                style: const TextStyle(color: Colors.white),
                cursorColor: AppTheme.kPrimaryColor,
                textInputAction: TextInputAction.search,
                onChanged: (value) => controller.searchQuery.value = value,
                onSubmitted: controller.search,
                decoration: InputDecoration(
                  hintText: 'Cari lagu, artis, atau album...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  suffixIcon: Obx(
                    () => controller.searchQuery.value.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: Colors.white.withValues(alpha: 0.4),
                              size: 18,
                            ),
                            onPressed: () {
                              controller.searchTextController.clear();
                              controller.searchQuery.value = '';
                              controller.searchResults.clear();
                              controller.searchError.value = '';
                            },
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Obx(
            () => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: AppTheme.kPrimaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: controller.isSearching.value
                  ? const SizedBox(
                      width: 50,
                      height: 50,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: () => controller.search(
                        controller.searchTextController.text,
                      ),
                      icon: const Icon(
                        Icons.search_rounded,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search Results ──────────────────────────────────────────────────────────

class _SearchResults extends StatelessWidget {
  final YouTubeController controller;
  const _SearchResults({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.searchError.value.isNotEmpty) {
        return _EmptyState(
          icon: Icons.wifi_off_rounded,
          title: 'Oops!',
          subtitle: controller.searchError.value,
        );
      }

      if (controller.searchResults.isEmpty && !controller.isSearching.value) {
        return const _EmptyState(
          icon: Icons.music_note_rounded,
          title: 'Temukan Musikmu',
          subtitle:
              'Ketik judul lagu, nama artis, atau album di kolom pencarian',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 100),
        itemCount: controller.searchResults.length,
        itemBuilder: (context, index) {
          final video = controller.searchResults[index];
          return _VideoCard(video: video, controller: controller);
        },
      );
    });
  }
}

// ─── Video Card ───────────────────────────────────────────────────────────────

class _VideoCard extends StatelessWidget {
  final Video video;
  final YouTubeController controller;

  const _VideoCard({required this.video, required this.controller});

  @override
  Widget build(BuildContext context) {
    final videoId = video.id.value;
    final duration = video.duration;
    final durationStr = duration != null
        ? '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}'
        : '--:--';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: Image.network(
                video.thumbnails.mediumResUrl,
                width: 100,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 100,
                  height: 80,
                  color: Colors.white.withValues(alpha: 0.08),
                  child: Icon(
                    Icons.music_video_rounded,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 28,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 11,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          durationStr,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Obx(() {
                final state = controller.downloadStates[videoId];
                final progress = controller.downloadProgress[videoId] ?? 0.0;
                return _DownloadButton(
                  state: state,
                  progress: progress,
                  onTap: () => controller.downloadVideo(video),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Download Button & Empty State (Shared with YouTubePage) ──────────────────

class _DownloadButton extends StatelessWidget {
  final DownloadState? state;
  final double progress;
  final VoidCallback onTap;

  const _DownloadButton({
    required this.state,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (state?.isDownloading == true) {
      return Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: CircularProgressIndicator(
              value: progress > 0 ? progress : null,
              color: AppTheme.kPrimaryColor,
              backgroundColor: AppTheme.kPrimaryColor.withValues(alpha: 0.1),
              strokeWidth: 3,
            ),
          ),
          Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(
              color: AppTheme.kPrimaryColor,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    if (state?.isDone == true) {
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: Colors.green, size: 22),
      );
    }

    if (state?.isError == true) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.refresh_rounded,
            color: Colors.redAccent,
            size: 22,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.kPrimaryColor, Color(0xFF64FFDA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.kPrimaryColor.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.download_rounded,
          color: Colors.black,
          size: 22,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.kPrimaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.kPrimaryColor, size: 42),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.45),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
