import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final bool isForwarded;
  final VoidCallback? onLongPress;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.isForwarded = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (isForwarded)
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.forward, size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    "Forwarded",
                    style: TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: isCurrentUser
                  ? const LinearGradient(
                      colors: [Color(0xFFFF4500), Color(0xFFFF8C00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: !isCurrentUser
                  ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
                  : null,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isCurrentUser ? 18 : 4),
                bottomRight: Radius.circular(isCurrentUser ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: isCurrentUser
                      ? const Color(0xFFFF4500).withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
            margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
            child: Text(
              message,
              style: TextStyle(
                color: isCurrentUser
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
                fontSize: 16,
                fontWeight: isCurrentUser ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
