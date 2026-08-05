import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/models.dart';
import 'auth_service.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Talks to the Flask backend for all prediction-related operations.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  Map<String, dynamic> _decode(http.Response r) {
    final body = r.body.isEmpty ? {} : jsonDecode(r.body);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return Map<String, dynamic>.from(body);
    }
    if (r.statusCode == 401) {
      // Token is invalid or expired — clear the stale session.
      AuthService.instance.logout();
      throw AuthException(body is Map && body['error'] != null
          ? body['error']
          : 'Session expired. Please log in again.');
    }
    throw ApiException(body is Map && body['error'] != null
        ? body['error']
        : 'Request failed (${r.statusCode})');
  }

  Future<Categories> fetchCategories() async {
    final r = await http.get(Uri.parse('${AppConfig.apiPrefix}/categories'));
    return Categories.fromJson(_decode(r));
  }

  Future<PredictionResult> predict(BaobabInput input) async {
    final r = await http.post(
      Uri.parse('${AppConfig.apiPrefix}/predict'),
      headers: AuthService.instance.authHeaders,
      body: jsonEncode(input.toJson()),
    );
    return PredictionResult.fromJson(_decode(r));
  }

  /// Upload an image; backend returns estimated morphology to confirm.
  Future<ImageEstimate> analyzeImage(XFile image,
      {double? refHeightM, double? refPixelHeight}) async {
    final req = http.MultipartRequest(
        'POST', Uri.parse('${AppConfig.apiPrefix}/predict/image'));
    req.headers['Authorization'] = 'Bearer ${AuthService.instance.token}';
    final bytes = await image.readAsBytes();
    req.files.add(http.MultipartFile.fromBytes('image', bytes, filename: image.name));
    if (refHeightM != null) req.fields['ref_object_height_m'] = '$refHeightM';
    if (refPixelHeight != null) {
      req.fields['ref_object_pixel_height'] = '$refPixelHeight';
    }
    final streamed = await req.send();
    final r = await http.Response.fromStream(streamed);
    return ImageEstimate.fromJson(_decode(r));
  }

  Future<Map<String, dynamic>> submitFeedback(
      BaobabInput input, Map<String, int?> labels) async {
    final feats = input.toJson()..remove('source');
    final r = await http.post(
      Uri.parse('${AppConfig.apiPrefix}/feedback'),
      headers: AuthService.instance.authHeaders,
      body: jsonEncode({'features': feats, 'labels': labels}),
    );
    return _decode(r);
  }

  Future<List<dynamic>> history() async {
    final r = await http.get(Uri.parse('${AppConfig.apiPrefix}/history'),
        headers: AuthService.instance.authHeaders);
    return _decode(r)['history'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> modelStatus() async {
    final r = await http.get(Uri.parse('${AppConfig.apiPrefix}/models/status'),
        headers: AuthService.instance.authHeaders);
    return _decode(r);
  }
}
