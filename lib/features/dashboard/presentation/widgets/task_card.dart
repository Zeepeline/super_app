import 'package:flutter/material.dart';

class DashboardTaskCard extends StatelessWidget {
  final String title;
  final String priority;
  final String estimatedTime;
  final bool isCompleted;
  final VoidCallback? onTap;

  const DashboardTaskCard({
    super.key,
    required this.title,
    required this.priority,
    required this.estimatedTime,
    required this.isCompleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color priorityColor;
    switch (priority.toLowerCase()) {
      case 'high':
        priorityColor = const Color(0xFFFF5722);
        break;
      case 'medium':
        priorityColor = const Color(0xFF72FE8F);
        break;
      default:
        priorityColor = const Color(0xFFADAAAA);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A).withOpacity(isCompleted ? 0.5 : 1.0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        priority.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: priorityColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '•',
                        style: TextStyle(color: Color(0xFFADAAAA)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        estimatedTime,
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            if (isCompleted)
              const Icon(Icons.check_circle, color: Color(0xFF72FE8F))
            else
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white70,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF72FE8F),
                        width: 2,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
