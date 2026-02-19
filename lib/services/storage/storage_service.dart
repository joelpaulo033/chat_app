import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 5MB max (governance control)
  static const int maxFileSize = 5 * 1024 * 1024;

  Future<String> uploadProfileImage({
    required XFile image,
    required String uid,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Validate size
      final int fileSize = await image.length();
      if (fileSize > maxFileSize) {
        throw Exception("Image exceeds 5MB limit");
      }

      // Validate type
      final String extension = image.name.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png'].contains(extension)) {
        throw Exception("Only JPG and PNG images are allowed");
      }

      final String fileName =
          '${uid}_${DateTime.now().millisecondsSinceEpoch}.$extension';

      final Reference reference =
          _storage.ref().child('profile_images/$uid/$fileName');

      UploadTask uploadTask;

      if (kIsWeb) {
        final Uint8List bytes = await image.readAsBytes();
        final String mimeType = extension == 'jpg' || extension == 'jpeg'
            ? 'image/jpeg'
            : 'image/png';

        uploadTask = reference.putData(
          bytes,
          SettableMetadata(contentType: mimeType),
        );
      } else {
        final File file = File(image.path);

        // Compress image on mobile
        final compressedBytes = await FlutterImageCompress.compressWithFile(
          file.absolute.path,
          quality: 70,
        );

        if (compressedBytes == null) {
          throw Exception("Compression failed");
        }

        final String mimeType = extension == 'jpg' || extension == 'jpeg'
            ? 'image/jpeg'
            : 'image/png';

        uploadTask = reference.putData(
          compressedBytes,
          SettableMetadata(contentType: mimeType),
        );
      }

      // Track progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (onProgress != null) {
          double progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });

      await uploadTask;

      return await reference.getDownloadURL();
    } catch (e) {
      throw Exception("Image upload failed: $e");
    }
  }
}
