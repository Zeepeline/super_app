import 'package:flutter/material.dart';

class TrendCard extends StatelessWidget {
  final String growth;
  final List<double> dataPoints;

  const TrendCard({
    super.key,
    required this.growth,
    required this.dataPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TREND',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.trending_up, color: Color(0xFF72FE8F), size: 16),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            growth,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: 24,
            ),
          ),
          Text(
            'Growth',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dataPoints.map((p) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 40 * p,
                    decoration: BoxDecoration(
                      color: p > 0.5 ? const Color(0xFF72FE8F) : Colors.white12,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: p > 0.5 ? [
                        BoxShadow(
                          color: const Color(0xFF72FE8F).withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ] : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class InsightCard extends StatelessWidget {
  final String message;

  const InsightCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'INSIGHTS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.lightbulb_outline, color: Colors.cyanAccent, size: 16),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  height: 1.5,
                ),
                children: _buildMessageSpans(context, message),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildMessageSpans(BuildContext context, String message) {
    // Basic highlighting for numbers
    final words = message.split(' ');
    return words.map((word) {
      final isHighlight = int.tryParse(word) != null || word.contains('earlier');
      return TextSpan(
        text: '$word ',
        style: TextStyle(
          color: isHighlight ? Colors.cyanAccent : Colors.white,
          fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
        ),
      );
    }).toList();
  }
}
