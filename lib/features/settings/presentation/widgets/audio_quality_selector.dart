import 'package:flutter/material.dart';

import '../../domain/entities/settings_entity.dart';

class AudioQualitySelector extends StatelessWidget {
  final AudioQuality currentQuality;
  final ValueChanged<AudioQuality> onQualityChanged;

  const AudioQualitySelector({
    super.key,
    required this.currentQuality,
    required this.onQualityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quality label
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              'Quality',
              style: TextStyle(
                color: Color(0xFFadaaaa),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Quality options
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF262626),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                _buildQualityButton(
                  label: 'Standard',
                  quality: AudioQuality.standard,
                ),
                const SizedBox(width: 8),
                _buildQualityButton(label: 'High', quality: AudioQuality.high),
                const SizedBox(width: 8),
                _buildQualityButton(
                  label: 'Lossless',
                  quality: AudioQuality.lossless,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityButton({
    required String label,
    required AudioQuality quality,
  }) {
    final isSelected = currentQuality == quality;
    return Expanded(
      child: GestureDetector(
        onTap: () => onQualityChanged(quality),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF262626) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: const Color(0xFF72fe8f).withValues(alpha: 0.2))
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF72fe8f).withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFFadaaaa),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
