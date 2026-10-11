import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 匿名ユーザーのAPI認証情報の保存先(`ApiClient`が使う)。
///
/// テストでは本物のKeychain/Keystoreに依存しないフェイク実装に差し替える
/// (`ApiClient(storage: ...)`)。
abstract class TokenStorage {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> delete();
}

/// iOS Keychain / Android Keystore(flutter_secure_storage)に保存する実装(Security issue #3)。
///
/// - Android: Keystore鍵で暗号化したEncryptedSharedPreferences。バックアップからの除外は
///   `android/app/src/main/res/xml/backup_rules.xml`・`data_extraction_rules.xml`で設定済み
/// - iOS: Keychain。`first_unlock_this_device`で、他端末への移行(暗号化バックアップの復元含む)
///   では引き継がれないようにする(紛失時はアプリ側の再登録フローに任せる)。iCloud同期もしない
///   (`synchronizable`の既定値false)
class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage();

  static const _key = 'api_token';

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);

  @override
  Future<void> delete() => _storage.delete(key: _key);
}
