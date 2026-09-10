import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'user_avatar.dart';

class UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onAudioCall;
  final VoidCallback onVideoCall;
  final VoidCallback? onTap;

  const UserTile({
    super.key,
    required this.user,
    required this.onAudioCall,
    required this.onVideoCall,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            UserAvatar(
              initials: user.initials,
              colorHex: user.avatarColorHex,
              radius: 24,
              showOnlineDot: true,
              isOnline: user.isOnline,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    user.isOnline ? 'Online' : 'Offline',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: user.isOnline ? const Color(0xFF2ECC71) : null,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onAudioCall,
              icon: const Icon(Icons.call_outlined),
              style: IconButton.styleFrom(backgroundColor: theme.colorScheme.primary.withOpacity(0.1)),
              color: theme.colorScheme.primary,
              tooltip: 'Audio call',
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onVideoCall,
              icon: const Icon(Icons.videocam_outlined),
              style: IconButton.styleFrom(backgroundColor: theme.colorScheme.primary.withOpacity(0.1)),
              color: theme.colorScheme.primary,
              tooltip: 'Video call',
            ),
          ],
        ),
      ),
    );
  }
}
