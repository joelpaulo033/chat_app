import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  final String text;
  final String? profilePhotoUrl;
  final void Function()? onTap;

  const UserTile(
      {super.key, required this.text, this.onTap, this.profilePhotoUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 25),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // profile picture
            CircleAvatar(
              radius: 20,
              backgroundImage: (profilePhotoUrl != null &&
                      profilePhotoUrl!.isNotEmpty)
                  ? NetworkImage(profilePhotoUrl!)
                  : null,
              child: (profilePhotoUrl == null || profilePhotoUrl!.isEmpty)
                  ? const Icon(Icons.person)
                  : null,
            ),

            const SizedBox(width: 20),

            // user name
            Text(text),
          ],
        ),
      ),
    );
  }
}
