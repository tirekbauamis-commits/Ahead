// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

AccountStorage createAccountStorage() => const AccountStorage();

class AccountStorage {
  const AccountStorage();

  static const _key = 'ahead_app_accounts_v1';

  Future<String?> read() async => html.window.localStorage[_key];

  Future<void> write(String value) async {
    html.window.localStorage[_key] = value;
  }
}
