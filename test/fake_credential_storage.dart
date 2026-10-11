import 'package:readygo_phrase/data/credential_storage.dart';

/// テスト用の`TokenStorage`。本物のKeychain/Keystore(flutter_secure_storage)は
/// `flutter test`上のプラットフォームチャンネルを持たないため、メモリ上で代用する。
class FakeCredentialStorage implements TokenStorage {
  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String value) async => _value = value;

  @override
  Future<void> delete() async => _value = null;
}
