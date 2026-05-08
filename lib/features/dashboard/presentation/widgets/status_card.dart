import 'package:flutter/material.dart';

class DashboardStatusCard extends StatelessWidget {
  final String title;
  final String value;
  final double? progress;
  final String type;

  const DashboardStatusCard({
    super.key,
    required this.title,
    required this.value,
    this.progress,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (type == 'next_up') ...[
            const SizedBox(height: 4),
            const Text(
              '09:00 AM',
              style: TextStyle(color: Color(0xFF72FE8F), fontSize: 12),
            ),
          ] else if (type == 'meeting') ...[
            const SizedBox(height: 4),
            const Text(
              'in 45m',
              style: TextStyle(color: Colors.cyanAccent, fontSize: 12),
            ),
          ] else if (type == 'readiness' && progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF72FE8F),
                ),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
