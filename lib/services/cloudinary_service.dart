import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = 'do2udchvu';
  static const String _uploadPreset = 'profile_pictures';

  /// Upload gambar ke Cloudinary menggunakan multipart upload.
  /// Mengembalikan URL gambar jika berhasil, null jika gagal.
  static Future<String?> uploadImage(Uint8List bytes, String fileName) async {
    try {
      // Bersihkan nama file dari path separator agar tidak ada slash
      String cleanName = fileName
          .replaceAll('\\', '_')
          .replaceAll('/', '_');

      // Pastikan nama file tidak kosong
      if (cleanName.isEmpty) {
        cleanName = 'profile_photo.jpg';
      }

      debugPrint('CloudinaryService: upload $cleanName (${bytes.length} bytes)');

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      // Gunakan multipart request — kirim bytes langsung sebagai file
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: cleanName,
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
      );

      final responseBody = await streamedResponse.stream.bytesToString();
      debugPrint('CloudinaryService: status ${streamedResponse.statusCode}');

      if (streamedResponse.statusCode == 200) {
        final jsonData = jsonDecode(responseBody);
        final url = jsonData['secure_url'] as String?;
        debugPrint('CloudinaryService: berhasil → $url');
        return url;
      } else {
        debugPrint('CloudinaryService: gagal → $responseBody');
        return null;
      }
    } catch (e) {
      debugPrint('CloudinaryService: error → $e');
      return null;
    }
  }
}
