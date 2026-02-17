import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  final String text;
  final String? subtitle;
  final Widget? trailing;
  final String? profilePhotoUrl;
  final void Function()? onTap;

  const UserTile({
    super.key,
    required this.text,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.profilePhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          highlightColor: AppTheme.orangeRed.withValues(alpha: 0.1),
          splashColor: AppTheme.tomato.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile picture with ring
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: AppTheme.volcanoColors,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: (profilePhotoUrl != null &&
                            profilePhotoUrl!.isNotEmpty)
                        ? NetworkImage(profilePhotoUrl!)
                        : null,
                    backgroundColor: Colors.grey[300],
                    child: (profilePhotoUrl == null || profilePhotoUrl!.isEmpty)
                        ? const Icon(Icons.person, color: Colors.white, size: 30)
                        : null,
                  ),
                ),

                const SizedBox(width: 20),

                // User name and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle ?? "Tap to start chatting",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Trailing widget or default arrow
                if (trailing != null)
                  trailing!
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
