AccountStorage createAccountStorage() => const AccountStorage();

class AccountStorage {
  const AccountStorage();

  Future<String?> read() async => null;

  Future<void> write(String value) async {}
}
