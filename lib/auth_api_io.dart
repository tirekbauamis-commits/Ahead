import 'dart:convert';
import 'dart:io';

AuthApi createAuthApi() => const AuthApi();

class AuthApi {
  const AuthApi();

  static const baseUrl = 'http://127.0.0.1:8000';

  Future<Map<String, dynamic>> post(
      String path, Map<String, Object?> body) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse('$baseUrl$path'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
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
