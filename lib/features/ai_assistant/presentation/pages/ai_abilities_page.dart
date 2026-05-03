import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';

class AiAbilitiesPage extends StatelessWidget {
  const AiAbilitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundColor,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.kPrimaryColor.withValues(alpha: 0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(context),
                _buildHeader(context),
                Expanded(child: _buildAbilitiesGrid(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.kPrimaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.kPrimaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              'INTELIGENCE',
              style: GoogleFonts.inter(
                color: AppTheme.kPrimaryColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'SoundWave AI\nCapabilities',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Discover how your AI assistant can help you manage and enjoy your music collection.',
            style: GoogleFonts.inter(
              color: Colors.white60,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbilitiesGrid(BuildContext context) {
    final abilities = [
      _Ability(
        icon: Icons.play_circle_filled_rounded,
        title: 'Smart Playback',
        description: 'Play any track or artist just by asking.',
        color: const Color(0xFF6366F1),
      ),
      _Ability(
        icon: Icons.search_rounded,
        title: 'Library Explorer',
        description: 'Find tracks in your local collection instantly.',
        color: const Color(0xFF10B981),
      ),
      _Ability(
        icon: Icons.lyrics_rounded,
        title: 'Lyrics Finder',
        description: 'Get plain or synced lyrics for your favorite songs.',
        color: const Color(0xFFF59E0B),
      ),
      _Ability(
        icon: Icons.cloud_download_rounded,
        title: 'Music Miner',
        description: 'Download new music from YouTube to your library.',
        color: const Color(0xFFEC4899),
      ),
      _Ability(
        icon: Icons.psychology_rounded,
        title: 'Neural Memory',
        description: 'Remembers your tastes for personalized sessions.',
        color: const Color(0xFF8B5CF6),
      ),
      _Ability(
        icon: Icons.tune_rounded,
        title: 'Device Maestro',
        description: 'Control volume and check system hardware status.',
        color: const Color(0xFF06B6D4),
      ),
      _Ability(
        icon: Icons.info_outline_rounded,
        title: 'System Awareness',
        description: 'Monitor battery, connectivity, and device info.',
        color: const Color(0xFF3B82F6),
      ),
      _Ability(
        icon: Icons.auto_awesome_rounded,
        title: 'Expert Mode',
        description: 'Deep music analysis and intelligent hybrid RAG.',
        color: AppTheme.kPrimaryColor,
      ),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: abilities.length,
      itemBuilder: (context, index) {
        return _AbilityCard(ability: abilities[index]);
      },
    );
  }
}

class _Ability {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _Ability({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

class _AbilityCard extends StatelessWidget {
  final _Ability ability;

  const _AbilityCard({required this.ability});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Accent
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ability.color.withValues(alpha: 0.1),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ability.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(ability.icon, color: ability.color, size: 28),
                  ),
                  const Spacer(),
                  Text(
                    ability.title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ability.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.4,
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
}
