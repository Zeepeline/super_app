import 'package:flutter/material.dart';
import 'package:super_app/features/settings/domain/entities/user_entity.dart';

class UserProfileCard extends StatelessWidget {
  final UserEntity? user;

  const UserProfileCard({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF262626).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          // Avatar with glow effect
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF72fe8f).withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundImage: user?.avatarUrl != null
                      ? NetworkImage(user!.avatarUrl!)
                      : null,
                  backgroundColor: const Color(0xFF262626),
                  child: user?.avatarUrl == null
                      ? const Icon(Icons.person, color: Color(0xFF72fe8f))
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'Guest User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'Sign in to continue',
                  style: const TextStyle(
                    color: Color(0xFFadaaaa),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Edit button
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF262626),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.edit, color: Color(0xFF72fe8f), size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
