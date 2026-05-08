import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/session_entity.dart';

class SessionTimelineCard extends StatelessWidget {
  final SessionEntity session;
  final VoidCallback? onTap;

  const SessionTimelineCard({super.key, required this.session, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                session.time,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: session.isLive ? AppTheme.kPrimaryColor : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 1,
                    color: AppTheme.kSurfaceContainerHighestColor,
                    margin: const EdgeInsets.only(left: 4),
                  ),
                ),
                if (session.isLive)
                  Positioned(
                    left: 0,
                    top: 24,
                    child: Container(
                      width: 9,
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.kPrimaryColor,
                            AppTheme.kPrimaryColor.withOpacity(0),
                          ],
                        ),
                      ),
                      margin: const EdgeInsets.only(left: 0),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(left: 24, bottom: 24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.kSurfaceContainerLowColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.02)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: session.isLive
                                    ? const Color(0xFF1A1A1A)
                                    : AppTheme.kPrimaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: session.isLive
                                      ? Colors.white.withOpacity(0.1)
                                      : AppTheme.kPrimaryColor.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                session.tag,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: session.isLive
                                          ? Colors.white
                                          : AppTheme.kPrimaryColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            const Icon(
                              Icons.more_vert,
                              color: AppTheme.kOnSurfaceVariantColor,
                              size: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          session.title,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          session.description,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.kOnSurfaceVariantColor,
                              ),
                        ),
                        if (session.participants.isNotEmpty ||
                            session.id == '3') ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              if (session.id == '3')
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppTheme.kPrimaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.headphones,
                                    color: Colors.black,
                                    size: 18,
                                  ),
                                )
                              else
                                const CircleAvatar(
                                  radius: 14,
                                  backgroundImage: NetworkImage(
                                    'https://api.dicebear.com/7.x/avataaars/png?seed=Sarah',
                                  ),
                                ),
                              const SizedBox(width: 12),
                              Text(
                                session.id == '3'
                                    ? 'Analysis of "Echoes of Silence"'
                                    : '+ Sarah Jenkins',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
