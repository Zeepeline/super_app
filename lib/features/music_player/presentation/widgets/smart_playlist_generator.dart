import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:super_app/core/services/music/smart_playlist_service.dart';
import 'package:super_app/core/theme/app_theme.dart';
import 'package:super_app/features/music_player/presentation/cubit/player_cubit.dart';
import 'package:super_app/injection_container.dart';

class SmartPlaylistGenerator extends StatefulWidget {
  const SmartPlaylistGenerator({super.key});

  @override
  State<SmartPlaylistGenerator> createState() => _SmartPlaylistGeneratorState();
}

class _SmartPlaylistGeneratorState extends State<SmartPlaylistGenerator> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  bool _isYouTubeMode = false;
  SmartPlaylistResponse? _response;

  Future<void> _generate() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _response = null;
    });

    final service = sl<SmartPlaylistService>();
    final result = _isYouTubeMode
        ? await service.generateYouTubePlaylist(_controller.text)
        : await service.generatePlaylist(_controller.text);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _response = result;
      });
    }
  }

  void _playAll() {
    if (_response == null || _response!.tracks.isEmpty) return;

    final playerCubit = sl<PlayerCubit>();
    playerCubit.playPlaylist(_response!.tracks);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Memutar: ${_response!.playlistName} (${_isYouTubeMode ? 'YouTube' : 'Local'})',
        ),
        backgroundColor: AppTheme.kPrimaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.kSurfaceContainerLowColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: AppTheme.kPrimaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'AI SMART PLAYLIST',
                        style: GoogleFonts.inter(
                          color: AppTheme.kPrimaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Mode Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildModeButton(false, 'Local', Icons.storage_rounded),
                    _buildModeButton(true, 'YouTube', Icons.public_rounded),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _isYouTubeMode
                ? 'Jelajahi musik baru di YouTube'
                : 'Buat playlist dari library Anda',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: _isYouTubeMode
                          ? 'Ingin dengar apa hari ini?'
                          : 'Misal: Jogging sore santai...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                      ),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _generate(),
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.kPrimaryColor,
                    ),
                  )
                else
                  IconButton(
                    onPressed: _generate,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: AppTheme.kPrimaryColor,
                    ),
                  ),
              ],
            ),
          ),
          if (_response != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _response!.playlistName,
                    style: const TextStyle(
                      color: AppTheme.kPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _response!.reason,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._response!.tracks
                      .take(3)
                      .map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.music_note,
                                size: 14,
                                color: Colors.white38,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${t.title} - ${t.artist}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  if (_response!.tracks.length > 3)
                    Text(
                      '+ ${_response!.tracks.length - 3} lagu lainnya',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _playAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.kPrimaryColor,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text(
                      'PUTAR SEMUA',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeButton(bool isYoutube, String label, IconData icon) {
    final active = _isYouTubeMode == isYoutube;
    return GestureDetector(
      onTap: () => setState(() => _isYouTubeMode = isYoutube),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.kPrimaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: active ? Colors.black : Colors.white38),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.black : Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
