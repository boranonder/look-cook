import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  // Upload profile image (works for both web and mobile)
  Future<String?> uploadProfileImage(dynamic imageFile, String userId) async {
    try {
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$fileName';

      if (kIsWeb && imageFile is XFile) {
        final bytes = await imageFile.readAsBytes();
        await _supabase.storage.from('profile-images').uploadBinary(path, bytes);
      } else if (imageFile is File) {
        await _supabase.storage.from('profile-images').upload(path, imageFile);
      } else if (imageFile is XFile) {
        final bytes = await imageFile.readAsBytes();
        await _supabase.storage.from('profile-images').uploadBinary(path, bytes);
      }

      final publicUrl = _supabase.storage.from('profile-images').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('Upload profile image error: $e');
      return null;
    }
  }

  // Upload recipe image from XFile (web compatible)
  Future<String?> uploadRecipeImageFromXFile(XFile imageFile, String userId) async {
    try {
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$fileName';

      final bytes = await imageFile.readAsBytes();
      await _supabase.storage.from('recipe-images').uploadBinary(path, bytes);
      final publicUrl = _supabase.storage.from('recipe-images').getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      debugPrint('Upload recipe image from XFile error: $e');
      return null;
    }
  }

  // Upload recipe image (mobile - File based)
  Future<String?> uploadRecipeImage(File imageFile, String userId) async {
    try {
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$fileName';

      await _supabase.storage.from('recipe-images').upload(path, imageFile);
      final publicUrl = _supabase.storage.from('recipe-images').getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      debugPrint('Upload recipe image error: $e');
      return null;
    }
  }

  // Upload multiple recipe images from XFile list (web compatible)
  Future<List<String>> uploadRecipeImagesFromXFiles(List<XFile> imageFiles, String userId) async {
    List<String> imageUrls = [];

    for (var imageFile in imageFiles) {
      final url = await uploadRecipeImageFromXFile(imageFile, userId);
      if (url != null) {
        imageUrls.add(url);
      }
    }

    return imageUrls;
  }

  // Upload multiple recipe images
  Future<List<String>> uploadRecipeImages(List<File> imageFiles, String userId) async {
    List<String> imageUrls = [];

    for (var imageFile in imageFiles) {
      final url = await uploadRecipeImage(imageFile, userId);
      if (url != null) {
        imageUrls.add(url);
      }
    }

    return imageUrls;
  }

  // Upload recipe video
  Future<String?> uploadRecipeVideo(File videoFile, String userId) async {
    try {
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final path = '$fileName';

      await _supabase.storage.from('recipe-videos').upload(path, videoFile);
      final publicUrl = _supabase.storage.from('recipe-videos').getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      debugPrint('Upload recipe video error: $e');
      return null;
    }
  }

  // Delete image by path
  Future<void> deleteImage(String bucket, String path) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
    } catch (e) {
      debugPrint('Delete image error: $e');
    }
  }

  // Delete video by path
  Future<void> deleteVideo(String bucket, String path) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
    } catch (e) {
      debugPrint('Delete video error: $e');
    }
  }

  // Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('Pick image from gallery error: $e');
      return null;
    }
  }

  // Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('Pick image from camera error: $e');
      return null;
    }
  }

  // Pick multiple images
  Future<List<XFile>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return images;
    } catch (e) {
      debugPrint('Pick multiple images error: $e');
      return [];
    }
  }

  // Pick video (max 1 minute)
  Future<XFile?> pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 1),
      );
      return video;
    } catch (e) {
      debugPrint('Pick video error: $e');
      return null;
    }
  }

  // Pick video from camera (max 1 minute)
  Future<XFile?> pickVideoFromCamera() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 1),
      );
      return video;
    } catch (e) {
      debugPrint('Pick video from camera error: $e');
      return null;
    }
  }
}
