// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

AuthApi createAuthApi() => const AuthApi();

class AuthApi {
  const AuthApi();

  static const baseUrl = 'http://127.0.0.1:8000';

  Future<Map<String, dynamic>> get(String path, {String? token}) async {
    return _request(path, method: 'GET', token: token);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, Object?> body,
      {String? token}) async {
    return _request(path, method: 'POST', body: body, token: token);
  }

  Future<Map<String, dynamic>> _request(
    String path, {
    required String method,
    Map<String, Object?>? body,
    String? token,
  }) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final request = await html.HttpRequest.request(
        '$baseUrl$path',
        method: method,
        requestHeaders: headers,
        sendData: body == null ? null : jsonEncode(body),
      );
      final response = _decode(request.responseText);
      if (request.status == null ||
          request.status! < 200 ||
          request.status! >= 300) {
        throw AuthApiException(_message(response));
      }
      return response;
    } on AuthApiException {
      rethrow;
    } catch (_) {
      throw const AuthApiException(
          'Backend API belum menyala. Jalankan file JALANKAN_AHEAD.bat dari folder C:\\ahead_app agar MySQL, API, dan Flutter aktif bersama.');
    }
  }

  Map<String, dynamic> _decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return {};
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic>
        ? decoded
        : decoded is Map
            ? decoded.map((key, value) => MapEntry('$key', value))
            : {};
  }

  String _message(Map<String, dynamic> response) {
    return '${response['error'] ?? response['message'] ?? 'API gagal diproses.'}';
  }
}

class AuthApiException implements Exception {
  const AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
