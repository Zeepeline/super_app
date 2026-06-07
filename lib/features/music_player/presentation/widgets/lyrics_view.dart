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
  Worker? _activeIndexWorker;

  // Use a map to store keys for each lyric line
  final Map<int, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    // Use worker to scroll only when activeIndex changes
    _activeIndexWorker = ever(controller.activeIndex, (int index) {
      if (index != -1 && mounted) {
        // Delay slightly to ensure layout is ready if needed,
        // though postFrameCallback inside _scrollToCurrent handles it usually
        _scrollToCurrent(index);
      }
    });
  }

  @override
  void dispose() {
    _activeIndexWorker?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.syncedLyrics != oldWidget.syncedLyrics) {
      controller.updateLyrics(widget.syncedLyrics);
    }
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

    return Obx(() {
      if (controller.lyrics.isNotEmpty) {
        final activeIndex = controller.activeIndex.value;

        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.only(top: topPadding, bottom: screenHeight * 0.7),
          itemCount: controller.lyrics.length,
          itemBuilder: (context, index) {
            final lyric = controller.lyrics[index];
            final isActive = index == activeIndex;

            // Create or reuse key for this index
            _itemKeys[index] ??= GlobalKey();

            return AnimatedContainer(
              key: _itemKeys[index],
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
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
