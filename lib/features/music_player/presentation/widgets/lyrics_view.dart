import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:super_app/features/music_player/presentation/controllers/player_ui_controller.dart';

class LyricsView extends StatefulWidget {
  final String? syncedLyrics;
  final String? plainLyrics;

  const LyricsView({super.key, this.syncedLyrics, this.plainLyrics});

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  final PlayerUIController controller = Get.find<PlayerUIController>();
  final ScrollController _scrollController = ScrollController();

  // Use a map to store keys for each lyric line
  final Map<int, GlobalKey> _itemKeys = {};

  // Cache last active index to avoid redundant scrolls
  int _lastActiveIndex = -1;

  @override
  void didUpdateWidget(LyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.syncedLyrics != oldWidget.syncedLyrics) {
      _lastActiveIndex = -1;
      _itemKeys.clear();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrent(int index) {
    final key = _itemKeys[index];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        alignment: 0.15, // Keep active lyric at 15% from the top
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = screenHeight * 0.15;

    // Update lyrics in controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.updateLyrics(widget.syncedLyrics);
    });

    return Obx(() {
      if (controller.lyrics.isNotEmpty) {
        return StreamBuilder<Duration>(
          stream: controller.positionStream,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;

            // Optimized: Find active index using binary search
            int activeIndex = controller.lyricsService.findActiveIndex(
              controller.lyrics,
              position,
            );

            // Optimized: Only trigger scroll if active index has changed
            if (activeIndex != -1 && activeIndex != _lastActiveIndex) {
              _lastActiveIndex = activeIndex;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToCurrent(activeIndex);
              });
            }

            return ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.only(
                top: topPadding,
                bottom: screenHeight * 0.7,
              ),
              itemCount: controller.lyrics.length,
              itemBuilder: (context, index) {
                final lyric = controller.lyrics[index];
                final isActive = index == activeIndex;

                // Create or reuse key for this index
                _itemKeys[index] ??= GlobalKey();

                return AnimatedContainer(
                  key: _itemKeys[index],
                  duration: const Duration(milliseconds: 400),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 32,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    lyric.text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isActive ? 26 : 20,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      color: isActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.2),
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            );
          },
        );
      }

      if (widget.plainLyrics != null && widget.plainLyrics!.isNotEmpty) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Text(
            widget.plainLyrics!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.7),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        );
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lyrics_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'Lyrics not available',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
      );
    });
  }
}
