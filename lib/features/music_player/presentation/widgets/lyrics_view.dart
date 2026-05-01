import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:super_app/features/music_player/presentation/controllers/player_ui_controller.dart';

class LyricsView extends StatelessWidget {
  final String? syncedLyrics;
  final String? plainLyrics;
  final PlayerUIController controller = Get.find<PlayerUIController>();
  final ScrollController _scrollController = ScrollController();

  LyricsView({super.key, this.syncedLyrics, this.plainLyrics});

  void _scrollToCurrent(int index) {
    if (_scrollController.hasClients && index >= 0) {
      _scrollController.animateTo(
        index * 60.0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update lyrics in controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.updateLyrics(syncedLyrics);
    });

    return Obx(() {
      if (controller.lyrics.isNotEmpty) {
        return StreamBuilder<Duration>(
          stream: controller.positionStream,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;

            // Find active index
            int activeIndex = -1;
            for (int i = 0; i < controller.lyrics.length; i++) {
              if (position >= controller.lyrics[i].startTime) {
                activeIndex = i;
              } else {
                break;
              }
            }

            // Trigger scroll
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToCurrent(activeIndex);
            });

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 200),
              itemCount: controller.lyrics.length,
              itemBuilder: (context, index) {
                final lyric = controller.lyrics[index];
                final isActive = index == activeIndex;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                  child: Text(
                    lyric.text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isActive ? 24 : 18,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            );
          },
        );
      }

      if (plainLyrics != null && plainLyrics!.isNotEmpty) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Text(
            plainLyrics!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
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
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'Lyrics not available',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    });
  }
}
