import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';
class UploadService {
  static Future<String?> uploadImage(XFile image) async {
    try {
      final headers = await ApiService.authHeaders();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/upload'),
      );

      request.headers.addAll({
        'Authorization': headers['Authorization'] ?? '',
      });

      if (kIsWeb) {
  final bytes = await image.readAsBytes();

  request.files.add(
    http.MultipartFile.fromBytes(
      'image',
      bytes,
      filename: image.name,
      contentType: MediaType('image', 'jpeg'),
    ),
  );
} else {
  request.files.add(
    await http.MultipartFile.fromPath(
      'image',
      image.path,
      contentType: MediaType('image', 'jpeg'),
    ),
  );
}
      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(body)['imageUrl'];
      }

      throw Exception(body);
    } catch (e) {
    debugPrint(e.toString());      return null;
    }
  }
}
