import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ImageUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  /// Mostra un dialog per scegliere tra camera e galleria
  static Future<File?> pickImage() async {
    final ImageSource? source = await _showImageSourceDialog();
    if (source == null) return null;

    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      return File(pickedFile.path);
    }

    return null;
  }

  /// Carica un'immagine su Firebase Storage
  static Future<String?> uploadImage(File imageFile, String folderPath) async {
    try {
      // Genera un nome univoco per il file
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final String fullPath = '$folderPath/$fileName';

      // Riferimento al file su Firebase Storage
      final Reference ref = _storage.ref().child(fullPath);

      // Upload del file
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;

      // Ottieni URL di download
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Carica più immagini
  static Future<List<String>> uploadMultipleImages(
    List<File> imageFiles,
    String folderPath,
  ) async {
    final List<String> urls = [];

    for (final File imageFile in imageFiles) {
      final String? url = await uploadImage(imageFile, folderPath);
      if (url != null) {
        urls.add(url);
      }
    }

    return urls;
  }

  /// Elimina un'immagine da Firebase Storage
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      // Estrai il path dall'URL
      final Uri uri = Uri.parse(imageUrl);
      final String? fullPath = uri.pathSegments.lastOrNull;
      
      if (fullPath != null) {
        final Reference ref = _storage.ref().child(fullPath);
        await ref.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Mostra dialog per selezione sorgente immagine
  static Future<ImageSource?> _showImageSourceDialog() async {
    // Questo metodo verrà chiamato dal widget che ne ha bisogno
    // per ora ritorna direttamente gallery come default
    return ImageSource.gallery;
  }

  /// Seleziona più immagini dalla galleria (workaround per pickMultipleImages)
  static Future<List<File>> pickMultipleImages({int maxImages = 5}) async {
    try {
      // Per ora, selezioniamo una singola immagine alla volta
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return [File(pickedFile.path)];
      }

      return [];
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }
}