import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  final String text;
  final String? profilePhotoUrl;
  final bool isOnline;
  final void Function()? onTap;

  const UserTile({
    super.key,
    required this.text,
    this.onTap,
    this.profilePhotoUrl,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color:
              Colors.transparent, // Let the background show or use a soft color
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Row(
          children: [
            // profile picture
            Stack(
              children: [
                CircleAvatar(
                  key: ValueKey(profilePhotoUrl),
                  radius: 28,
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  backgroundImage:
                      (profilePhotoUrl != null && profilePhotoUrl!.isNotEmpty)
                          ? NetworkImage(profilePhotoUrl!)
                          : null,
                  child: (profilePhotoUrl == null || profilePhotoUrl!.isEmpty)
                      ? Text(
                          text.isNotEmpty ? text[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 2.5),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 16),

            // user name
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
