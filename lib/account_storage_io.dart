import 'dart:io';

AccountStorage createAccountStorage() => AccountStorage();

class AccountStorage {
  AccountStorage();

  File get _file {
    final separator = Platform.pathSeparator;
    return File(
        '${Directory.systemTemp.path}${separator}ahead_app_accounts_v1.json');
  }

  Future<String?> read() async {
    try {
      if (!await _file.exists()) return null;
      return await _file.readAsString();
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String value) async {
    try {
      await _file.writeAsString(value, flush: true);
    } catch (_) {}
  }
}
