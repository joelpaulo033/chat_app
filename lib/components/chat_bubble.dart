import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final String? time;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? AppTheme.tomato
                  : Colors.white.withValues(alpha: 0.9),
              gradient: isCurrentUser
                  ? const LinearGradient(
                      colors: [AppTheme.orangeRed, AppTheme.tomato],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isCurrentUser ? 20 : 4),
                bottomRight: Radius.circular(isCurrentUser ? 4 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Text(
              message,
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black87,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
          if (time != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text(
                time!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
