import 'dart:convert';
import 'dart:io';

AuthApi createAuthApi() => const AuthApi();

class AuthApi {
  const AuthApi();

  static const baseUrl = 'http://127.0.0.1:8000';

  Future<Map<String, dynamic>> get(String path, {String? token}) {
    return _request(path, method: 'GET', token: token);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, Object?> body,
      {String? token}) {
    return _request(path, method: 'POST', body: body, token: token);
  }

  Future<Map<String, dynamic>> _request(
    String path, {
    required String method,
    Map<String, Object?>? body,
    String? token,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl$path');
      final request = method == 'GET'
          ? await client.getUrl(uri)
          : await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      if (token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      if (body != null) request.write(jsonEncode(body));
      final response = await request.close();
      final raw = await response.transform(utf8.decoder).join();
      final data = _decode(raw);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(_message(data));
      }
      return data;
    } on SocketException {
      throw const AuthApiException(
          'Backend API belum menyala. Jalankan file JALANKAN_AHEAD.bat dari folder C:\\ahead_app agar MySQL, API, dan Flutter aktif bersama.');
    } finally {
      client.close(force: true);
    }
  }

  Map<String, dynamic> _decode(String raw) {
    if (raw.trim().isEmpty) return {};
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
