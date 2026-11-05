import 'dart:io';

import 'package:path_provider/path_provider.dart';

AccountStorage createAccountStorage() => AccountStorage();

class AccountStorage {
  AccountStorage();

  Future<File> get _file async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    return File(
        '${directory.path}${Platform.pathSeparator}ahead_app_accounts_v1.json');
  }

  Future<String?> read() async {
    try {
      final file = await _file;
      if (await file.exists()) return await file.readAsString();

      // Migrate data written by older builds to the app's persistent directory.
      final legacyFile = File(
          '${Directory.systemTemp.path}${Platform.pathSeparator}ahead_app_accounts_v1.json');
      if (!await legacyFile.exists()) return null;
      final legacyData = await legacyFile.readAsString();
      await file.writeAsString(legacyData, flush: true);
      return legacyData;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String value) async {
    try {
      final file = await _file;
      await file.writeAsString(value, flush: true);
    } catch (_) {}
  }
}
