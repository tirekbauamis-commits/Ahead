AuthApi createAuthApi() => const AuthApi();

class AuthApi {
  const AuthApi();

  Future<Map<String, dynamic>> post(String path, Map<String, Object?> body) {
    throw const AuthApiException('API tidak tersedia di platform ini.');
  }
}

class AuthApiException implements Exception {
  const AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
