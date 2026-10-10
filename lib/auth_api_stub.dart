AuthApi createAuthApi() => const AuthApi();

class AuthApi {
  const AuthApi();

  Future<Map<String, dynamic>> get(String path, {String? token}) {
    throw const AuthApiException('API tidak tersedia di platform ini.');
  }

  Future<Map<String, dynamic>> post(String path, Map<String, Object?> body,
      {String? token}) {
    throw const AuthApiException('API tidak tersedia di platform ini.');
  }
}

class AuthApiException implements Exception {
  const AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
